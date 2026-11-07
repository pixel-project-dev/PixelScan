import Foundation
import Network

enum TCPProbe {
    static func check(host: String, port: Int, timeout: TimeInterval = 4) async -> Result<Void, ScanFailure> {
        guard DeviceName.isValidHost(host), let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            return .failure(.invalidAddress)
        }
        let connection = NWConnection(host: NWEndpoint.Host(host), port: nwPort, using: .tcp)
        return await withCheckedContinuation { continuation in
            let gate = ProbeGate()
            let finish: @Sendable (Result<Void, ScanFailure>) -> Void = { result in
                gate.finish {
                    connection.cancel()
                    continuation.resume(returning: result)
                }
            }
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    finish(.success(()))
                case .failed(let error):
                    finish(.failure(map(error)))
                default:
                    break
                }
            }
            connection.start(queue: .global(qos: .userInitiated))
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
                finish(.failure(.portUnreachable))
            }
        }
    }

    private static func map(_ error: NWError) -> ScanFailure {
        switch error {
        case .dns:
            return .unreachable
        case .posix(let code):
            switch code {
            case .ECONNREFUSED, .ETIMEDOUT, .ENOTCONN:
                return .portUnreachable
            case .EHOSTUNREACH, .ENETUNREACH, .EHOSTDOWN, .ENETDOWN:
                return .unreachable
            default:
                return .unreachable
            }
        case .tls:
            return .portUnreachable
        default:
            return .unreachable
        }
    }
}

private final class ProbeGate: @unchecked Sendable {
    private let lock = NSLock()
    private var finished = false

    func finish(_ body: () -> Void) {
        lock.lock()
        let shouldRun = !finished
        if shouldRun { finished = true }
        lock.unlock()
        if shouldRun { body() }
    }
}
