import SwiftUI

struct LeftPanel: View {
    @ObservedObject var vm: ViewModel
    var isPortrait: Bool = false

    var body: some View {
        if isPortrait {
            PortraitControls(vm: vm)
        } else {
            VStack(spacing: 8) {
                VolumeCard(vm: vm)
                MediaCard(vm: vm)
            }
        }
    }
}

// ── Portrait : barre de contrôles compacte pleine largeur ─────────────────────

struct PortraitControls: View {
    @ObservedObject var vm: ViewModel

    var body: some View {
        VStack(spacing: 12) {

            // Volume
            HStack(spacing: 10) {
                Image(systemName: "speaker.wave.1.fill")
                    .foregroundColor(Color(hex: "7c3aed"))
                    .font(.system(size: 14))
                    .frame(width: 18)
                HorizontalSlider(value: $vm.volume,
                                 gradient: [Color(hex: "4f46e5"), Color(hex: "7c3aed")]) {
                    vm.commitVolume()
                }
                Text("\(Int(vm.volume))")
                    .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.white)
                    .frame(width: 30, alignment: .trailing)
            }

            // Luminosité
            HStack(spacing: 10) {
                Image(systemName: "sun.min.fill")
                    .foregroundColor(Color(hex: "f59e0b"))
                    .font(.system(size: 14))
                    .frame(width: 18)
                HorizontalSlider(value: $vm.brightness,
                                 gradient: [Color(hex: "d97706"), Color(hex: "fbbf24")]) {
                    vm.commitBrightness()
                }
                Image(systemName: "sun.max.fill")
                    .foregroundColor(Color(hex: "f59e0b"))
                    .font(.system(size: 14))
                    .frame(width: 18)
            }

            // Médias + mute
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(vm.nowPlayingTitle.isEmpty ? "—" : vm.nowPlayingTitle)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    if !vm.nowPlayingArtist.isEmpty {
                        Text(vm.nowPlayingArtist)
                            .font(.system(size: 9))
                            .foregroundColor(Color(hex: "666666"))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                mediaBtn("backward.fill")  { vm.prevTrack() }
                mediaBtn("playpause.fill") { vm.playPause() }
                mediaBtn("forward.fill")   { vm.nextTrack() }

                Rectangle()
                    .fill(Color(hex: "333333"))
                    .frame(width: 1, height: 24)

                iconBtn(icon: vm.micMuted ? "mic.slash.fill" : "mic.fill",
                        active: vm.micMuted) { vm.toggleMicMute() }
                iconBtn(icon: vm.muted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                        active: vm.muted)   { vm.toggleMute() }
            }
        }
        .padding(14)
        .background(Color(hex: "1a1a1a"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "2a2a2a"), lineWidth: 1))
    }

    @ViewBuilder
    private func mediaBtn(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(hex: "10b981"))
                .frame(width: 36, height: 36)
                .background(Color(hex: "222222"))
                .cornerRadius(8)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func iconBtn(icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(active ? .white : Color(hex: "ef4444"))
                .frame(width: 36, height: 36)
                .background(active ? Color(hex: "ef4444") : Color(hex: "222222"))
                .cornerRadius(8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// ── Slider horizontal ──────────────────────────────────────────────────────────

struct HorizontalSlider: View {
    @Binding var value: Double
    var gradient: [Color]
    var onEditEnd: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let pct = CGFloat(value / 100)
            let fillW = max(24, w * pct)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(hex: "111111"))
                    .overlay(Capsule().stroke(Color(hex: "2a2a2a"), lineWidth: 1))

                Capsule()
                    .fill(LinearGradient(colors: gradient,
                                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: fillW)

                Circle()
                    .fill(Color.white)
                    .frame(width: 26, height: 26)
                    .shadow(color: .black.opacity(0.4), radius: 3)
                    .padding(.leading, max(0, w * pct - 13))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { g in
                        value = min(100, max(0, Double(g.location.x / w) * 100))
                    }
                    .onEnded { g in
                        value = min(100, max(0, Double(g.location.x / w) * 100))
                        onEditEnd()
                    }
            )
        }
        .frame(height: 70)
    }
}

// ── Volume card (paysage) ──────────────────────────────────────────────────────

