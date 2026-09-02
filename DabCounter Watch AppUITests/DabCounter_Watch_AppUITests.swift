import XCTest

final class DabCounter_Watch_AppUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testStartResetAndTapToCount() throws {
        let app = XCUIApplication()
        app.launch()

        let startStop = app.buttons["start-stop"]
        let reset = app.buttons["reset"]
        XCTAssertTrue(startStop.waitForExistence(timeout: 5))
        XCTAssertTrue(reset.exists)
        XCTAssertTrue(app.staticTexts["DABS TODAY"].exists)

        startStop.tap()
        XCTAssertEqual(startStop.label, "Stop")

        startStop.tap()
        XCTAssertEqual(startStop.label, "Start")

        app.otherElements["dab-ring"].tap()

        reset.tap()
        XCTAssertTrue(app.staticTexts["dab-count"].waitForExistence(timeout: 2))
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
