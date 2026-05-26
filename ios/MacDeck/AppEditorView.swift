import SwiftUI

// ── Icon auto-assign based on app name ────────────────────────────────────────

func iconForApp(_ name: String) -> String {
    let l = name.lowercased()
    if l.hasPrefix("http://") || l.hasPrefix("https://") { return "globe" }
    if l.contains("youtube")                        { return "play.rectangle" }
    if l.contains("safari")                        { return "safari" }
    if l.contains("code") || l.contains("vscode")  { return "curlybraces.square" }
    if l.contains("terminal") || l.contains("iterm"){ return "terminal" }
    if l.contains("spotify")                        { return "music.note" }
    if l.contains("discord")                        { return "bubble.left.and.bubble.right" }
    if l.contains("finder")                         { return "folder" }
    if l.contains("mail")                           { return "envelope" }
    if l.contains("calendar")                       { return "calendar" }
    if l.contains("photo")                          { return "photo" }
    if l.contains("music")                          { return "music.note.list" }
    if l.contains("xcode")                          { return "hammer" }
    if l.contains("slack")                          { return "bubble.left.and.bubble.right.fill" }
    if l.contains("figma")                          { return "paintbrush" }
    if l.contains("chrome")                         { return "globe" }
    if l.contains("firefox")                        { return "flame" }
    if l.contains("notion")                         { return "doc.text" }
    if l.contains("zoom")                           { return "video" }
    if l.contains("whatsapp") || l.contains("telegram") || l.contains("message") { return "message" }
    if l.contains("screen")                         { return "display" }
    if l.contains("system pref") || l.contains("system setting") { return "gearshape" }
    if l.contains("activity")                       { return "chart.bar" }
    if l.contains("store")                          { return "bag" }
    if l.contains("numbers")                        { return "tablecells" }
    if l.contains("pages")                          { return "doc.richtext" }
    if l.contains("keynote")                        { return "rectangle.on.rectangle" }
    if l.contains("word") || l.contains("excel") || l.contains("powerpoint") { return "doc.fill" }
    if l.contains("vlc") || l.contains("video") || l.contains("player") { return "film" }
    if l.contains("arc") || l.contains("browser")  { return "globe" }
    return "app"
}

// ── App list editor ───────────────────────────────────────────────────────────

struct AppEditorView: View {
    @ObservedObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss
    @State private var editingApp: CustomApp? = nil

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0d0d0d").ignoresSafeArea()

                List {
                    ForEach($vm.customApps) { $app in
                        Button { editingApp = app } label: {
                            HStack(spacing: 12) {
                                Image(systemName: app.sfSymbol)
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "8b5cf6"))
                                    .frame(width: 32)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.displayName)
                                        .foregroundColor(.white)
                                        .font(.system(size: 15, weight: .medium))
                                    Text(app.launchName)
                                        .foregroundColor(Color(hex: "555555"))
                                        .font(.system(size: 12))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(hex: "444444"))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete { vm.customApps.remove(atOffsets: $0) }
                    .onMove  { vm.customApps.move(fromOffsets: $0, toOffset: $1) }
                    .listRowBackground(Color(hex: "1a1a1a"))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Apps")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton().foregroundColor(Color(hex: "8b5cf6"))
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button {
                            let blank = CustomApp(displayName: "", launchName: "", sfSymbol: "app")
                            vm.customApps.append(blank)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                editingApp = vm.customApps.last
                            }
                        } label: { Image(systemName: "plus") }
                        .foregroundColor(Color(hex: "8b5cf6"))

                        Button("Fermer") { dismiss() }
                    }
                }
            }
            .sheet(item: $editingApp) { app in
                AppDetailEditor(app: app, vm: vm)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// ── Detail editor ─────────────────────────────────────────────────────────────

struct AppDetailEditor: View {
    let app: CustomApp
    @ObservedObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss

    @State private var displayName: String
    @State private var launchName: String
    @State private var sfSymbol: String
    @State private var showPicker = false
    @State private var installedApps: [String] = []
    @State private var loadingApps = false

    init(app: CustomApp, vm: ViewModel) {
        self.app = app; self.vm = vm
        _displayName = State(initialValue: app.displayName)
        _launchName  = State(initialValue: app.launchName)
        _sfSymbol    = State(initialValue: app.sfSymbol)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0d0d0d").ignoresSafeArea()

                Form {
                    // Preview
                    Section {
                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                Image(systemName: sfSymbol)
                                    .font(.system(size: 40))
                                    .foregroundColor(Color(hex: "8b5cf6"))
                                Text(displayName.isEmpty ? "App" : displayName)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(20)
                            .background(Color(hex: "1a1a1a"))
                            .cornerRadius(16)
                            Spacer()
                        }
                    }
                    .listRowBackground(Color.clear)

                    // App picker or URL
                    Section("Application ou URL") {
                        Button {
                            if installedApps.isEmpty { fetchApps() }
                            showPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "square.grid.2x2")
                                    .foregroundColor(Color(hex: "8b5cf6"))
                                    .frame(width: 28)
                                Text("Choisir une app…")
                                    .foregroundColor(Color(hex: "888888"))
                                Spacer()
                                if loadingApps {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "444444"))
                                }
                            }
                        }

                        HStack {
                            Image(systemName: launchName.hasPrefix("http") ? "globe" : "keyboard")
                                .foregroundColor(Color(hex: "8b5cf6"))
                                .frame(width: 28)
                            TextField("Nom d'app ou URL (https://...)", text: $launchName)
                                .foregroundColor(.white)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                                .onChange(of: launchName) { val in
                                    sfSymbol = iconForApp(val)
                                }
                        }
                    }
                    .listRowBackground(Color(hex: "1a1a1a"))

                    // Custom display name override
                    Section {
                        TextField("Laisser vide pour utiliser le nom de l'app", text: $displayName)
                            .foregroundColor(.white)
                            .autocorrectionDisabled()
                    } header: {
                        Text("Surnom (optionnel)")
                    }
                    .listRowBackground(Color(hex: "1a1a1a"))

                    // Icon picker
                    Section("Icône") {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                            ForEach(CustomApp.availableSymbols, id: \.self) { sym in
                                Button { sfSymbol = sym } label: {
                                    Image(systemName: sym)
                                        .font(.system(size: 20))
                                        .foregroundColor(sym == sfSymbol ? Color(hex: "8b5cf6") : Color(hex: "888888"))
                                        .frame(width: 42, height: 42)
                                        .background(sym == sfSymbol ? Color(hex: "8b5cf6").opacity(0.15) : Color.clear)
                                        .cornerRadius(8)
                                }
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color(hex: "1a1a1a"))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { dismiss() }.foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("OK") { save() }
                        .foregroundColor(Color(hex: "8b5cf6"))
                        .disabled(launchName.isEmpty)
                }
            }
            .sheet(isPresented: $showPicker) {
                AppPickerView(
                    installedApps: installedApps,
                    runningApps: Array(vm.runningApps).sorted(),
                    loading: loadingApps,
                    selectedName: launchName
                ) { chosen in
                    launchName = chosen
                    if displayName.isEmpty || displayName == app.launchName {
                        displayName = chosen
                    }
                    sfSymbol = iconForApp(chosen)
                    showPicker = false
                }
            }
            .onAppear { fetchApps() }
        }
        .preferredColorScheme(.dark)
    }

    private func fetchApps() {
        guard !loadingApps else { return }
        loadingApps = true
        Task {
            if let r = try? await (APIClient.get("/apps/list") as AppsListResponse) {
                await MainActor.run {
                    installedApps = r.apps
                    loadingApps = false
                }
            } else {
                await MainActor.run { loadingApps = false }
            }
        }
    }

    private func save() {
        var name = displayName.isEmpty ? launchName : displayName
        if displayName.isEmpty && launchName.hasPrefix("http"),
           let host = URL(string: launchName)?.host {
            name = host.replacingOccurrences(of: "www.", with: "")
        }
        if let idx = vm.customApps.firstIndex(where: { $0.id == app.id }) {
            vm.customApps[idx].displayName = name
            vm.customApps[idx].launchName  = launchName
            vm.customApps[idx].sfSymbol    = sfSymbol
        }
        vm.pinApp(launchName)
        dismiss()
    }
}

