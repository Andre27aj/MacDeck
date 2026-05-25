import Foundation

// ── Response models ──────────────────────────────────────────────────────────

struct ServerResponse: Decodable { var success: Bool; var error: String? }

struct SystemStatus: Decodable {
    var success: Bool
    var volume: Int
    var muted: Bool
    var micMuted: Bool?
    var nowPlaying: NowPlayingData?
}

struct NowPlayingData: Decodable {
    var app: String?
    var title: String?
    var artist: String?
}

struct NowPlayingResponse: Decodable {
    var success: Bool
    var app: String?
    var title: String?
    var artist: String?
}

struct AppsListResponse: Decodable {
    var success: Bool
    var apps: [String]
}

struct AudioDevicesResponse: Decodable {
    var success: Bool
    var devices: [String]?
    var current: String?
}

struct BrightnessResponse: Decodable {
    var success: Bool
    var value: Int
}

struct MicMuteResponse: Decodable {
    var success: Bool
    var micMuted: Bool
}

// ── Client ───────────────────────────────────────────────────────────────────

enum APIClient {
    static var baseURL = ""
    private static let timeout: TimeInterval = 5

    static func get<T: Decodable>(_ path: String) async throws -> T {
        guard !baseURL.isEmpty else { throw URLError(.badURL) }
        let url = URL(string: baseURL + path)!
        var req = URLRequest(url: url, timeoutInterval: timeout)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func post<T: Decodable>(_ path: String, body: [String: Any] = [:]) async throws -> T {
        guard !baseURL.isEmpty else { throw URLError(.badURL) }
        let url = URL(string: baseURL + path)!
        var req = URLRequest(url: url, timeoutInterval: timeout)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
