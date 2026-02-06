import Foundation

/// Result of a single ping attempt
struct PingResult: Identifiable, Equatable {
    let id: UUID
    let targetId: UUID
    let timestamp: Date
    let latency: TimeInterval?
    let isSuccess: Bool
    let error: String?

    init(
        id: UUID = UUID(),
        targetId: UUID,
        timestamp: Date = Date(),
        latency: TimeInterval? = nil,
        isSuccess: Bool,
        error: String? = nil
    ) {
        self.id = id
        self.targetId = targetId
        self.timestamp = timestamp
        self.latency = latency
        self.isSuccess = isSuccess
        self.error = error
    }

    /// Latency in milliseconds
    var latencyMs: Int? {
        guard let latency = latency else { return nil }
        return Int(latency * 1000)
    }
}

// MARK: - Convenience Initializers

extension PingResult {
    static func success(targetId: UUID, latency: TimeInterval) -> PingResult {
        PingResult(
            targetId: targetId,
            latency: latency,
            isSuccess: true
        )
    }

    static func failure(targetId: UUID, error: String) -> PingResult {
        PingResult(
            targetId: targetId,
            isSuccess: false,
            error: error
        )
    }
}
