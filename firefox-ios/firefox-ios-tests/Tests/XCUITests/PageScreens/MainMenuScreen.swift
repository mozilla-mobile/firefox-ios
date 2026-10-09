// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class MainMenuScreen {
    private let app: XCUIApplication
    private let sel: MainMenuSelectorSet

    init(app: XCUIApplication, selectors: MainMenuSelectorSet = MainMenuSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertDesktopSiteExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.DESKTOP_SITE.element(in: app), timeout: timeout)
    }

    func waitForMenuOptionsToExist() {
        let elements = [
            sel.BOOKMARKS_BUTTON.element(in: app),
            sel.HISTORY_BUTTON.element(in: app),
            sel.DOWNLOADS_BUTTON.element(in: app),
            sel.PASSWORDS_BUTTON.element(in: app),
            sel.SETTINGS_CELL.element(in: app)
        ]
        BaseTestCase().waitForElementsToExist(elements)
    }

	func assertMenuOptionsExist() {
		let elements = [
			sel.SETTINGS_CELL.element(in: app),
			sel.BOOKMARKS_BUTTON.element(in: app),
			sel.HISTORY_BUTTON.element(in: app),
			sel.DOWNLOADS_BUTTON.element(in: app),
			sel.PASSWORDS_BUTTON.element(in: app),
			sel.SIGN_IN_CELL.element(in: app)
		]
		BaseTestCase().waitForElementsToExist(elements)
	}

	func dismissMenu() {
		app.otherElements["PopoverDismissRegion"].firstMatch.tap()
	}

    /// Unlike dismissMenu(), never lands on a menu row: below iOS 26 the dismiss region's center
    /// sits over the sheet.
    func closeMenu() {
        sel.CLOSE_BUTTON.element(in: app).waitAndTap()
        assertMenuIsDismissed()
    }

	func assertMenuIsDismissed(timeout: TimeInterval = TIMEOUT) {
		let settings = sel.SETTINGS_CELL.element(in: app)
		BaseTestCase().mozWaitForElementToNotExist(settings, timeout: timeout)
	}

    func assertMainMenuSettingsExist() {
        let settings = sel.SETTINGS_CELL.element(in: app)
        BaseTestCase().mozWaitForElementToExist(settings)
    }

    func tapSettings() {
        let settings = sel.SETTINGS_CELL.element(in: app)
        BaseTestCase().mozWaitForElementToExist(settings)
        settings.waitAndTap()
    }

    func tapBookmarks() {
        let bookmarks = sel.BOOKMARKS_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(bookmarks)
        bookmarks.waitAndTap()
    }

    func tapBookmarkPage() {
        let bookmarkPage = sel.BOOKMARK_PAGE.element(in: app)
        BaseTestCase().mozWaitForElementToExist(bookmarkPage)
        bookmarkPage.waitAndTap()
    }

    func tapSiteProtections() {
        sel.SITE_PROTECTIONS.element(in: app).waitAndTap()
    }

    func tapHistory() {
        let history = sel.HISTORY_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(history)
        history.waitAndTap()
    }

    func assertReaderViewIsBelowPageZoom() {
        assertMenuItem(sel.READER_VIEW, isBelow: sel.PAGE_ZOOM)
    }

    func assertSummarizePageIsBelowFindInPage(timeout: TimeInterval = TIMEOUT) {
        assertMenuItem(sel.SUMMARIZE_PAGE, isBelow: sel.FIND_IN_PAGE, timeout: timeout)
    }

    private func assertMenuItem(_ item: Selector, isBelow reference: Selector, timeout: TimeInterval = TIMEOUT) {
        let itemElement = item.element(in: app)
        let referenceElement = reference.element(in: app)
        BaseTestCase().waitForElementsToExist([referenceElement, itemElement], timeout: timeout)
        XCTAssertGreaterThanOrEqual(
            itemElement.frame.minY,
            referenceElement.frame.maxY,
            "\(item.description) should be displayed below \(reference.description)"
        )
    }

    func assertReaderViewIs(on isOn: Bool, timeout: TimeInterval = TIMEOUT) {
        let readerView = sel.READER_VIEW.element(in: app)
        let status = isOn ? sel.READER_VIEW_STATUS_ON : sel.READER_VIEW_STATUS_OFF
        BaseTestCase().mozWaitForElementToExist(readerView, timeout: timeout)
        BaseTestCase().mozWaitForElementToExist(readerView.staticTexts[status.value], timeout: timeout)
    }

    func tapReaderView() {
        sel.READER_VIEW.element(in: app).waitAndTap()
    }

    func assertTranslatePageItemDoesNotExist() {
        assertMenuItemDoesNotExist(AccessibilityIdentifiers.MainMenu.translatePage)
    }

    func assertSummarizePageItemDoesNotExist() {
        assertMenuItemDoesNotExist(AccessibilityIdentifiers.MainMenu.summarizePage)
    }

    private func assertMenuItemDoesNotExist(_ identifier: String) {
        // Wait for a stable Main Menu element to render first, otherwise the absence
        // check can pass simply because the menu hasn't finished loading yet.
        BaseTestCase().mozWaitForElementToExist(sel.SETTINGS_CELL.element(in: app))
        let item = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
        BaseTestCase().mozWaitForElementToNotExist(item)
    }
}
