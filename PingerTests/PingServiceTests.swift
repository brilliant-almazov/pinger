import XCTest
import Combine
@testable import Pinger

final class PingServiceTests: XCTestCase {
    var sut: PingService!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        sut = PingService()
        cancellables = []
    }

    override func tearDown() {
        sut.stop()
        sut = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - Integration Tests (require network)

    func testPingGoogleDNS() async {
        let target = PingTarget.googleDNS
        let result = await sut.ping(target: target)

        XCTAssertTrue(result.isSuccess, "Google DNS should be reachable")
        XCTAssertNotNil(result.latency, "Should have latency value")
        XCTAssertNil(result.error)
    }

    func testPingCloudflareDNS() async {
        let target = PingTarget.cloudflareDNS
        let result = await sut.ping(target: target)

        XCTAssertTrue(result.isSuccess, "Cloudflare DNS should be reachable")
        XCTAssertNotNil(result.latency)
    }

    func testPingUnreachableHost() async {
        let target = PingTarget(host: "192.0.2.1", name: "Unreachable")
        let result = await sut.ping(target: target)

        XCTAssertFalse(result.isSuccess, "Should fail for unreachable host")
        XCTAssertNotNil(result.error)
    }

    func testContinuousPing() {
        let expectation = XCTestExpectation(description: "Receive ping results")
        let target = PingTarget.googleDNS

        var receivedResults: [[PingResult]] = []

        sut.startContinuousPing(targets: [target], interval: 1.0)
            .sink { results in
                receivedResults.append(results)
                if receivedResults.count >= 2 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 5.0)

        XCTAssertGreaterThanOrEqual(receivedResults.count, 2)
        XCTAssertTrue(receivedResults.allSatisfy { !$0.isEmpty })
    }

    func testStopContinuousPing() {
        let target = PingTarget.googleDNS
        var resultCount = 0

        sut.startContinuousPing(targets: [target], interval: 0.5)
            .sink { _ in
                resultCount += 1
            }
            .store(in: &cancellables)

        // Wait for first result
        let expectation = XCTestExpectation(description: "Receive first result")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)

        // Stop and verify no more results
        sut.stop()
        let countAfterStop = resultCount

        let waitExpectation = XCTestExpectation(description: "Wait after stop")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            waitExpectation.fulfill()
        }
        wait(for: [waitExpectation], timeout: 3.0)

        // Allow at most 2 additional results that were in-flight when stop was called
        XCTAssertLessThanOrEqual(resultCount - countAfterStop, 2, "Should not receive many results after stop")
    }

    func testDisabledTargetsNotPinged() {
        let expectation = XCTestExpectation(description: "Receive ping results")

        let enabledTarget = PingTarget(host: "8.8.8.8", name: "Enabled", isEnabled: true)
        let disabledTarget = PingTarget(host: "1.1.1.1", name: "Disabled", isEnabled: false)

        var receivedResults: [PingResult] = []

        sut.startContinuousPing(targets: [enabledTarget, disabledTarget], interval: 1.0)
            .sink { results in
                receivedResults = results
                expectation.fulfill()
            }
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 3.0)

        XCTAssertEqual(receivedResults.count, 1, "Only enabled target should be pinged")
        XCTAssertEqual(receivedResults.first?.targetId, enabledTarget.id)
    }
}
