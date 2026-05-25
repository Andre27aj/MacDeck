import SwiftUI

// ── iTunes icon cache ─────────────────────────────────────────────────────────

actor AppIconCache {
    static let shared = AppIconCache()
    private var cache: [String: URL?] = [:]

    func iconURL(displayName: String, launchName: String) async -> URL? {
        if let cached = cache[launchName] { return cached }
        if let server = await fetchFromServer(launchName) { cache[launchName] = server; return server }
        let itunes = await fetchFromItunes(displayName)
        cache[launchName] = itunes
        return itunes
    }

    private func fetchFromServer(_ appName: String) async -> URL? {
        guard !APIClient.baseURL.isEmpty,
              let encoded = appName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(APIClient.baseURL)/app-icon?name=\(encoded)"),
              let (_, response) = try? await URLSession.shared.data(from: url),
              (response as? HTTPURLResponse)?.statusCode == 200
        else { return nil }
        return url
    }

    private func fetchFromItunes(_ name: String) async -> URL? {
        guard let encoded = name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let apiURL = URL(string: "https://itunes.apple.com/search?term=\(encoded)&entity=software&limit=1"),
              let (data, _) = try? await URLSession.shared.data(from: apiURL),
              let json = try? JSONDecoder().decode(ItunesResult.self, from: data),
              let artwork = json.results.first?.artworkUrl100
        else { return nil }
        return URL(string: artwork.replacingOccurrences(of: "100x100bb", with: "256x256bb"))
    }
}

private struct ItunesResult: Decodable {
    let results: [ItunesApp]
    struct ItunesApp: Decodable { let artworkUrl100: String? }
}

// ── Fixed actions (shortcuts + system) ───────────────────────────────────────

struct DeckAction: Identifiable {
    let id = UUID()
    let symbol: String
    let label: String
    let category: Category
    let handler: (ViewModel) async -> Bool

    enum Category {
        case shortcut, system
        var accent: Color {
            switch self {
            case .shortcut: return Color(hex: "3b82f6")
            case .system:   return Color(hex: "f59e0b")
            }
        }
        var border: Color { accent.opacity(0.35) }
    }
}

private let fixedActions: [DeckAction] = [
    // Row 3 — bleu clair (raccourcis)
    DeckAction(symbol: "camera.viewfinder", label: "Screenshot",  category: .shortcut) { await $0.shortcut(keys: ["cmd","shift","3"]) },
    DeckAction(symbol: "magnifyingglass",   label: "Spotlight",   category: .shortcut) { await $0.shortcut(keys: ["cmd","space"]) },
    DeckAction(symbol: "lock",              label: "Verrouiller", category: .shortcut) { await $0.shortcut(keys: ["cmd","ctrl","q"]) },
    DeckAction(symbol: "rectangle.stack",   label: "Mission",     category: .shortcut) { await $0.shortcut(keys: ["F3"]) },
    DeckAction(symbol: "arrow.left.arrow.right.square", label: "App Switch", category: .shortcut) { await $0.shortcut(keys: ["cmd","tab"]) },
    // Row 4 — orange (système)
    DeckAction(symbol: "xmark.app",         label: "Close App",   category: .system)   { await $0.shortcut(keys: ["cmd","q"]) },
    DeckAction(symbol: "moon.fill",         label: "DND",         category: .system)   { await $0.toggleDND() },
    DeckAction(symbol: "zzz",              label: "Sleep",        category: .system)   { await $0.sleep() },
    DeckAction(symbol: "trash",            label: "Corbeille",   category: .system)   { await $0.emptyTrash() },
]

// ── Grid ──────────────────────────────────────────────────────────────────────

struct DeckGrid: View {
    @ObservedObject var vm: ViewModel
    @State var showEditor = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 8) {
                    // App buttons (customizable)
                    ForEach(Array(vm.customApps.enumerated()), id: \.element.id) { idx, app in
                        AppDeckButton(app: app, idx: idx, vm: vm)
                    }

                    // Fixed buttons
                    ForEach(fixedActions) { action in
                        FixedDeckButton(action: action, vm: vm)
                    }
                }
            }

            // Edit apps button
            Button { showEditor = true } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color(hex: "555555"))
                    .padding(8)
            }
        }
        .sheet(isPresented: $showEditor) {
            AppEditorView(vm: vm)
        }
    }
}

// ── App button (dynamic) ──────────────────────────────────────────────────────

struct AppDeckButton: View {
    let app: CustomApp
    let idx: Int
    @ObservedObject var vm: ViewModel
    @State private var flashColor: Color? = nil
    @State private var iconURL: URL? = nil

    private var accent: Color {
        idx < 4 ? Color(hex: "8b5cf6") : Color(hex: "6366f1")
    }

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 4) {
                Group {
                    if let iconURL {
                        AsyncImage(url: iconURL) { phase in
                            if let img = phase.image {
                                img.resizable().scaledToFit()
                                    .frame(width: 42, height: 42)
                                    .cornerRadius(10)
                            } else {
                                fallbackIcon
                            }
                        }
                    } else {
                        fallbackIcon
                    }
                }
                Text(app.displayName)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(Color(hex: "888888"))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(flashColor ?? Color(hex: "1a1a1a"))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(accent.opacity(0.35), lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
        .task {
            iconURL = await AppIconCache.shared.iconURL(displayName: app.displayName, launchName: app.launchName)
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: app.sfSymbol)
            .font(.system(size: 26, weight: .medium))
            .foregroundColor(accent)
            .frame(width: 42, height: 42)
    }

    private func handleTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            let ok = await vm.launch(app: app.launchName)
            await flash(success: ok)
        }
    }

    @MainActor
    private func flash(success: Bool) async {
        withAnimation(.easeOut(duration: 0.05)) {
            flashColor = success ? Color.green.opacity(0.3) : Color.red.opacity(0.3)
        }
        try? await Task.sleep(nanoseconds: 350_000_000)
        withAnimation(.easeOut(duration: 0.2)) { flashColor = nil }
    }
}

// ── Fixed button ──────────────────────────────────────────────────────────────

struct FixedDeckButton: View {
    let action: DeckAction
    @ObservedObject var vm: ViewModel
    @State private var flashColor: Color? = nil
    @State private var isToggled = false

    var body: some View {
        Button(action: handleTap) {
            Image(systemName: action.symbol)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(isToggled ? .white : action.category.accent)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.vertical, 8)
                .background(flashColor ?? (isToggled ? action.category.accent.opacity(0.25) : Color(hex: "1a1a1a")))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12)
                    .stroke(isToggled ? action.category.accent : action.category.border, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
        .onChange(of: vm.dndActive) { val in
            if action.symbol == "moon.fill" { isToggled = val }
        }
    }

    private func handleTap() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        Task {
            let ok = await action.handler(vm)
            await flash(success: ok)
        }
    }

    @MainActor
    private func flash(success: Bool) async {
        withAnimation(.easeOut(duration: 0.05)) {
            flashColor = success ? Color.green.opacity(0.3) : Color.red.opacity(0.3)
        }
        try? await Task.sleep(nanoseconds: 350_000_000)
        withAnimation(.easeOut(duration: 0.2)) { flashColor = nil }
    }
}
