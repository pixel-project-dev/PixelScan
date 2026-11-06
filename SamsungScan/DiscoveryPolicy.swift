import Foundation

enum DiscoveryPolicy {
    static func role(for serviceType: String) -> ServiceRole {
        let type = serviceType.lowercased()
        if type.contains("_ipp._tcp") { return .printer }
        if type.contains("_uscan._tcp") || type.contains("_uscans._tcp") || type.contains("_scanner._tcp") {
            return .scanAnnouncement
        }
        return .ignored
    }

    static func shouldSuggest(serviceType: String, scanPortOpen: Bool) -> Bool {
        switch role(for: serviceType) {
        case .printer:
            return scanPortOpen
        case .scanAnnouncement:
            return true
        case .ignored:
            return false
        }
    }

    static func suggestedPort(serviceType: String, servicePort: Int?, scanPortOpen: Bool) -> Int {
        let type = serviceType.lowercased()
        if type.contains("_ipp._tcp") { return DeviceName.defaultPort }
        if type.contains("_scanner._tcp"), scanPortOpen { return DeviceName.defaultPort }
        if let servicePort, (1...65535).contains(servicePort) { return servicePort }
        if type.contains("_uscans._tcp") { return 443 }
        if type.contains("_uscan._tcp") { return 80 }
        return DeviceName.defaultPort
    }

    static func backendHint(serviceType: String, scanPortOpen: Bool) -> String {
        let type = serviceType.lowercased()
        if type.contains("_uscans._tcp") || type.contains("_uscan._tcp") { return DeviceAddress.webScan }
        if scanPortOpen || type.contains("_ipp._tcp") || type.contains("_scanner._tcp") {
            return DeviceAddress.samsungNetwork
        }
        return DeviceAddress.samsungNetwork
    }

    static func usesSecureWeb(serviceType: String) -> Bool {
        serviceType.lowercased().contains("_uscans._tcp")
    }
}

enum ServiceRole {
    case printer
    case scanAnnouncement
    case ignored
}
