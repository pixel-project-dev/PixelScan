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
        let types = ["_scanner._tcp", "_uscan._tcp", "_uscans._tcp", "_ipp._tcp"]
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
            let endpoint = Self.hostAndPort(from: connection.currentPath?.remoteEndpoint)
            connection.cancel()
            guard let endpoint else { return }
            Task { @MainActor in
                await self?.consider(host: endpoint.host, servicePort: endpoint.port, name: name, serviceType: serviceType)
            }
        }
        connection.start(queue: .global(qos: .utility))
    }

    private func consider(host: String, servicePort: Int, name: String, serviceType: String) async {
        let cleaned = host.trimmingCharacters(in: CharacterSet(charactersIn: "[]%"))
        guard DeviceName.isValidHost(cleaned), suggestions.count < 15 else { return }
        let role = DiscoveryPolicy.role(for: serviceType)
        let scanPortOpen: Bool
        if role == .printer || serviceType.lowercased().contains("_scanner._tcp") {
            let probe = await TCPProbe.check(host: cleaned, port: DeviceName.defaultPort, timeout: 1.2)
            scanPortOpen = probe.isSuccess
        } else {
            scanPortOpen = false
        }
        guard DiscoveryPolicy.shouldSuggest(serviceType: serviceType, scanPortOpen: scanPortOpen) else { return }
        let port = DiscoveryPolicy.suggestedPort(serviceType: serviceType, servicePort: servicePort, scanPortOpen: scanPortOpen)
        let hint = DiscoveryPolicy.backendHint(serviceType: serviceType, scanPortOpen: scanPortOpen)
        let key = "\(cleaned):\(port):\(hint)"
        guard !seenHosts.contains(key) else { return }
        seenHosts.insert(key)
        let detail: String
        if role == .printer {
            detail = L10n.text("This printer answers the scan port. A print service alone is not treated as a scanner.")
        } else if hint == DeviceAddress.webScan {
            detail = L10n.text("This device announces a scan service.")
        } else {
            detail = L10n.text("This device announces itself as a scanner.")
        }
        suggestions.append(DiscoveredScanner(
            name: name.isEmpty ? cleaned : name,
            host: cleaned,
            port: port,
            serviceType: serviceType,
            backendHint: hint,
            secureConnection: DiscoveryPolicy.usesSecureWeb(serviceType: serviceType),
            detail: detail
        ))
    }

    nonisolated private static func hostAndPort(from endpoint: NWEndpoint?) -> (host: String, port: Int)? {
        guard case let .hostPort(host, port) = endpoint else { return nil }
        let value: String?
        switch host {
        case let .ipv4(address):
            value = "\(address)"
        case let .ipv6(address):
            value = "\(address)"
        case let .name(name, _):
            value = name
        @unknown default:
            value = nil
        }
        guard let value else { return nil }
        return (value, Int(port.rawValue))
    }
}

private extension Result where Failure == ScanFailure {
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
}
