import Foundation
import Combine

/// Protocol for ping operations
protocol PingServiceProtocol {
    func ping(target: PingTarget) async -> PingResult
    func startContinuousPing(targets: [PingTarget], interval: TimeInterval) -> AnyPublisher<[PingResult], Never>
    func stop()
}

/// Service for performing ICMP ping operations
final class PingService: PingServiceProtocol {
    private var cancellables = Set<AnyCancellable>()
    private var isRunning = false
    private let pingSubject = PassthroughSubject<[PingResult], Never>()

    /// Ping a single target once
    func ping(target: PingTarget) async -> PingResult {
        await withCheckedContinuation { continuation in
            performPing(target: target) { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// Start continuous ping for multiple targets
    func startContinuousPing(targets: [PingTarget], interval: TimeInterval) -> AnyPublisher<[PingResult], Never> {
        stop()
        isRunning = true

        let enabledTargets = targets.filter { $0.isEnabled }

        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, self.isRunning else { return }
                self.pingAllTargets(enabledTargets)
            }
            .store(in: &cancellables)

        // Initial ping
        pingAllTargets(enabledTargets)

        return pingSubject.eraseToAnyPublisher()
    }

    /// Stop continuous pinging
    func stop() {
        isRunning = false
        cancellables.removeAll()
    }

    // MARK: - Private

    private var latestResults: [UUID: PingResult] = [:]

    private func pingAllTargets(_ targets: [PingTarget]) {
        Task {
            await withTaskGroup(of: PingResult.self) { group in
                for target in targets {
                    group.addTask {
                        await self.ping(target: target)
                    }
                }

                // Send results as they arrive
                for await result in group {
                    await MainActor.run {
                        self.latestResults[result.targetId] = result
                        self.pingSubject.send(Array(self.latestResults.values))
                    }
                }
            }
        }
    }

    private func performPing(target: PingTarget, completion: @escaping (PingResult) -> Void) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-W", "1000", target.host]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        let startTime = Date()

        do {
            try process.run()

            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()

                let endTime = Date()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? ""

                if process.terminationStatus == 0 {
                    // Parse latency from output
                    let latency = self.parseLatency(from: output) ?? endTime.timeIntervalSince(startTime)
                    completion(.success(targetId: target.id, latency: latency))
                } else {
                    completion(.failure(targetId: target.id, error: "Host unreachable"))
                }
            }
        } catch {
            completion(.failure(targetId: target.id, error: error.localizedDescription))
        }
    }

    private func parseLatency(from output: String) -> TimeInterval? {
        // Parse "time=12.345 ms" from ping output
        let pattern = #"time[=<](\d+\.?\d*)\s*ms"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []),
              let match = regex.firstMatch(in: output, options: [], range: NSRange(output.startIndex..., in: output)),
              let range = Range(match.range(at: 1), in: output),
              let ms = Double(output[range]) else {
            return nil
        }
        return ms / 1000.0
    }
}
