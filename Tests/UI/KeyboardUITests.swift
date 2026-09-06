// KeyboardUITests.swift — Keyboat
// XCUITest suite for basic keyboard interaction.

import XCTest

final class KeyboardUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testAppLaunchesSuccessfully() {
        XCTAssertTrue(app.state == .runningForeground)
    }

    func testSettingsTabExists() {
        XCTAssertTrue(app.tabBars.buttons["Settings"].exists)
    }

    func testThemesTabExists() {
        XCTAssertTrue(app.tabBars.buttons["Themes"].exists)
    }

    func testClipboardTabExists() {
        XCTAssertTrue(app.tabBars.buttons["Clipboard"].exists)
    }

    func testThemeStudioNavigationTitle() {
        app.tabBars.buttons["Themes"].tap()
        XCTAssertTrue(app.navigationBars.staticTexts["Theme Studio"].waitForExistence(timeout: 2))
    }
}
