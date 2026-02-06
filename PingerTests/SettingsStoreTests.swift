import XCTest
@testable import Pinger

final class SettingsStoreTests: XCTestCase {
    var sut: SettingsStore!
    var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "TestDefaults")!
        testDefaults.removePersistentDomain(forName: "TestDefaults")
        sut = SettingsStore(defaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "TestDefaults")
        testDefaults = nil
        sut = nil
        super.tearDown()
    }

    // MARK: - Default Values

    func testDefaultTargets() {
        XCTAssertEqual(sut.targets.count, 3)
        XCTAssertEqual(sut.targets[0].host, "8.8.8.8")
        XCTAssertEqual(sut.targets[1].host, "1.1.1.1")
    }

    func testDefaultPingInterval() {
        XCTAssertEqual(sut.pingInterval, 1.0)
    }

    func testDefaultBadPingThreshold() {
        XCTAssertEqual(sut.badPingThreshold, 100)
    }

    func testDefaultIsPaused() {
        XCTAssertFalse(sut.isPaused)
    }

    func testDefaultNotificationsEnabled() {
        XCTAssertTrue(sut.notificationsEnabled)
    }

    // MARK: - Persistence

    func testPingIntervalPersistence() {
        sut.pingInterval = 2.5

        let newStore = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(newStore.pingInterval, 2.5)
    }

    func testTargetsPersistence() {
        let newTarget = PingTarget(host: "9.9.9.9", name: "Quad9")
        sut.addTarget(newTarget)

        let newStore = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(newStore.targets.count, 4)
        XCTAssertEqual(newStore.targets.last?.host, "9.9.9.9")
    }

    func testBadPingThresholdPersistence() {
        sut.badPingThreshold = 150

        let newStore = SettingsStore(defaults: testDefaults)
        XCTAssertEqual(newStore.badPingThreshold, 150)
    }

    func testIsPausedPersistence() {
        sut.isPaused = true

        let newStore = SettingsStore(defaults: testDefaults)
        XCTAssertTrue(newStore.isPaused)
    }

    // MARK: - Target Management

    func testAddTarget() {
        let target = PingTarget(host: "9.9.9.9", name: "Quad9")
        sut.addTarget(target)

        XCTAssertEqual(sut.targets.count, 4)
        XCTAssertEqual(sut.targets.last?.host, "9.9.9.9")
    }

    func testRemoveTargetAtIndex() {
        sut.removeTarget(at: 0)

        XCTAssertEqual(sut.targets.count, 2)
        XCTAssertEqual(sut.targets[0].host, "1.1.1.1")
    }

    func testRemoveTargetById() {
        let targetId = sut.targets[1].id
        sut.removeTarget(id: targetId)

        XCTAssertEqual(sut.targets.count, 2)
        XCTAssertNil(sut.targets.first { $0.id == targetId })
    }

    func testUpdateTarget() {
        var target = sut.targets[0]
        target.name = "Updated Name"
        sut.updateTarget(target)

        XCTAssertEqual(sut.targets[0].name, "Updated Name")
    }

    func testToggleTarget() {
        let targetId = sut.targets[0].id
        let wasEnabled = sut.targets[0].isEnabled

        sut.toggleTarget(id: targetId)

        XCTAssertEqual(sut.targets[0].isEnabled, !wasEnabled)
    }

    func testEnabledTargets() {
        // By default: Google and Cloudflare enabled, OpenDNS disabled
        XCTAssertEqual(sut.enabledTargets.count, 2)
    }

    // MARK: - Reset

    func testResetToDefaults() {
        sut.pingInterval = 5.0
        sut.badPingThreshold = 200
        sut.isPaused = true
        sut.addTarget(PingTarget(host: "9.9.9.9", name: "Quad9"))

        sut.resetToDefaults()

        XCTAssertEqual(sut.pingInterval, 1.0)
        XCTAssertEqual(sut.badPingThreshold, 100)
        XCTAssertFalse(sut.isPaused)
        XCTAssertEqual(sut.targets.count, 3)
    }

    // MARK: - Edge Cases

    func testRemoveInvalidIndex() {
        sut.removeTarget(at: 100)
        XCTAssertEqual(sut.targets.count, 3)
    }

    func testRemoveInvalidId() {
        sut.removeTarget(id: UUID())
        XCTAssertEqual(sut.targets.count, 3)
    }

    func testUpdateNonExistentTarget() {
        let target = PingTarget(host: "9.9.9.9", name: "Quad9")
        sut.updateTarget(target)
        XCTAssertEqual(sut.targets.count, 3)
    }

    func testToggleNonExistentTarget() {
        sut.toggleTarget(id: UUID())
        // Should not crash
        XCTAssertEqual(sut.targets.count, 3)
    }
}
