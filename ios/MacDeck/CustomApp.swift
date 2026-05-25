import Foundation

struct CustomApp: Codable, Identifiable {
    var id: UUID
    var displayName: String
    var launchName: String
    var sfSymbol: String

    init(id: UUID = UUID(), displayName: String, launchName: String, sfSymbol: String = "app") {
        self.id = id
        self.displayName = displayName
        self.launchName = launchName
        self.sfSymbol = sfSymbol
    }

    static let defaults: [CustomApp] = [
        // Row 1 — violet
        .init(displayName: "Safari",   launchName: "Safari",             sfSymbol: "safari"),
        .init(displayName: "VS Code",  launchName: "Visual Studio Code", sfSymbol: "curlybraces.square"),
        .init(displayName: "Terminal", launchName: "Terminal",           sfSymbol: "terminal"),
        .init(displayName: "Spotify",  launchName: "Spotify",            sfSymbol: "music.note"),
        // Row 2 — indigo
        .init(displayName: "Discord",  launchName: "Discord",            sfSymbol: "bubble.left.and.bubble.right"),
        .init(displayName: "Finder",   launchName: "Finder",             sfSymbol: "folder"),
        .init(displayName: "Mail",     launchName: "Mail",               sfSymbol: "envelope"),
        .init(displayName: "Notion",   launchName: "Notion",             sfSymbol: "doc.text"),
    ]

    // Curated symbols available in the editor
    static let availableSymbols: [String] = [
        "safari","curlybraces.square","terminal","music.note","bubble.left.and.bubble.right",
        "folder","envelope","calendar","clock","photo","film","mic","headphones",
        "gamecontroller","globe","lock","star","heart","bookmark","tag",
        "doc","tray","archivebox","externaldrive","display","keyboard",
        "paintbrush","pencil","scissors","hammer","wrench.and.screwdriver",
        "app","app.badge","square.grid.2x2","rectangle.stack",
    ]
}
