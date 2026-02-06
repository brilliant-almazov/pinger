import XCTest

final class PingerUITests: XCTestCase {

    func testAppLaunches() throws {
        let app = XCUIApplication()
        app.launch()
        // Menu bar apps don't have traditional windows
        // UI tests will be expanded as we add features
    }
}