// ── App picker sheet ──────────────────────────────────────────────────────────

struct AppPickerView: View {
    let installedApps: [String]
    let runningApps: [String]
    let loading: Bool
    let selectedName: String
    let onSelect: (String) -> Void

    @State private var search = ""
    @Environment(\.dismiss) var dismiss

    var filteredRunning: [String] {
        let q = search.lowercased()
        return q.isEmpty ? runningApps : runningApps.filter { $0.localizedCaseInsensitiveContains(q) }
    }

    var filteredInstalled: [String] {
        let q = search.lowercased()
        let all = q.isEmpty ? installedApps : installedApps.filter { $0.localizedCaseInsensitiveContains(q) }
        let runningSet = Set(runningApps)
        return all.filter { !runningSet.contains($0) }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0d0d0d").ignoresSafeArea()

                Group {
                    if loading && installedApps.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Chargement des apps…")
                                .foregroundColor(Color(hex: "555555"))
                                .font(.caption)
                        }
                    } else {
                        List {
                            if !filteredRunning.isEmpty {
                                Section {
                                    ForEach(filteredRunning, id: \.self) { appName in
                                        appRow(appName, running: true)
                                    }
                                } header: {
                                    Label("En cours", systemImage: "circle.fill")
                                        .foregroundColor(Color(hex: "10b981"))
                                        .font(.caption.weight(.semibold))
                                }
                            }

                            if !filteredInstalled.isEmpty {
                                Section {
                                    ForEach(filteredInstalled, id: \.self) { appName in
                                        appRow(appName, running: false)
                                    }
                                } header: {
                                    Text("Toutes les apps")
                                        .foregroundColor(Color(hex: "555555"))
                                        .font(.caption.weight(.semibold))
                                }
                            }
                        }
                        .listStyle(.insetGrouped)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .navigationTitle("Choisir une app")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Rechercher…")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annuler") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func appRow(_ appName: String, running: Bool) -> some View {
        Button { onSelect(appName) } label: {
            HStack(spacing: 12) {
                Image(systemName: iconForApp(appName))
                    .font(.system(size: 18))
                    .foregroundColor(running ? Color(hex: "10b981") : Color(hex: "8b5cf6"))
                    .frame(width: 28)
                Text(appName)
                    .foregroundColor(.white)
                if running {
                    Circle()
                        .fill(Color(hex: "10b981"))
                        .frame(width: 6, height: 6)
                }
                Spacer()
                if appName == selectedName {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color(hex: "8b5cf6"))
                }
            }
        }
        .listRowBackground(Color(hex: "1a1a1a"))
    }
}
