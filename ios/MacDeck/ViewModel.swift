import SwiftUI
import Combine

@MainActor
class ViewModel: ObservableObject {
    @Published var volume: Double = 50
    @Published var muted: Bool = false
    @Published var connected: Bool = false
    @Published var discovering: Bool = false
    @Published var nowPlayingTitle: String = ""
    @Published var nowPlayingArtist: String = ""
    @Published var micMuted: Bool = false
    @Published var dndActive: Bool = false
    @Published var brightness: Double = 100
    @Published var audioDevices: [String] = []
    @Published var currentAudioDevice: String = ""
    @Published var macIP: String
    @Published var customApps: [CustomApp]
    @Published var battery: Int? = nil
    @Published var isCharging: Bool = false
    @Published var isDarkMode: Bool = false
    @Published var activeApp: String = ""
    @Published var currentPage: Int = 0

    private var lastActiveProfileApp: String = ""
    private var pollTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    private var discovery: ServiceDiscovery?

    var activeProfile: AppProfile? {
        appProfiles.first { $0.appName.lowercased() == activeApp.lowercased() }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "macIP") ?? ""
        macIP = saved
        APIClient.baseURL = saved.isEmpty ? "" : "http://\(saved):3000"

        customApps = {
            guard let data = UserDefaults.standard.data(forKey: "customApps"),
                  let apps = try? JSONDecoder().decode([CustomApp].self, from: data)
            else { return CustomApp.defaults }
            return apps
        }()

        $macIP
            .dropFirst()
            .debounce(for: .seconds(0.6), scheduler: RunLoop.main)
            .sink { [weak self] ip in
                UserDefaults.standard.set(ip, forKey: "macIP")
                APIClient.baseURL = ip.isEmpty ? "" : "http://\(ip):3000"
                self?.restartPolling()
            }
            .store(in: &cancellables)

        $customApps
            .dropFirst()
            .sink { apps in
                if let data = try? JSONEncoder().encode(apps) {
                    UserDefaults.standard.set(data, forKey: "customApps")
                }
            }
            .store(in: &cancellables)

