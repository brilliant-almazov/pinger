import Foundation
import Combine

/// Calculates connection status from ping results
final class StatusCalculator: ObservableObject {
    @Published private(set) var status: ConnectionStatus = .unknown
    @Published private(set) var averageLatencyMs: Int?
    @Published private(set) var displayText: String = "⏳ --"

    private let historyStore: HistoryStore
    private let settingsStore: SettingsStore
    private var cancellables = Set<AnyCancellable>()

    init(historyStore: HistoryStore, settingsStore: SettingsStore) {
        self.historyStore = historyStore
        self.settingsStore = settingsStore

        setupBindings()
    }

    private func setupBindings() {
        // Recalculate when latest results change
        historyStore.$latestResults
            .combineLatest(settingsStore.$isPaused, settingsStore.$badPingThreshold)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] results, isPaused, threshold in
                self?.calculate(results: results, isPaused: isPaused, threshold: threshold)
            }
            .store(in: &cancellables)
    }

    private func calculate(results: [UUID: PingResult], isPaused: Bool, threshold: Int) {
        // Handle paused state
        if isPaused {
            status = .paused
            displayText = "\(status.emoji) --"
            return
        }

        // Handle no results
        guard !results.isEmpty else {
            status = .unknown
            averageLatencyMs = nil
            displayText = "\(status.emoji) --"
            return
        }

        // Calculate statistics
        let successfulResults = results.values.filter { $0.isSuccess }
        let failedCount = results.count - successfulResults.count

        // Calculate average latency from successful pings
        let latencies = successfulResults.compactMap { $0.latencyMs }
        let avgLatency: Int? = latencies.isEmpty ? nil : latencies.reduce(0, +) / latencies.count

        averageLatencyMs = avgLatency

        // Determine status
        if successfulResults.isEmpty {
            // All failed
            status = .offline
        } else if failedCount > 0 {
            // Some failed
            status = .partial
        } else if let avg = avgLatency, avg > threshold {
            // All succeeded but slow
            status = .degraded
        } else {
            // All good
            status = .good
        }

        // Update display text (fixed width: 3 digits)
        if let avg = avgLatency {
            let formatted = String(format: "%3d", min(avg, 999))
            displayText = "\(status.emoji) \(formatted)ms"
        } else {
            displayText = "\(status.emoji)  --"
        }
    }

    /// Calculate status from a single batch of results (for testing)
    func calculateStatus(
        from results: [PingResult],
        threshold: Int,
        isPaused: Bool = false
    ) -> (status: ConnectionStatus, averageMs: Int?) {
        if isPaused {
            return (.paused, nil)
        }

        guard !results.isEmpty else {
            return (.unknown, nil)
        }

        let successful = results.filter { $0.isSuccess }
        let failedCount = results.count - successful.count
        let latencies = successful.compactMap { $0.latencyMs }
        let avgLatency: Int? = latencies.isEmpty ? nil : latencies.reduce(0, +) / latencies.count

        let status: ConnectionStatus
        if successful.isEmpty {
            status = .offline
        } else if failedCount > 0 {
            status = .partial
        } else if let avg = avgLatency, avg > threshold {
            status = .degraded
        } else {
            status = .good
        }

        return (status, avgLatency)
    }

    /// Format latency for display
    static func formatLatency(_ ms: Int?) -> String {
        guard let ms = ms else { return "--" }
        return "\(ms)ms"
    }
}
