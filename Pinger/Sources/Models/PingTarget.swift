import Foundation

/// Represents a target host to ping
struct PingTarget: Identifiable, Codable, Equatable {
    let id: UUID
    var host: String
    var name: String
    var isEnabled: Bool

    init(id: UUID = UUID(), host: String, name: String, isEnabled: Bool = true) {
        self.id = id
        self.host = host
        self.name = name
        self.isEnabled = isEnabled
    }
}

// MARK: - Default Targets

extension PingTarget {
    static let googleDNS = PingTarget(
        host: "8.8.8.8",
        name: "Google DNS"
    )

    static let cloudflareDNS = PingTarget(
        host: "1.1.1.1",
        name: "Cloudflare"
    )

    static let openDNS = PingTarget(
        host: "208.67.222.222",
        name: "OpenDNS",
        isEnabled: false
    )

    static var defaults: [PingTarget] {
        [.googleDNS, .cloudflareDNS, .openDNS]
    }
}
