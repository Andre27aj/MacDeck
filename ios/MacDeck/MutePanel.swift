import SwiftUI

struct MutePanel: View {
    @ObservedObject var vm: ViewModel

    var body: some View {
        HStack(spacing: 8) {
            muteBtn(
                icon: vm.micMuted ? "mic.slash.fill" : "mic.fill",
                label: "Micro",
                active: vm.micMuted,
                action: vm.toggleMicMute
            )
            muteBtn(
                icon: vm.muted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                label: "Son",
                active: vm.muted,
                action: vm.toggleMute
            )
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func muteBtn(icon: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(active ? .white : Color(hex: "ef4444"))
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(active ? .white.opacity(0.85) : Color(hex: "666666"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(active ? Color(hex: "ef4444") : Color(hex: "1a1a1a"))
            .cornerRadius(10)
            .overlay(RoundedRectangle(cornerRadius: 10)
                .stroke(active ? Color(hex: "ef4444") : Color(hex: "2a2a2a"), lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
