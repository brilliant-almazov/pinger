import Foundation
import Combine

/// Stores ping history for each target
final class HistoryStore: ObservableObject {
    /// Maximum number of results to keep per target
    private let maxResultsPerTarget: Int

    /// All stored results, keyed by target ID
    @Published private(set) var resultsByTarget: [UUID: [PingResult]] = [:]

    /// Latest results for all targets (one per target)
    @Published private(set) var latestResults: [UUID: PingResult] = [:]

    init(maxResultsPerTarget: Int = 60) {
        self.maxResultsPerTarget = maxResultsPerTarget
    }

    /// Add new results to history
    func add(results: [PingResult]) {
        for result in results {
            add(result: result)
        }
    }

    /// Add a single result to history
    func add(result: PingResult) {
        let targetId = result.targetId

        // Update latest
        latestResults[targetId] = result

        // Add to history
        var history = resultsByTarget[targetId] ?? []
        history.append(result)

        // Trim if needed
        if history.count > maxResultsPerTarget {
            history = Array(history.suffix(maxResultsPerTarget))
        }

        resultsByTarget[targetId] = history
    }

    /// Get history for a specific target
    func history(for targetId: UUID) -> [PingResult] {
        resultsByTarget[targetId] ?? []
    }

    /// Get latest result for a specific target
    func latest(for targetId: UUID) -> PingResult? {
        latestResults[targetId]
    }

    /// Clear all history
    func clear() {
        resultsByTarget.removeAll()
        latestResults.removeAll()
    }

    /// Clear history for a specific target
    func clear(for targetId: UUID) {
        resultsByTarget.removeValue(forKey: targetId)
        latestResults.removeValue(forKey: targetId)
    }

    /// Get average latency for a target (from successful pings only)
    func averageLatency(for targetId: UUID) -> TimeInterval? {
        let history = resultsByTarget[targetId] ?? []
        let successfulLatencies = history.compactMap { $0.latency }

        guard !successfulLatencies.isEmpty else { return nil }

        return successfulLatencies.reduce(0, +) / Double(successfulLatencies.count)
    }

    /// Get average latency across all targets
    func averageLatencyAll() -> TimeInterval? {
        let allLatencies = latestResults.values.compactMap { $0.latency }

        guard !allLatencies.isEmpty else { return nil }

        return allLatencies.reduce(0, +) / Double(allLatencies.count)
    }

    /// Get success rate for a target (percentage of successful pings)
    func successRate(for targetId: UUID) -> Double? {
        let history = resultsByTarget[targetId] ?? []

        guard !history.isEmpty else { return nil }

        let successCount = history.filter { $0.isSuccess }.count
        return Double(successCount) / Double(history.count)
    }
}
