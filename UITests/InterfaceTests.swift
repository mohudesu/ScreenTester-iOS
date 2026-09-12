import XCTest

final class InterfaceTests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<6 {
            if element.isHittable { return }
            app.scrollViews["page.scroll"].swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }
    func testHomeSettingsAndFullscreenReturn() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 15))
        capture("01-Home", app: app)
        app.buttons["home.settings"].tap()
        let slider = app.sliders["settings.width"]
        XCTAssertTrue(slider.waitForExistence(timeout: 5))
        reveal(slider, in: app)
        slider.adjust(toNormalizedSliderPosition: 0.6)
        let savedWidth = app.staticTexts["settings.widthValue"].label
        capture("02-Settings", app: app)
        app.terminate()
        app.launch()
        app.buttons["home.settings"].tap()
        XCTAssertTrue(app.sliders["settings.width"].waitForExistence(timeout: 5))
        reveal(app.sliders["settings.width"], in: app)
        XCTAssertEqual(app.staticTexts["settings.widthValue"].label, savedWidth)
        app.navigationBars.buttons.firstMatch.tap()
        let border = app.buttons["test.border"]
        XCTAssertTrue(border.waitForExistence(timeout: 5))
        border.tap()
        XCTAssertTrue(app.staticTexts["test.border.deviceTitle"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["test.border.deviceTitle"].label.hasSuffix(" 黑边测试"))
        XCTAssertFalse(app.buttons["home.settings"].isHittable)
        capture("03-Fullscreen", app: app)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 2.3)
        XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["home.settings"].isHittable)
    }
    func testManualDarkModePersistsAcrossLaunchAndStyles() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 15))
        app.buttons["home.settings"].tap()
        for style in ["neumorphic", "liquidGlass"] {
            app.buttons["settings.style.\(style)"].tap()
            let picker = app.segmentedControls["settings.appearance"]
            reveal(picker, in: app)
            picker.buttons["深色"].tap()
            XCTAssertEqual(app.staticTexts["settings.appearanceValue"].label, "当前外观：深色")
            capture("Manual-Dark-\(style)", app: app)
            app.terminate()
            app.launch()
            XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 15))
            app.buttons["home.settings"].tap()
            XCTAssertTrue(app.segmentedControls["settings.appearance"].buttons["深色"].isSelected)
            XCTAssertEqual(app.staticTexts["settings.appearanceValue"].label, "当前外观：深色")
        }
        app.segmentedControls["settings.appearance"].buttons["浅色"].tap()
        XCTAssertEqual(app.staticTexts["settings.appearanceValue"].label, "当前外观：浅色")
        app.segmentedControls["settings.appearance"].buttons["跟随系统"].tap()
        XCTAssertTrue(app.segmentedControls["settings.appearance"].buttons["跟随系统"].isSelected)
    }
    func testStyleSwitchPersistsAndPreservesTestSettings() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 15))
        app.buttons["home.settings"].tap()
        let width = app.sliders["settings.width"]
        XCTAssertTrue(width.waitForExistence(timeout: 5))
        reveal(width, in: app)
        width.adjust(toNormalizedSliderPosition: 0.8)
        let colors = app.segmentedControls["settings.colors"]
        reveal(colors, in: app)
        colors.buttons["红"].tap()
        let ppi = app.sliders["settings.ppi"]
        reveal(ppi, in: app)
        ppi.adjust(toNormalizedSliderPosition: 0.7)
        let originalWidth = app.staticTexts["settings.widthValue"].label
        let originalPPI = app.staticTexts["settings.ppiValue"].label
        let originalColor = app.segmentedControls["settings.colors"].buttons.matching(NSPredicate(format: "selected == true")).firstMatch.label
        let originalBrightness = app.switches["settings.brightness"].value as? String
        for _ in 0..<6 {
            if app.buttons["settings.style.liquidGlass"].isHittable { break }
            app.scrollViews["page.scroll"].swipeDown()
        }

        for (index, style) in ["liquidGlass", "neumorphic"].enumerated() {
            let choice = app.buttons["settings.style.\(style)"]
            XCTAssertTrue(choice.waitForExistence(timeout: 5))
            choice.tap()
            XCTAssertTrue(app.buttons["settings.style.\(style)"].isSelected)
            XCTAssertEqual(app.staticTexts["settings.widthValue"].label, originalWidth)
            XCTAssertEqual(app.staticTexts["settings.ppiValue"].label, originalPPI)
            XCTAssertEqual(app.segmentedControls["settings.colors"].buttons.matching(NSPredicate(format: "selected == true")).firstMatch.label, originalColor)
            XCTAssertEqual(app.switches["settings.brightness"].value as? String, originalBrightness)
            capture("Style-\(index)-Settings", app: app)

            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 5))
            XCTAssertEqual(app.buttons["home.settings"].value as? String, style == "liquidGlass" ? "Liquid Glass" : "新拟态")
            capture("Style-\(index)-Home", app: app)
            app.buttons["test.border"].tap()
            XCTAssertTrue(app.staticTexts["test.border.deviceTitle"].waitForExistence(timeout: 10))
            let homeHidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == false"), object: app.buttons["home.settings"])
            XCTAssertEqual(XCTWaiter.wait(for: [homeHidden], timeout: 5), .completed)
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(forDuration: 2.3)
            XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 5))

            app.terminate()
            app.launch()
            XCTAssertTrue(app.buttons["home.settings"].waitForExistence(timeout: 15))
            app.buttons["home.settings"].tap()
            XCTAssertTrue(app.buttons["settings.style.\(style)"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["settings.style.\(style)"].isSelected)
            XCTAssertEqual(app.staticTexts["settings.widthValue"].label, originalWidth)
            XCTAssertEqual(app.staticTexts["settings.ppiValue"].label, originalPPI)
        }
    }
}
