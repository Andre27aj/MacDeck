import SwiftUI

struct PagedDeckView: View {
    @ObservedObject var vm: ViewModel
    var isPortrait: Bool = false

    var body: some View {
        VStack(spacing: 4) {
            // Tab bar
            HStack(spacing: 6) {
                tabBtn(page: 0, icon: "square.grid.2x2.fill", label: "Apps")
                tabBtn(page: 1, icon: "gearshape.fill", label: "Système")
                tabBtn(page: 2, icon: "bolt.fill",
                       label: vm.activeProfile?.displayName ?? "Profil",
                       hasNotification: vm.activeProfile != nil && vm.currentPage != 2)
            }

            TabView(selection: $vm.currentPage) {
                DeckGrid(vm: vm, isPortrait: isPortrait)
                    .tag(0)
                SystemPage(vm: vm, isPortrait: isPortrait)
                    .tag(1)
                AppProfilePage(vm: vm, isPortrait: isPortrait)
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func tabBtn(page: Int, icon: String, label: String, hasNotification: Bool = false) -> some View {
        let active = vm.currentPage == page
        Button { vm.currentPage = page } label: {
            ZStack(alignment: .topTrailing) {
                HStack(spacing: 4) {
                    Image(systemName: icon).font(.system(size: 11))
                    Text(label).font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(active ? Color(hex: "6366f1") : Color(hex: "444444"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(active ? Color(hex: "6366f1").opacity(0.15) : Color(hex: "1a1a1a"))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(
                    active ? Color(hex: "6366f1").opacity(0.4) : Color(hex: "2a2a2a"),
                    lineWidth: 1
                ))

                if hasNotification {
                    Circle()
                        .fill(Color(hex: "10b981"))
                        .frame(width: 7, height: 7)
                        .offset(x: 3, y: -3)
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
