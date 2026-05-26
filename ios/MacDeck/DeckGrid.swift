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
            case .shortcut: return Color(hex: "6366f1")
            case .system:   return Color(hex: "8b5cf6")
            }
        }
        var border: Color { accent.opacity(0.35) }
    }
}

// ── Grid ──────────────────────────────────────────────────────────────────────

struct DeckGrid: View {
    @ObservedObject var vm: ViewModel
    @State var showEditor = false
    var isPortrait: Bool = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    private var baseApps: [CustomApp] { vm.customApps.filter(\.isPinned) }
    private var liveApps: [CustomApp] { vm.customApps.filter { !$0.isPinned } }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    // ── Base panel ──────────────────────────────────────
                    if !baseApps.isEmpty {
                        sectionHeader("Base", icon: "pin.fill", color: Color(hex: "8b5cf6"))
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(baseApps) { app in
                                AppDeckButton(app: app, vm: vm)
                            }
                        }
                    }

                    // ── En cours ────────────────────────────────────────
                    if !liveApps.isEmpty {
                        sectionHeader("En cours", icon: "circle.fill", color: Color(hex: "10b981"))
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(liveApps) { app in
                                AppDeckButton(app: app, vm: vm)
                            }
                        }
                    }
                }
            }

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

    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 7))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
        }
        .padding(.top, 10)
        .padding(.bottom, 6)
        .padding(.leading, 2)
    }
}

// ── App button (dynamic) ──────────────────────────────────────────────────────

struct AppDeckButton: View {
    let app: CustomApp
    @ObservedObject var vm: ViewModel
    @State private var flashColor: Color? = nil
    @State private var iconURL: URL? = nil

    private var isRunning: Bool {
        vm.runningApps.contains { r in
            let r = r.lowercased(), n = app.launchName.lowercased()
            return r == n || r.contains(n) || n.contains(r)
        }
    }

    private var accentColor: Color {
        app.isPinned ? Color(hex: "6366f1") : Color(hex: "10b981")
    }

    var body: some View {
        Button(action: handleTap) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Group {
                        if let iconURL {
                            AsyncImage(url: iconURL) { phase in
                                if let img = phase.image {
                                    img.resizable().scaledToFit()
                                        .frame(width: 42, height: 42)
                                        .cornerRadius(10)
                                } else { fallbackIcon }
                            }
                        } else { fallbackIcon }
                    }
                    // Dot vert = running, visible uniquement sur les apps de base
                    if app.isPinned && isRunning {
                        Circle()
                            .fill(Color(hex: "10b981"))
                            .frame(width: 7, height: 7)
                            .offset(x: 2, y: -2)
                    }
                }
                Text(app.displayName)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(app.isPinned ? Color(hex: "888888") : Color(hex: "10b981"))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(flashColor ?? Color(hex: "1a1a1a"))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(accentColor.opacity(app.isPinned ? 0.35 : 0.6), lineWidth: app.isPinned ? 1 : 1.5))
        }
        .buttonStyle(ScaleButtonStyle())
        .task {
            iconURL = await AppIconCache.shared.iconURL(displayName: app.displayName, launchName: app.launchName)
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: app.sfSymbol)
            .font(.system(size: 26, weight: .medium))
            .foregroundColor(accentColor)
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
        .onAppear {
            if action.symbol == "moon.fill" { isToggled = vm.dndActive }
            if action.symbol == "circle.lefthalf.filled" { isToggled = vm.isDarkMode }
        }
        .onChange(of: vm.dndActive) { val in
            if action.symbol == "moon.fill" { isToggled = val }
        }
        .onChange(of: vm.isDarkMode) { val in
            if action.symbol == "circle.lefthalf.filled" { isToggled = val }
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
