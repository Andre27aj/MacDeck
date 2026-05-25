import SwiftUI

struct AppProfilePage: View {
    @ObservedObject var vm: ViewModel
    var isPortrait: Bool = false

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

    var body: some View {
        if let profile = vm.activeProfile {
            if isPortrait {
                GeometryReader { geo in
                    let rows = max(1, Int(ceil(Double(profile.actions.count) / 4.0)))
                    let btnH = (geo.size.height - CGFloat(rows - 1) * 8) / CGFloat(rows)
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(profile.actions) { action in
                            FixedDeckButton(action: action, vm: vm)
                                .frame(height: btnH)
                        }
                    }
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(profile.actions) { action in
                            FixedDeckButton(action: action, vm: vm)
                        }
                    }
                }
            }
        } else {
            VStack(spacing: 12) {
                Image(systemName: "bolt.slash")
                    .font(.system(size: 36))
                    .foregroundColor(Color(hex: "444444"))
                Text("Aucun profil actif")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color(hex: "555555"))
                Text("Ouvre Figma, Xcode ou Safari\npour voir les raccourcis")
                    .font(.system(size: 12))
                    .foregroundColor(Color(hex: "444444"))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
