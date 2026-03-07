// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class WebsiteDataScreen {
    private let app: XCUIApplication
    private let sel: WebsiteDataSelectorsSet

    init(app: XCUIApplication, selectors: WebsiteDataSelectorsSet = WebsiteDataSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func clearAllWebsiteData() {
        BaseTestCase().mozWaitForElementToExist(sel.TABLE_WEBSITE_DATA.element(in: app))
        // Use longer timeout for parallel execution - activity indicator may take longer
        BaseTestCase().mozWaitForElementToNotExist(app.activityIndicators.firstMatch, timeout: TIMEOUT_LONG)

        let clearAll = sel.clearAllLabel(in: app)
        BaseTestCase().mozWaitForElementToExist(clearAll)
        clearAll.waitAndTap()

        let okButton = sel.ALERT_OK_BUTTON.element(in: app)
        okButton.waitAndTap()
        BaseTestCase().mozWaitForElementToNotExist(okButton)

        XCTAssertEqual(app.cells.buttons.images.count, 0, "The Website data has not cleared correctly")

        // Add wait for back button to be enabled
        let backButton = sel.BUTTON_DATA_MANAGEMENT.element(in: app)
        BaseTestCase().mozWaitElementEnabled(element: backButton, timeout: TIMEOUT)
        backButton.waitAndTap()
        sel.BUTTON_SETTINGS.element(in: app).waitAndTap()
        sel.BUTTON_DONE.element(in: app).waitAndTap()
    }

    func assertAllWebsiteDataCleared() {
        XCTAssertEqual(app.cells.buttons.images.count, 0, "The Website data has not cleared correctly")
    }

    func navigateBackToBrowser() {
        Selector.buttonByLabel("Data Management", description: "Back").element(in: app).waitAndTap()
        Selector.buttonByLabel("Settings", description: "Back").element(in: app).waitAndTap()
        Selector.buttonByLabel("Done", description: "Done").element(in: app).waitAndTap()
    }

    func waitUntilListIsReady(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.TABLE_WEBSITE_DATA.element(in: app), timeout: timeout)

        // Wait for activity indicator to disappear before checking for data
        // Use longer timeout when running in parallel as iOS takes longer to persist website data
        BaseTestCase().mozWaitForElementToNotExist(app.activityIndicators.firstMatch, timeout: TIMEOUT_LONG)

        if #available(iOS 17, *) {
            let circleInCells = sel.circleImageInsideCells(app)
            BaseTestCase().mozWaitForElementToExist(circleInCells, timeout: timeout)
        } else {
            let anyBtn = sel.anyTableButton(app)
            BaseTestCase().mozWaitForElementToExist(anyBtn, timeout: timeout)
        }
    }

    /// Checks if website data has loaded without failing the test
    /// Returns true if data is loaded, false otherwise
    func checkIfDataLoaded(timeout: TimeInterval = TIMEOUT) -> Bool {
        // Wait for table to exist
        guard sel.TABLE_WEBSITE_DATA.element(in: app).waitForExistence(timeout: timeout) else {
            return false
        }

        // Wait for activity indicator to disappear
        BaseTestCase().mozWaitForElementToNotExist(app.activityIndicators.firstMatch, timeout: TIMEOUT_LONG)

        // Check if data cells exist
        if #available(iOS 17, *) {
            let circleInCells = sel.circleImageInsideCells(app)
            return circleInCells.waitForExistence(timeout: timeout)
        } else {
            let anyBtn = sel.anyTableButton(app)
            return anyBtn.waitForExistence(timeout: timeout)
        }
    }

    func expandShowMoreIfNeeded() {
        let showMore = sel.CELL_SHOW_MORE.element(in: app)
        if showMore.exists {
            showMore.waitAndTap()
        }
    }

    func waitForExampleDomain(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.EXAMPLE_EQUAL.element(in: app), timeout: timeout)
    }

    func assertWebsiteDataVisible(timeout: TimeInterval = TIMEOUT) {
        if #available(iOS 17, *) {
            let circle = sel.circleImageInsideCells(app)
            BaseTestCase().mozWaitForElementToExist(circle, timeout: timeout)
            XCTAssertTrue(circle.exists, "Expected circle image inside cells")
        } else {
            let exampleText = sel.STATIC_TEXT_EXAMPLE_IN_CELL.element(in: app)
            BaseTestCase().mozWaitForElementToExist(exampleText, timeout: timeout)
            XCTAssertTrue(exampleText.exists, "Expected a staticText 'example.com' inside a cell")
        }
    }
}
