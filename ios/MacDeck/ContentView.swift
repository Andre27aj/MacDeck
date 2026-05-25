import SwiftUI

struct ContentView: View {
    @StateObject var vm = ViewModel()
    @State var showSettings = false

    var body: some View {
        ZStack {
            Color(hex: "0d0d0d").ignoresSafeArea()

            VStack(spacing: 8) {
                // Status banner
                if vm.discovering {
                    HStack(spacing: 6) {
                        ProgressView().tint(.white).scaleEffect(0.8)
                        Text("Recherche du Mac sur le réseau…")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color(hex: "3b82f6"))
                    .cornerRadius(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                } else if !vm.connected {
                    HStack(spacing: 6) {
                        Image(systemName: "wifi.slash")
                        Text("Impossible de joindre le Mac — reconnexion…")
                            .font(.caption.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 5)
                    .background(Color.red)
                    .cornerRadius(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Main layout — adapts to orientation
                GeometryReader { geo in
                    let isPortrait = geo.size.height > geo.size.width
                    if isPortrait {
                        VStack(spacing: 8) {
                            LeftPanel(vm: vm, isPortrait: true)
                                .frame(height: geo.size.height * 0.33)
                            DeckGrid(vm: vm)
                        }
                    } else {
                        HStack(alignment: .top, spacing: 8) {
                            LeftPanel(vm: vm, isPortrait: false)
                                .frame(width: geo.size.width * 0.32)
                            DeckGrid(vm: vm)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .animation(.easeInOut(duration: 0.2), value: vm.connected)

            // Settings gear
            VStack {
                HStack {
                    Spacer()
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundColor(Color(hex: "444444"))
                            .font(.system(size: 16))
                            .padding(10)
                    }
                }
                Spacer()
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(vm: vm)
        }
    }
}
