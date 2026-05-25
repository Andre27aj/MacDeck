import SwiftUI

private let systemPageActions: [DeckAction] = [
    DeckAction(symbol: "lock.fill",            label: "Verrouiller",  category: .system)   { await $0.lockScreen() },
    DeckAction(symbol: "moon.zzz.fill",        label: "Veille écran", category: .system)   { await $0.sleepDisplay() },
    DeckAction(symbol: "camera.viewfinder",    label: "Screenshot",   category: .shortcut) { await $0.shortcut(keys: ["cmd","shift","3"]) },
    DeckAction(symbol: "circle.lefthalf.filled", label: "Apparence",  category: .system)   { await $0.toggleDarkMode() },
    DeckAction(symbol: "rectangle.stack",      label: "Mission Ctrl", category: .shortcut) { await $0.shortcut(keys: ["F3"]) },
    DeckAction(symbol: "moon.fill",            label: "Focus/DND",    category: .system)   { await $0.toggleDND() },
    DeckAction(symbol: "zzz",                  label: "Sleep Mac",    category: .system)   { await $0.sleep() },
    DeckAction(symbol: "trash",                label: "Corbeille",    category: .system)   { await $0.emptyTrash() },
    DeckAction(symbol: "magnifyingglass",      label: "Spotlight",    category: .shortcut) { await $0.shortcut(keys: ["cmd","space"]) },
    DeckAction(symbol: "arrow.left.arrow.right.square", label: "App Switch", category: .shortcut) { await $0.shortcut(keys: ["cmd","tab"]) },
    DeckAction(symbol: "xmark.app",            label: "Quitter App",  category: .system)   { await $0.shortcut(keys: ["cmd","q"]) },
]

struct SystemPage: View {
    @ObservedObject var vm: ViewModel
    var isPortrait: Bool = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        if isPortrait {
            GeometryReader { geo in
                let rows = max(1, Int(ceil(Double(systemPageActions.count) / 4.0)))
                let btnH = (geo.size.height - CGFloat(rows - 1) * 8) / CGFloat(rows)
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(systemPageActions) { action in
                        FixedDeckButton(action: action, vm: vm)
                            .frame(height: btnH)
                    }
                }
            }
        } else {
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(systemPageActions) { action in
                        FixedDeckButton(action: action, vm: vm)
                    }
                }
            }
        }
    }
}