        if saved.isEmpty { startDiscovery() } else { startPolling() }
    }

    // ── Discovery ─────────────────────────────────────────────────────────────────

    func startDiscovery() {
        discovering = true
        discovery?.stop()
        discovery = ServiceDiscovery { [weak self] host in
            Task { @MainActor [weak self] in
                guard let self else { return }
                discovering = false
                discovery?.stop()
                macIP = host
                UserDefaults.standard.set(host, forKey: "macIP")
                APIClient.baseURL = "http://\(host):3000"
                restartPolling()
            }
        }
        discovery?.start()
    }

    // ── Polling ───────────────────────────────────────────────────────────────────

    private func startPolling() {
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.syncStatus()
                try? await Task.sleep(nanoseconds: 5_000_000_000)
            }
        }
    }

    func restartPolling() { pollTask?.cancel(); startPolling() }

    func syncStatus() async {
        do {
            let s: SystemStatus = try await APIClient.get("/system/status")
            volume = Double(s.volume)
            muted = s.muted
            if let np = s.nowPlaying { nowPlayingTitle = np.title ?? ""; nowPlayingArtist = np.artist ?? "" }
            if let mic = s.micMuted { micMuted = mic }
            if let batt = s.battery { battery = batt }
            if let charging = s.charging { isCharging = charging }
            if let dm = s.darkMode { isDarkMode = dm }
            if let app = s.activeApp { activeApp = app }
            if !connected { fetchAudioDevices(); fetchBrightness() }
            connected = true
            updateAutoProfile()
        } catch { connected = false }
    }

    private func updateAutoProfile() {
        let profile = appProfiles.first { $0.appName.lowercased() == activeApp.lowercased() }
        if let profile = profile {
            if profile.appName != lastActiveProfileApp {
                lastActiveProfileApp = profile.appName
                currentPage = 2
            }
        } else if !lastActiveProfileApp.isEmpty {
            lastActiveProfileApp = ""
            if currentPage == 2 { currentPage = 0 }
        }
    }

    // ── Volume ────────────────────────────────────────────────────────────────────

    func adjustVolume(_ delta: Double) {
        volume = min(100, max(0, volume + delta))
        Task { await sendVolume(volume) }
    }

    @discardableResult
    func sendVolume(_ v: Double) async -> Bool {
        (try? await (APIClient.post("/volume", body: ["value": Int(v)]) as ServerResponse).success) ?? false
    }

    func commitVolume() { Task { await sendVolume(volume) } }

    func toggleMute() {
        let m = !muted; muted = m
        Task { _ = try? await (APIClient.post("/mute", body: ["muted": m]) as ServerResponse) }
    }

    func toggleMicMute() {
        Task {
            guard let r = try? await (APIClient.post("/mic/mute") as MicMuteResponse) else { return }
            if r.success { micMuted = r.micMuted }
        }
    }

    // ── Media ─────────────────────────────────────────────────────────────────────

    func playPause() { Task { _ = try? await (APIClient.post("/media/play-pause") as ServerResponse) } }
    func nextTrack() { Task { _ = try? await (APIClient.post("/media/next") as ServerResponse) } }
    func prevTrack() { Task { _ = try? await (APIClient.post("/media/prev") as ServerResponse) } }

    // ── Brightness ────────────────────────────────────────────────────────────────

    func commitBrightness() {
        let v = brightness
        Task { _ = try? await (APIClient.post("/system/brightness", body: ["value": Int(v)]) as ServerResponse) }
    }

    func fetchBrightness() {
        Task {
            if let r = try? await (APIClient.get("/system/brightness") as BrightnessResponse) {
                brightness = Double(r.value)
            }
        }
    }

    // ── Audio ─────────────────────────────────────────────────────────────────────

    func fetchAudioDevices() {
        Task {
            if let r = try? await (APIClient.get("/audio/devices") as AudioDevicesResponse) {
                audioDevices = r.devices ?? []
                currentAudioDevice = r.current ?? ""
            }
        }
    }

    func cycleAudioDevice() async -> Bool {
        guard !audioDevices.isEmpty else { return false }
        let idx = audioDevices.firstIndex(of: currentAudioDevice) ?? -1
        let next = audioDevices[(idx + 1) % audioDevices.count]
        guard let r = try? await (APIClient.post("/audio/device", body: ["name": next]) as ServerResponse) else { return false }
        if r.success { currentAudioDevice = next }
        return r.success
    }

    // ── Actions ───────────────────────────────────────────────────────────────────

    func launch(app: String) async -> Bool {
        (try? await (APIClient.post("/launch", body: ["app": app]) as ServerResponse).success) ?? false
    }

    func shortcut(keys: [String]) async -> Bool {
        (try? await (APIClient.post("/shortcut", body: ["keys": keys]) as ServerResponse).success) ?? false
    }

    func sleep() async -> Bool {
        (try? await (APIClient.post("/system/sleep") as ServerResponse).success) ?? false
    }

    func toggleDND() async -> Bool {
        guard let r = try? await (APIClient.post("/system/dnd") as ServerResponse) else { return false }
        if r.success { dndActive.toggle() }
        return r.success
    }

    func emptyTrash() async -> Bool {
        (try? await (APIClient.post("/system/trash") as ServerResponse).success) ?? false
    }

    func lockScreen() async -> Bool {
        (try? await (APIClient.post("/system/lock") as ServerResponse).success) ?? false
    }

    func sleepDisplay() async -> Bool {
        (try? await (APIClient.post("/system/sleep-display") as ServerResponse).success) ?? false
    }

    func toggleDarkMode() async -> Bool {
        guard let r = try? await (APIClient.post("/system/dark-mode") as DarkModeResponse) else { return false }
        if r.success { isDarkMode = r.darkMode }
        return r.success
    }
}
