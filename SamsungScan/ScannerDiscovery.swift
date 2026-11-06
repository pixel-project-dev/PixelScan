import Foundation
import Network

@MainActor
@Observable
final class ScannerDiscovery {
    var isRunning = false
    var suggestions: [DiscoveredScanner] = []
    private var browsers: [NWBrowser] = []
    private var seenHosts: Set<String> = []
    private var connections: [NWConnection] = []
    private var stopTask: Task<Void, Never>?

    func start() {
        stop()
        isRunning = true
        suggestions = []
        seenHosts = []
        let types = ["_scanner._tcp", "_uscan._tcp", "_ipp._tcp"]
        for type in types {
            let parameters = NWParameters.tcp
            parameters.includePeerToPeer = false
            let browser = NWBrowser(for: .bonjour(type: type, domain: nil), using: parameters)
            browser.browseResultsChangedHandler = { [weak self] results, _ in
                Task { @MainActor in
                    self?.ingest(results, serviceType: type)
                }
            }
            browser.start(queue: .main)
            browsers.append(browser)
        }
        stopTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            await MainActor.run {
                self?.stop()
            }
        }
    }

    func stop() {
        stopTask?.cancel()
        stopTask = nil
        for browser in browsers {
            browser.cancel()
        }
        browsers.removeAll()
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
        isRunning = false
    }

    private func ingest(_ results: Set<NWBrowser.Result>, serviceType: String) {
        guard suggestions.count < 15 else { return }
        for result in results {
            guard case let .service(name, _, _, _) = result.endpoint else { continue }
            resolve(result.endpoint, name: name, serviceType: serviceType)
        }
    }

    private func resolve(_ endpoint: NWEndpoint, name: String, serviceType: String) {
        guard connections.count < 20 else { return }
        let connection = NWConnection(to: endpoint, using: .tcp)
        connections.append(connection)
        connection.stateUpdateHandler = { [weak self] state in
            guard case .ready = state else {
                if case .failed = state {
                    connection.cancel()
                }
                return
            }
            let host = Self.hostString(from: connection.currentPath?.remoteEndpoint)
            connection.cancel()
            guard let host else { return }
            Task { @MainActor in
                await self?.consider(host: host, name: name, serviceType: serviceType)
            }
        }
        connection.start(queue: .global(qos: .utility))
    }

    private func consider(host: String, name: String, serviceType: String) async {
        let cleaned = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]%"))
        guard DeviceName.isValidHost(cleaned), !seenHosts.contains(cleaned), suggestions.count < 15 else { return }
        seenHosts.insert(cleaned)
        let probe = await TCPProbe.check(host: cleaned, port: DeviceName.defaultPort, timeout: 1.2)
        guard case .success = probe else { return }
        guard !suggestions.contains(where: { $0.host == cleaned }) else { return }
        suggestions.append(DiscoveredScanner(
            name: name.isEmpty ? cleaned : name,
            host: cleaned,
            port: DeviceName.defaultPort,
            serviceType: serviceType
        ))
    }

    nonisolated private static func hostString(from endpoint: NWEndpoint?) -> String? {
        guard case let .hostPort(host, _) = endpoint else { return nil }
        switch host {
        case let .ipv4(address):
            return "\(address)"
        case let .ipv6(address):
            return "\(address)"
        case let .name(name, _):
            return name
        @unknown default:
            return nil
        }
    }
}
