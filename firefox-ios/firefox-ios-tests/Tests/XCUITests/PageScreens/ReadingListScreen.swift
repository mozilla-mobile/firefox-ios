// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class ReadingListScreen {
    private let app: XCUIApplication
    private let sel: ReadingListSelectorsSet
    private let selZoom: ZoomBarSelectorsSet

    private var readerViewButton: XCUIElement { sel.READER_VIEW_BUTTON.element(in: app) }
    private var zoomingScreen: ZoomBarScreen!

    init(app: XCUIApplication,
         selectors: ReadingListSelectorsSet = ReadingListSelectors(),
         zoomSelectors: ZoomBarSelectorsSet = ZoomBarSelectors()) {
            self.app = app
            self.sel = selectors
            self.selZoom = zoomSelectors
    }

    // ACTIONS
    func tapOnReaderView() {
        BaseTestCase().mozWaitForElementToExist(readerViewButton)
        readerViewButton.tapOnApp()
        BaseTestCase().waitUntilPageLoad()
    }

    func tapOnDoneButton() {
        sel.DONE_BUTTON_READING_LIST.element(in: app).waitAndTap()
    }

    func checkReadingListNumberOfItems(items: Int) {
        BaseTestCase().mozWaitForElementToExist(sel.READING_TABLE.element(in: app))
        let list = sel.READING_TABLE.element(in: app).cells.count
        XCTAssertEqual(list, items, "The number of items in the reading table is not correct")
    }

    // Returns the element "The Book of Mozilla" inside the table
    func getSavedBookElement() -> XCUIElement {
        let table = sel.READING_TABLE.element(in: app)
        BaseTestCase().mozWaitForElementToExist(table)

        let savedBook = table.cells.staticTexts[selZoom.BOOK_OF_MOZILLA_TEXT.value]
        return savedBook
    }

    func openReaderModeSettings() {
        let settingsButton = sel.READERMODE_SETTINGS_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(settingsButton)
        settingsButton.waitAndTap()
    }

    func tapMarkAsUnread() {
        let markAsUnread = sel.MARK_AS_UNREAD_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(markAsUnread)
        markAsUnread.tap(force: true)
    }

    func tapRemoveArticle() {
        let removeButton = sel.REMOVE_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(removeButton)
        removeButton.tap(force: true)
    }

    // WAITS
    func waitForSavedBook() {
        let bookElement = getSavedBookElement()
        BaseTestCase().mozWaitForElementToExist(bookElement)
    }

    func waitForReadingListsPanel() {
        BaseTestCase().waitForElementsToExist(
            [sel.EMPTY_READING_LIST_1.element(in: app),
            sel.EMPTY_READING_LIST_2.element(in: app),
            sel.EMPTY_READING_LIST_3.element(in: app)]
        )
    }
    func waitForArticle(_ title: String) {
        let table = sel.READING_TABLE.element(in: app)
        BaseTestCase().mozWaitForElementToExist(table)

        let articleCell = table.cells.elementContainingText(title)
        BaseTestCase().mozWaitForElementToExist(articleCell)
    }

    // ASSERTS
    func assertFennecAlertNotExists() {
        BaseTestCase().mozWaitForElementToNotExist(sel.FENNEC_ALERT_TEXT.element(in: app))
    }

    func assertReaderListContentVisible() {
        let zoomingScreen = ZoomBarScreen(app: app)
        BaseTestCase().waitForElementsToExist([
            sel.DISPLAY_SETTINGS_BUTTON.element(in: app),
            zoomingScreen.returnBookTextElement()
        ])
    }

    func assertReaderModeOptionsVisible() {
        for selector in sel.LAYOUT_OPTIONS {
            let optionButton = selector.element(in: app)
            BaseTestCase().mozWaitForElementToExist(optionButton)
            XCTAssertTrue(optionButton.exists, "Option \(selector.value) doesn't exist")
        }
    }

    func assertReaderButtonExists() {
        BaseTestCase().mozWaitForElementToExist(readerViewButton)
    }

    func assertReaderButtonIsSelected() {
        XCTAssertTrue(readerViewButton.isSelected)
    }

    func assertReaderButtonIsEnabled() {
        XCTAssertTrue(readerViewButton.isEnabled)
    }

    func assertSwipeOptionsVisible() {
        BaseTestCase().waitForElementsToExist([
            sel.MARK_AS_UNREAD_BUTTON.element(in: app),
            sel.REMOVE_BUTTON.element(in: app)
        ])
    }
}
