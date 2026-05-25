import SwiftUI

struct AppProfile {
    let appName: String
    let displayName: String
    let icon: String
    let actions: [DeckAction]
}

let appProfiles: [AppProfile] = [
    AppProfile(
        appName: "Figma",
        displayName: "Figma",
        icon: "pencil.and.outline",
        actions: [
            DeckAction(symbol: "arrow.uturn.backward",          label: "Undo",      category: .shortcut) { await $0.shortcut(keys: ["cmd","z"]) },
            DeckAction(symbol: "arrow.uturn.forward",           label: "Redo",      category: .shortcut) { await $0.shortcut(keys: ["cmd","shift","z"]) },
            DeckAction(symbol: "rectangle.3.group",             label: "Grouper",   category: .shortcut) { await $0.shortcut(keys: ["cmd","g"]) },
            DeckAction(symbol: "xmark.rectangle",               label: "Dégrouper", category: .shortcut) { await $0.shortcut(keys: ["cmd","shift","g"]) },
            DeckAction(symbol: "doc.on.doc",                    label: "Dupliquer", category: .shortcut) { await $0.shortcut(keys: ["cmd","d"]) },
            DeckAction(symbol: "bolt.fill",                     label: "Composant", category: .shortcut) { await $0.shortcut(keys: ["cmd","option","k"]) },
            DeckAction(symbol: "square.and.arrow.up",           label: "Exporter",  category: .shortcut) { await $0.shortcut(keys: ["cmd","shift","e"]) },
            DeckAction(symbol: "magnifyingglass",               label: "Recherche", category: .shortcut) { await $0.shortcut(keys: ["cmd","/"]) },
            DeckAction(symbol: "arrow.up.left.and.arrow.down.right", label: "Ajuster vue", category: .shortcut) { await $0.shortcut(keys: ["cmd","shift","h"]) },
            DeckAction(symbol: "1.square",                      label: "Zoom 100%", category: .shortcut) { await $0.shortcut(keys: ["cmd","shift","0"]) },
        ]
    ),
    AppProfile(
        appName: "Xcode",
        displayName: "Xcode",
        icon: "hammer",
        actions: [
            DeckAction(symbol: "hammer.fill",        label: "Build",      category: .shortcut) { await $0.shortcut(keys: ["cmd","b"]) },
            DeckAction(symbol: "play.fill",          label: "Run",        category: .shortcut) { await $0.shortcut(keys: ["cmd","r"]) },
            DeckAction(symbol: "stop.fill",          label: "Stop",       category: .shortcut) { await $0.shortcut(keys: ["cmd","."]) },
            DeckAction(symbol: "checkmark.seal",     label: "Tests",      category: .shortcut) { await $0.shortcut(keys: ["cmd","u"]) },
            DeckAction(symbol: "arrow.right.to.line", label: "Step Over",  category: .shortcut) { await $0.shortcut(keys: ["F6"]) },
            DeckAction(symbol: "arrow.down.to.line", label: "Step In",    category: .shortcut) { await $0.shortcut(keys: ["F7"]) },
            DeckAction(symbol: "arrow.up.to.line",   label: "Step Out",   category: .shortcut) { await $0.shortcut(keys: ["F8"]) },
            DeckAction(symbol: "text.magnifyingglass", label: "Chercher", category: .shortcut) { await $0.shortcut(keys: ["cmd","shift","f"]) },
        ]
    ),
    AppProfile(
        appName: "Safari",
        displayName: "Safari",
        icon: "safari",
        actions: [
            DeckAction(symbol: "arrow.left",       label: "Retour",       category: .shortcut) { await $0.shortcut(keys: ["cmd","["]) },
            DeckAction(symbol: "arrow.right",      label: "Suivant",      category: .shortcut) { await $0.shortcut(keys: ["cmd","]"]) },
            DeckAction(symbol: "arrow.clockwise",  label: "Recharger",    category: .shortcut) { await $0.shortcut(keys: ["cmd","r"]) },
            DeckAction(symbol: "plus.square",      label: "Nouvel onglet",category: .shortcut) { await $0.shortcut(keys: ["cmd","t"]) },
            DeckAction(symbol: "xmark.square",     label: "Fermer onglet",category: .shortcut) { await $0.shortcut(keys: ["cmd","w"]) },
            DeckAction(symbol: "book",             label: "Lecture",      category: .shortcut) { await $0.shortcut(keys: ["cmd","shift","r"]) },
            DeckAction(symbol: "location",         label: "Barre URL",    category: .shortcut) { await $0.shortcut(keys: ["cmd","l"]) },
            DeckAction(symbol: "bookmark",         label: "Favori",       category: .shortcut) { await $0.shortcut(keys: ["cmd","d"]) },
        ]
    ),
]
