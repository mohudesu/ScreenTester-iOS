import XCTest

final class InterfaceTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    func testHomeSettingsAndFullscreenReturn() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 15))
        capture("01-Home", app: app)
        app.buttons["home.settings"].tap()
        let slider = app.sliders["settings.width"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5))
        slider.adjust(toNormalizedSliderPosition: 0.6)
        let savedWidth = app.staticTexts["settings.widthValue"].label
        capture("02-Settings", app: app)
        app.terminate()
        app.launch()
        app.buttons["home.settings"].tap()
        XCTAssertTrue(app.sliders["settings.width"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["settings.widthValue"].label, savedWidth)
        app.navigationBars.buttons.firstMatch.tap()
        let border = app.buttons["test.border"]
        XCTAssertTrue(border.waitForExistence(timeout: 5))
        border.tap()
        XCTAssertFalse(app.buttons["home.settings"].isHittable)
        capture("03-Fullscreen", app: app)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 2.3)
        XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["home.settings"].isHittable)
    }
}
