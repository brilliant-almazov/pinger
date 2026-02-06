import XCTest
@testable import Pinger

final class PingTargetTests: XCTestCase {

    func testDefaultTargets() {
        let defaults = PingTarget.defaults

        XCTAssertEqual(defaults.count, 3)
        XCTAssertEqual(defaults[0].host, "8.8.8.8")
        XCTAssertEqual(defaults[1].host, "1.1.1.1")
        XCTAssertEqual(defaults[2].host, "208.67.222.222")
    }

    func testTargetEquality() {
        let id = UUID()
        let target1 = PingTarget(id: id, host: "8.8.8.8", name: "Test")
        let target2 = PingTarget(id: id, host: "8.8.8.8", name: "Test")

        XCTAssertEqual(target1, target2)
    }

    func testTargetCodable() throws {
        let target = PingTarget.googleDNS
        let data = try JSONEncoder().encode(target)
        let decoded = try JSONDecoder().decode(PingTarget.self, from: data)

        XCTAssertEqual(target.host, decoded.host)
        XCTAssertEqual(target.name, decoded.name)
        XCTAssertEqual(target.isEnabled, decoded.isEnabled)
    }
}

final class PingResultTests: XCTestCase {

    func testSuccessResult() {
        let targetId = UUID()
        let result = PingResult.success(targetId: targetId, latency: 0.012)

        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(result.latencyMs, 12)
        XCTAssertNil(result.error)
    }

    func testFailureResult() {
        let targetId = UUID()
        let result = PingResult.failure(targetId: targetId, error: "Timeout")

        XCTAssertFalse(result.isSuccess)
        XCTAssertNil(result.latency)
        XCTAssertEqual(result.error, "Timeout")
    }

    func testLatencyMilliseconds() {
        let targetId = UUID()
        let result = PingResult.success(targetId: targetId, latency: 0.123)

        XCTAssertEqual(result.latencyMs, 123)
    }

    func testLatencyNilForFailure() {
        let targetId = UUID()
        let result = PingResult.failure(targetId: targetId, error: "Error")

        XCTAssertNil(result.latencyMs)
    }
}
