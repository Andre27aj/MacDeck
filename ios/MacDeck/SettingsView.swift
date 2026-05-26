import SwiftUI

struct SettingsView: View {
    @ObservedObject var vm: ViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0d0d0d").ignoresSafeArea()

                Form {
                    // ── Réseau ────────────────────────────────────────────────
                    Section {
                        HStack {
                            Text("IP du Mac").foregroundColor(.white)
                            Spacer()
                            TextField("192.168.1.x", text: $vm.macIP)
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .foregroundColor(Color(hex: "8b5cf6"))
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                    } header: { Text("Réseau") }
                    .listRowBackground(Color(hex: "1a1a1a"))

                    // ── Sécurité ──────────────────────────────────────────────
                    Section {
                        if vm.isPaired {
                            HStack(spacing: 10) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(Color(hex: "10b981"))
                                    .frame(width: 24)
                                Text("Jumelé avec ce Mac")
                                    .foregroundColor(.white)
                                Spacer()
                                Button("Dissocier") { vm.unpair() }
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                            }
                        } else {
                            Button {
                                Task { await vm.requestPairing() }
                            } label: {
                                HStack(spacing: 10) {
                                    if vm.pairingPhase == .requesting {
                                        ProgressView().scaleEffect(0.8).frame(width: 24)
                                    } else {
                                        Image(systemName: "link")
                                            .foregroundColor(Color(hex: "8b5cf6"))
                                            .frame(width: 24)
                                    }
                                    Text(vm.pairingPhase == .requesting ? "Connexion…" : "Jumeler avec ce Mac")
                                        .foregroundColor(Color(hex: "8b5cf6"))
                                }
                            }
                            .disabled(vm.macIP.isEmpty || vm.pairingPhase != .idle)

                            if let err = vm.pairingError {
                                Text(err).foregroundColor(.red).font(.caption)
                            }
                        }
                    } header: {
                        Text("Sécurité")
                    } footer: {
                        Text(vm.isPaired
                             ? "Ce téléphone est autorisé à contrôler le Mac."
                             : "Un code apparaîtra sur le Mac. Entrez-le ici pour autoriser ce téléphone.")
                            .font(.caption)
                    }
                    .listRowBackground(Color(hex: "1a1a1a"))

                    // ── Statut ────────────────────────────────────────────────
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
                        Button("Tester la connexion") { Task { await vm.syncStatus() } }
                            .foregroundColor(Color(hex: "3b82f6"))
                        Button(action: { vm.startDiscovery() }) {
                            HStack(spacing: 6) {
                                if vm.discovering { ProgressView().scaleEffect(0.8) }
                                else { Image(systemName: "antenna.radiowaves.left.and.right") }
                                Text(vm.discovering ? "Recherche…" : "Détecter le Mac automatiquement")
                            }
                        }
                        .foregroundColor(Color(hex: "10b981"))
                        .disabled(vm.discovering)
                    }
                    .listRowBackground(Color(hex: "1a1a1a"))

                    // ── Instructions ──────────────────────────────────────────
                    Section("Instructions") {
                        VStack(alignment: .leading, spacing: 8) {
                            step("1", "Sur le Mac : `npm start` dans le dossier macdeck/")
                            step("2", "Trouver l'IP : `ipconfig getifaddr en0`")
                            step("3", "Entrer l'IP ci-dessus puis jumeler")
                            step("4", "Mac et iPhone sur le même Wi-Fi")
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color(hex: "1a1a1a"))
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
            .sheet(isPresented: $vm.showPairingCodeEntry) {
                PairingCodeView(vm: vm)
            }
        }
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private func step(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n)
                .font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                .frame(width: 18, height: 18).background(Color(hex: "333333")).clipShape(Circle())
            Text(text).font(.system(size: 13)).foregroundColor(Color(hex: "aaaaaa"))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// ── Pairing code entry sheet ──────────────────────────────────────────────────

struct PairingCodeView: View {
    @ObservedObject var vm: ViewModel
    @State private var code = ""
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0d0d0d").ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 72))
                        .foregroundColor(Color(hex: "8b5cf6"))

                    VStack(spacing: 8) {
                        Text("Jumelage MacDeck")
                            .font(.title2.bold()).foregroundColor(.white)
                        Text("Un code à 6 chiffres s'affiche sur votre Mac.\nEntrez-le ci-dessous.")
                            .font(.subheadline).foregroundColor(Color(hex: "888888"))
                            .multilineTextAlignment(.center)
                    }

                    TextField("000000", text: $code)
                        .keyboardType(.numberPad)
                        .font(.system(size: 44, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color(hex: "8b5cf6"))
                        .onChange(of: code) { v in if v.count > 6 { code = String(v.prefix(6)) } }
                        .padding()
                        .background(Color(hex: "1a1a1a"))
                        .cornerRadius(16)
                        .padding(.horizontal, 32)

                    if let err = vm.pairingError {
                        Text(err)
                            .foregroundColor(.red).font(.callout.weight(.semibold))
                            .padding(.horizontal)
                    }

                    Button {
                        Task { await vm.confirmPairing(code: code) }
                    } label: {
                        HStack(spacing: 8) {
                            if vm.pairingPhase == .confirming {
                                ProgressView().tint(.white).scaleEffect(0.9)
                            }
                            Text(vm.pairingPhase == .confirming ? "Vérification…" : "Confirmer")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(code.count == 6 ? Color(hex: "8b5cf6") : Color(hex: "333333"))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .padding(.horizontal, 32)
                    }
                    .disabled(code.count != 6 || vm.pairingPhase != .idle)

                    Spacer()
                }
            }
            .navigationTitle("Code de jumelage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") { vm.showPairingCodeEntry = false }
                        .foregroundColor(Color(hex: "888888"))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
