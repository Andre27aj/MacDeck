import Network
import Foundation

class ServiceDiscovery {
    private var browser: NWBrowser?
    private let onFound: (String) -> Void

    init(onFound: @escaping (String) -> Void) {
        self.onFound = onFound
    }

    func start() {
        stop()
        let params = NWParameters()
        params.includePeerToPeer = true

        let b = NWBrowser(
            for: .bonjourWithTXTRecord(type: "_macdeck._tcp", domain: nil),
            using: params
        )
        browser = b

        let handler = onFound
        b.browseResultsChangedHandler = { results, _ in
            // Pick first result that has a valid TXT record
            for result in results {
                guard case .bonjour(let txt) = result.metadata else { continue }

                var found: String?

                // Priority: "host" key (mDNS hostname like "Mac-3.local")
                for (key, entry) in txt {
                    if key == "host", case .data(let d) = entry,
                       let val = String(data: d, encoding: .utf8), !val.isEmpty {
                        found = val
                        break
                    }
                }

                // Fallback: "ip" key
                if found == nil {
                    for (key, entry) in txt {
                        if key == "ip", case .data(let d) = entry,
                           let val = String(data: d, encoding: .utf8), !val.isEmpty {
                            found = val
                            break
                        }
                    }
                }

                if let host = found {
                    DispatchQueue.main.async { handler(host) }
                    return
                }
            }
        }

        b.start(queue: .global(qos: .userInitiated))
    }

    func stop() {
        browser?.cancel()
        browser = nil
    }
}
