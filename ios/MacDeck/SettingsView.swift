import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0d0d0d").ignoresSafeArea()

                Form {
                    Section {
                        HStack {
                            Text("IP du Mac")
                                .foregroundColor(.white)
                            Spacer()
                            TextField("192.168.1.x", text: $vm.macIP)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .foregroundColor(Color(hex: "8b5cf6"))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                    } header: {
                        Text("Réseau")
                    } footer: {
                        Text("Lancez \u{0060}ipconfig getifaddr en0\u{0060} dans le Terminal de votre Mac pour trouver son adresse IP.")
                            .font(.caption)
                    }

                    Section("Statut") {
                        HStack {
                            Text("Connexion")
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(vm.connected ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                Text(vm.connected ? "Connecté" : "Déconnecté")
                                    .foregroundColor(vm.connected ? .green : .red)
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }

                        Button("Tester la connexion") {
                            Task { await vm.syncStatus() }
                        }
                        .foregroundColor(Color(hex: "3b82f6"))

                        Button(action: { vm.startDiscovery() }) {
                            HStack(spacing: 6) {
                                if vm.discovering {
                                    ProgressView().scaleEffect(0.8)
                                } else {
                                    Image(systemName: "antenna.radiowaves.left.and.right")
                                }
                                Text(vm.discovering ? "Recherche en cours…" : "Détecter le Mac automatiquement")
                            }
                        }
                        .foregroundColor(Color(hex: "10b981"))
                        .disabled(vm.discovering)
                    }

                    Section("Instructions") {
                        VStack(alignment: .leading, spacing: 8) {
                            step("1", "Sur le Mac : \u{0060}npm start\u{0060} dans le dossier macdeck/")
                            step("2", "Trouver l\u{2019}IP : \u{0060}ipconfig getifaddr en0\u{0060}")
                            step("3", "Entrer l\u{2019}IP ci-dessus")
                            step("4", "Mac et iPhone sur le même Wi-Fi")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("MacDeck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func step(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 18, height: 18)
                .background(Color(hex: "333333"))
                .clipShape(Circle())
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "aaaaaa"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
