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
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(active ? .white : Color(hex: "ef4444"))
                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(active ? .white.opacity(0.85) : Color(hex: "666666"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(active ? Color(hex: "ef4444") : Color(hex: "1a1a1a"))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                .stroke(active ? Color(hex: "ef4444") : Color(hex: "2a2a2a"), lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