struct VolumeCard: View {
    @ObservedObject var vm: ViewModel

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                cardLabel("Volume")
                Spacer()
                Text("\(Int(vm.volume))")
                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.white)
            }

            HStack(spacing: 10) {
                VStack(spacing: 6) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "7c3aed").opacity(0.7))
                    VolumeSliderVertical(value: $vm.volume) { vm.commitVolume() }
                        .frame(maxHeight: .infinity)
                    Image(systemName: "speaker.slash")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "555555"))
                }
                .frame(width: 44)

                VStack(spacing: 10) {
                    volBtn("plus")  { vm.adjustVolume(+5) }
                    Spacer()
                    volBtn("minus") { vm.adjustVolume(-5) }
                }

                VStack(spacing: 6) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "f59e0b").opacity(0.7))
                    BrightnessSliderVertical(value: $vm.brightness) { vm.commitBrightness() }
                        .frame(maxHeight: .infinity)
                    Image(systemName: "sun.min.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "555555"))
                }
                .frame(width: 44)
            }
            .frame(maxHeight: .infinity)

            Button(action: vm.toggleMute) {
                HStack(spacing: 5) {
                    Image(systemName: vm.muted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 13))
                    Text(vm.muted ? "Unmute" : "Muet")
                        .font(.system(size: 12, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(vm.muted ? Color.red : Color(hex: "2a2a2a"))
                .cornerRadius(8)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(12)
        .frame(maxHeight: .infinity)
        .background(Color(hex: "1a1a1a"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "2a2a2a"), lineWidth: 1))
    }

    @ViewBuilder
    private func volBtn(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color(hex: "2a2a2a"))
                .cornerRadius(8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// ── Vertical sliders (paysage uniquement) ─────────────────────────────────────

struct VolumeSliderVertical: View {
    @Binding var value: Double
    var onEditEnd: () -> Void

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let pct = CGFloat(value / 100)
            let fillH = max(14, h * pct)

            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color(hex: "111111"))
                    .overlay(Capsule().stroke(Color(hex: "2a2a2a"), lineWidth: 1))
                    .frame(maxHeight: .infinity)
                Capsule()
                    .fill(LinearGradient(colors: [Color(hex: "4f46e5"), Color(hex: "7c3aed")],
                                        startPoint: .bottom, endPoint: .top))
                    .frame(height: fillH)
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .shadow(color: .black.opacity(0.4), radius: 3)
                    .padding(.bottom, max(0, h * pct - 14))
            }
            .frame(width: 44).frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { g in value = min(100, max(0, Double((h - g.location.y) / h) * 100)) }
                .onEnded   { g in value = min(100, max(0, Double((h - g.location.y) / h) * 100)); onEditEnd() }
            )
        }
    }
}

struct BrightnessSliderVertical: View {
    @Binding var value: Double
    var onEditEnd: () -> Void

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let pct = CGFloat(value / 100)
            let fillH = max(14, h * pct)

            ZStack(alignment: .bottom) {
                Capsule()
                    .fill(Color(hex: "111111"))
                    .overlay(Capsule().stroke(Color(hex: "2a2a2a"), lineWidth: 1))
                    .frame(maxHeight: .infinity)
                Capsule()
                    .fill(LinearGradient(colors: [Color(hex: "d97706"), Color(hex: "fbbf24")],
                                        startPoint: .bottom, endPoint: .top))
                    .frame(height: fillH)
                Circle()
                    .fill(Color.white)
                    .frame(width: 28, height: 28)
                    .shadow(color: .black.opacity(0.4), radius: 3)
                    .padding(.bottom, max(0, h * pct - 14))
            }
            .frame(width: 44).frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { g in value = min(100, max(0, Double((h - g.location.y) / h) * 100)) }
                .onEnded   { g in value = min(100, max(0, Double((h - g.location.y) / h) * 100)); onEditEnd() }
            )
        }
    }
}

// ── Media card (paysage) ───────────────────────────────────────────────────────

struct MediaCard: View {
    @ObservedObject var vm: ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            cardLabel("Média")
            VStack(alignment: .leading, spacing: 2) {
                Text(vm.nowPlayingTitle.isEmpty ? "—" : vm.nowPlayingTitle)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !vm.nowPlayingArtist.isEmpty {
                    Text(vm.nowPlayingArtist)
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "666666"))
                        .lineLimit(1)
                }
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)

            HStack(spacing: 6) {
                mediaBtn("backward.fill") { vm.prevTrack() }
                mediaBtn("playpause.fill") { vm.playPause() }
                mediaBtn("forward.fill")  { vm.nextTrack() }
                muteBtn(icon: vm.micMuted ? "mic.slash.fill" : "mic.fill", active: vm.micMuted) { vm.toggleMicMute() }
                muteBtn(icon: vm.muted ? "speaker.slash.fill" : "speaker.wave.2.fill", active: vm.muted) { vm.toggleMute() }
            }
        }
        .padding(12)
        .background(Color(hex: "1a1a1a"))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color(hex: "2a2a2a"), lineWidth: 1))
    }

    @ViewBuilder
    private func mediaBtn(_ symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Color(hex: "10b981"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(Color(hex: "222222"))
                .cornerRadius(8)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private func muteBtn(icon: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(active ? .white : Color(hex: "ef4444"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(active ? Color(hex: "ef4444") : Color(hex: "222222"))
                .cornerRadius(8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

@ViewBuilder
func cardLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.system(size: 9, weight: .bold))
        .tracking(1.5)
        .foregroundColor(Color(hex: "555555"))
}
