import XCTest
@testable import Pinger

final class StatusCalculatorTests: XCTestCase {
    var historyStore: HistoryStore!
    var settingsStore: SettingsStore!
    var testDefaults: UserDefaults!
    var sut: StatusCalculator!

    override func setUp() {
        super.setUp()
        historyStore = HistoryStore()
        testDefaults = UserDefaults(suiteName: "StatusCalcTestDefaults")!
        testDefaults.removePersistentDomain(forName: "StatusCalcTestDefaults")
        settingsStore = SettingsStore(defaults: testDefaults)
        sut = StatusCalculator(historyStore: historyStore, settingsStore: settingsStore)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "StatusCalcTestDefaults")
        testDefaults = nil
        historyStore = nil
        settingsStore = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Status Calculation Tests

    func testGoodStatus() {
        let results = [
            PingResult.success(targetId: UUID(), latency: 0.012),
            PingResult.success(targetId: UUID(), latency: 0.015)
        ]

        let (status, avg) = sut.calculateStatus(from: results, threshold: 100)

        XCTAssertEqual(status, .good)
        XCTAssertNotNil(avg)
        XCTAssertLessThanOrEqual(avg!, 100)
    }

    func testDegradedStatus() {
        let results = [
            PingResult.success(targetId: UUID(), latency: 0.150),
            PingResult.success(targetId: UUID(), latency: 0.200)
        ]

        let (status, avg) = sut.calculateStatus(from: results, threshold: 100)

        XCTAssertEqual(status, .degraded)
        XCTAssertGreaterThan(avg!, 100)
    }

    func testPartialStatus() {
        let results = [
            PingResult.success(targetId: UUID(), latency: 0.012),
            PingResult.failure(targetId: UUID(), error: "Timeout")
        ]

        let (status, _) = sut.calculateStatus(from: results, threshold: 100)

        XCTAssertEqual(status, .partial)
    }

    func testOfflineStatus() {
        let results = [
            PingResult.failure(targetId: UUID(), error: "Timeout"),
            PingResult.failure(targetId: UUID(), error: "Unreachable")
        ]

        let (status, avg) = sut.calculateStatus(from: results, threshold: 100)

        XCTAssertEqual(status, .offline)
        XCTAssertNil(avg)
    }

    func testPausedStatus() {
        let results = [
            PingResult.success(targetId: UUID(), latency: 0.012)
        ]

        let (status, avg) = sut.calculateStatus(from: results, threshold: 100, isPaused: true)

        XCTAssertEqual(status, .paused)
        XCTAssertNil(avg)
    }

    func testUnknownStatusWithNoResults() {
        let results: [PingResult] = []

        let (status, avg) = sut.calculateStatus(from: results, threshold: 100)

        XCTAssertEqual(status, .unknown)
        XCTAssertNil(avg)
    }

    // MARK: - Average Calculation Tests

    func testAverageLatencyCalculation() {
        let results = [
            PingResult.success(targetId: UUID(), latency: 0.010), // 10ms
            PingResult.success(targetId: UUID(), latency: 0.020), // 20ms
            PingResult.success(targetId: UUID(), latency: 0.030)  // 30ms
        ]

        let (_, avg) = sut.calculateStatus(from: results, threshold: 100)

        XCTAssertEqual(avg, 20)
    }

    func testAverageExcludesFailures() {
        let results = [
            PingResult.success(targetId: UUID(), latency: 0.010),
            PingResult.failure(targetId: UUID(), error: "Timeout"),
            PingResult.success(targetId: UUID(), latency: 0.030)
        ]

        let (_, avg) = sut.calculateStatus(from: results, threshold: 100)

        XCTAssertEqual(avg, 20)
    }

    // MARK: - Threshold Edge Cases

    func testExactlyAtThreshold() {
        let results = [
            PingResult.success(targetId: UUID(), latency: 0.100) // 100ms
        ]

        let (status, _) = sut.calculateStatus(from: results, threshold: 100)

        // At threshold is still good (> not >=)
        XCTAssertEqual(status, .good)
    }

    func testJustAboveThreshold() {
        let results = [
            PingResult.success(targetId: UUID(), latency: 0.101) // 101ms
        ]

        let (status, _) = sut.calculateStatus(from: results, threshold: 100)

        XCTAssertEqual(status, .degraded)
    }

    // MARK: - Format Tests

    func testFormatLatency() {
        XCTAssertEqual(StatusCalculator.formatLatency(12), "12ms")
        XCTAssertEqual(StatusCalculator.formatLatency(150), "150ms")
        XCTAssertEqual(StatusCalculator.formatLatency(nil), "--")
        XCTAssertEqual(StatusCalculator.formatLatency(0), "0ms")
    }

    // MARK: - ConnectionStatus Tests

    func testConnectionStatusEmoji() {
        XCTAssertEqual(ConnectionStatus.good.emoji, "🟢")
        XCTAssertEqual(ConnectionStatus.degraded.emoji, "🟡")
        XCTAssertEqual(ConnectionStatus.partial.emoji, "🟠")
        XCTAssertEqual(ConnectionStatus.offline.emoji, "🔴")
        XCTAssertEqual(ConnectionStatus.paused.emoji, "⏸")
        XCTAssertEqual(ConnectionStatus.unknown.emoji, "⏳")
    }

    func testConnectionStatusColor() {
        XCTAssertEqual(ConnectionStatus.good.color, .green)
        XCTAssertEqual(ConnectionStatus.degraded.color, .yellow)
        XCTAssertEqual(ConnectionStatus.offline.color, .red)
    }
}
