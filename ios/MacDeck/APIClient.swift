import Foundation

// ── Errors ────────────────────────────────────────────────────────────────────

enum APIError: Error {
    case unauthorized
}

// ── Response models ───────────────────────────────────────────────────────────

struct ServerResponse:      Decodable { var success: Bool; var error: String? }
struct PairConfirmResponse: Decodable { var success: Bool; var token: String?; var error: String? }

struct SystemStatus: Decodable {
    var success: Bool
    var volume: Int
    var muted: Bool
    var micMuted: Bool?
    var nowPlaying: NowPlayingData?
    var battery: Int?
    var charging: Bool?
    var darkMode: Bool?
    var activeApp: String?
    var runningApps: [String]?
}

struct DarkModeResponse:    Decodable { var success: Bool; var darkMode: Bool }
struct NowPlayingData:      Decodable { var app: String?; var title: String?; var artist: String? }
struct NowPlayingResponse:  Decodable { var success: Bool; var app: String?; var title: String?; var artist: String? }
struct AppsListResponse:    Decodable { var success: Bool; var apps: [String] }
struct AudioDevicesResponse:Decodable { var success: Bool; var devices: [String]?; var current: String? }
struct BrightnessResponse:  Decodable { var success: Bool; var value: Int }
struct MicMuteResponse:     Decodable { var success: Bool; var micMuted: Bool }

// ── Client ────────────────────────────────────────────────────────────────────

enum APIClient {
    static var baseURL = ""
    static var token   = ""
    private static let timeout: TimeInterval = 5

    static func get<T: Decodable>(_ path: String) async throws -> T {
        guard !baseURL.isEmpty else { throw URLError(.badURL) }
        var req = URLRequest(url: URL(string: baseURL + path)!, timeoutInterval: timeout)
        addAuth(&req)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkAuth(response)
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func post<T: Decodable>(_ path: String, body: [String: Any] = [:]) async throws -> T {
        guard !baseURL.isEmpty else { throw URLError(.badURL) }
        var req = URLRequest(url: URL(string: baseURL + path)!, timeoutInterval: timeout)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        addAuth(&req)
        let (data, response) = try await URLSession.shared.data(for: req)
        try checkAuth(response)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static func addAuth(_ req: inout URLRequest) {
        if !token.isEmpty { req.setValue(token, forHTTPHeaderField: "X-MacDeck-Token") }
    }

    private static func checkAuth(_ response: URLResponse) throws {
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            throw APIError.unauthorized
        }
    }
}
