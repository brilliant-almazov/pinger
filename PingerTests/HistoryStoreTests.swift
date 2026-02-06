import XCTest
@testable import Pinger

final class HistoryStoreTests: XCTestCase {
    var sut: HistoryStore!

    override func setUp() {
        super.setUp()
        sut = HistoryStore(maxResultsPerTarget: 10)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testAddResult() {
        let targetId = UUID()
        let result = PingResult.success(targetId: targetId, latency: 0.012)

        sut.add(result: result)

        XCTAssertEqual(sut.history(for: targetId).count, 1)
        XCTAssertEqual(sut.latest(for: targetId)?.id, result.id)
    }

    func testAddMultipleResults() {
        let targetId = UUID()
        let results = (1...5).map { i in
            PingResult.success(targetId: targetId, latency: Double(i) / 1000)
        }

        sut.add(results: results)

        XCTAssertEqual(sut.history(for: targetId).count, 5)
        XCTAssertEqual(sut.latest(for: targetId)?.latencyMs, 5)
    }

    func testHistoryTrimming() {
        let targetId = UUID()

        // Add more than max (10)
        for i in 1...15 {
            let result = PingResult.success(targetId: targetId, latency: Double(i) / 1000)
            sut.add(result: result)
        }

        let history = sut.history(for: targetId)
        XCTAssertEqual(history.count, 10)
        // Should keep the last 10 (6-15)
        XCTAssertEqual(history.first?.latencyMs, 6)
        XCTAssertEqual(history.last?.latencyMs, 15)
    }

    func testClearAll() {
        let targetId1 = UUID()
        let targetId2 = UUID()

        sut.add(result: PingResult.success(targetId: targetId1, latency: 0.01))
        sut.add(result: PingResult.success(targetId: targetId2, latency: 0.02))

        sut.clear()

        XCTAssertTrue(sut.history(for: targetId1).isEmpty)
        XCTAssertTrue(sut.history(for: targetId2).isEmpty)
        XCTAssertNil(sut.latest(for: targetId1))
        XCTAssertNil(sut.latest(for: targetId2))
    }

    func testClearForTarget() {
        let targetId1 = UUID()
        let targetId2 = UUID()

        sut.add(result: PingResult.success(targetId: targetId1, latency: 0.01))
        sut.add(result: PingResult.success(targetId: targetId2, latency: 0.02))

        sut.clear(for: targetId1)

        XCTAssertTrue(sut.history(for: targetId1).isEmpty)
        XCTAssertEqual(sut.history(for: targetId2).count, 1)
    }

    func testAverageLatency() {
        let targetId = UUID()

        sut.add(result: PingResult.success(targetId: targetId, latency: 0.010))
        sut.add(result: PingResult.success(targetId: targetId, latency: 0.020))
        sut.add(result: PingResult.success(targetId: targetId, latency: 0.030))

        let average = sut.averageLatency(for: targetId)
        XCTAssertEqual(average! * 1000, 20, accuracy: 0.001)
    }

    func testAverageLatencyExcludesFailures() {
        let targetId = UUID()

        sut.add(result: PingResult.success(targetId: targetId, latency: 0.010))
        sut.add(result: PingResult.failure(targetId: targetId, error: "Timeout"))
        sut.add(result: PingResult.success(targetId: targetId, latency: 0.030))

        let average = sut.averageLatency(for: targetId)
        XCTAssertEqual(average! * 1000, 20, accuracy: 0.001)
    }

    func testAverageLatencyAllTargets() {
        let targetId1 = UUID()
        let targetId2 = UUID()

        sut.add(result: PingResult.success(targetId: targetId1, latency: 0.010))
        sut.add(result: PingResult.success(targetId: targetId2, latency: 0.030))

        let average = sut.averageLatencyAll()
        XCTAssertEqual(average! * 1000, 20, accuracy: 0.001)
    }

    func testSuccessRate() {
        let targetId = UUID()

        sut.add(result: PingResult.success(targetId: targetId, latency: 0.01))
        sut.add(result: PingResult.success(targetId: targetId, latency: 0.01))
        sut.add(result: PingResult.failure(targetId: targetId, error: "Error"))
        sut.add(result: PingResult.success(targetId: targetId, latency: 0.01))

        let rate = sut.successRate(for: targetId)
        XCTAssertNotNil(rate)
        XCTAssertEqual(rate!, 0.75, accuracy: 0.001)
    }

    func testEmptyHistory() {
        let targetId = UUID()

        XCTAssertTrue(sut.history(for: targetId).isEmpty)
        XCTAssertNil(sut.latest(for: targetId))
        XCTAssertNil(sut.averageLatency(for: targetId))
        XCTAssertNil(sut.successRate(for: targetId))
    }
}
