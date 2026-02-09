// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@MainActor
final class HistoryScreen {
    private let app: XCUIApplication
    private let sel: HistorySelectorsSet

    init(app: XCUIApplication, selectors: HistorySelectorsSet = HistorySelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var historyEntryExample: XCUIElement { sel.HISTORY_ENTRY_EXAMPLE.element(in: app) }

    func waitForExampleEntry() {
        BaseTestCase().mozWaitForElementToExist(historyEntryExample)
    }

    func swipeLeftOnExampleEntry() {
        BaseTestCase().mozWaitForElementToExist(historyEntryExample)
        historyEntryExample.firstMatch.swipeLeft()
    }

    func tapDeleteButton() {
        let delete = sel.DELETE_BUTTON.element(in: app)
        BaseTestCase().mozWaitForElementToExist(delete)
        delete.waitAndTap()
    }

    func assertExampleEntryRemoved() {
        BaseTestCase().mozWaitForElementToNotExist(historyEntryExample)
    }

    func assertEmptyMessageVisible() {
        BaseTestCase().mozWaitForElementToExist(sel.EMPTY_RECENTLY_CLOSED_MSG.element(in: app))
    }

    func tapOnClearRecentHistoryOption(optionSelected: String) {
        app.buttons[optionSelected].waitAndTap()
    }

    func waitForHistoryEntries(_ entries: [String]) {
        for entry in entries {
            let element = app.tables.cells.staticTexts
                .containing(NSPredicate(format: "label CONTAINS[c] %@", entry))
                .firstMatch
            BaseTestCase().mozWaitForElementToExist(element)
        }
    }

    func waitForHistoryEntriesNotExist(_ entries: [String]) {
        for entry in entries {
            let element = app.tables.cells.staticTexts[entry]
            BaseTestCase().mozWaitForElementToNotExist(element)
        }
    }

    func waitForStaticText(_ label: String, shouldExist: Bool, timeout: TimeInterval = TIMEOUT) {
        let element = app.staticTexts[label]
        if shouldExist {
            BaseTestCase().mozWaitForElementToExist(element, timeout: timeout)
        } else {
            BaseTestCase().mozWaitForElementToNotExist(element, timeout: timeout)
        }
    }
}
