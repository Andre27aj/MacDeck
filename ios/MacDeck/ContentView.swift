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

                GeometryReader { geo in
                    let isPortrait = geo.size.height > geo.size.width
                    if isPortrait {
                        VStack(spacing: 8) {
                            LeftPanel(vm: vm, isPortrait: true)
                                .fixedSize(horizontal: false, vertical: true)
                            PagedDeckView(vm: vm, isPortrait: true)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    } else {
                        HStack(alignment: .top, spacing: 8) {
                            LeftPanel(vm: vm, isPortrait: false)
                                .frame(width: geo.size.width * 0.32)
                            PagedDeckView(vm: vm)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .animation(.easeInOut(duration: 0.2), value: vm.connected)

            // Top overlay: battery + settings gear
            VStack {
                HStack {
                    if let batt = vm.battery {
                        HStack(spacing: 3) {
                            Image(systemName: vm.isCharging ? "battery.100.bolt" : batterySymbol(batt))
                                .font(.system(size: 12))
                                .foregroundColor(batteryColor(batt))
                            Text("\(batt)%")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(Color(hex: "555555"))
                        }
                        .padding(.leading, 12)
                    }
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

    private func batterySymbol(_ level: Int) -> String {
        switch level {
        case 0..<15:  return "battery.0"
        case 15..<40: return "battery.25"
        case 40..<65: return "battery.50"
        case 65..<85: return "battery.75"
        default:      return "battery.100"
        }
    }

    private func batteryColor(_ level: Int) -> Color {
        level < 20 ? .red : level < 40 ? Color(hex: "f59e0b") : Color(hex: "22c55e")
    }
}
