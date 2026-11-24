// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

/// Page object for Quick Answers, opened from the voice wave button on Firefox Home.
/// On first use its opt-in is shown as a sheet over the Quick Answers screen.
@MainActor
final class QuickAnswersScreen {
    private let app: XCUIApplication
    private let sel: QuickAnswersSelectorsSet

    private var optInSheetTitle: XCUIElement { sel.OPT_IN_SHEET_TITLE.element(in: app) }

    /// The sheet's close button is the nearest "Close" above its title, since the Quick Answers
    /// screen faded in behind the sheet has a "Close" button too.
    private var optInSheetCloseButton: XCUIElement {
        let closeButtons = sel.CLOSE_BUTTON.query(in: app).allElementsBoundByIndex
        let sheetCloseButton = closeButtons
            .filter { $0.isAbove(element: optInSheetTitle) }
            .max { $0.frame.minY < $1.frame.minY }
        return sheetCloseButton ?? sel.CLOSE_BUTTON.element(in: app)
    }

    init(app: XCUIApplication, selectors: QuickAnswersSelectorsSet = QuickAnswersSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertOptInSheetShown(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(optInSheetTitle, timeout: timeout)
        XCTAssertTrue(optInSheetTitle.waitForFrameToSettle(), "The Quick Answers opt-in sheet kept moving")
        BaseTestCase().mozWaitForElementToExist(optInSheetCloseButton)
    }

    func closeOptInSheet() {
        optInSheetCloseButton.waitAndTap()
    }

    func assertOptInSheetDismissed(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(optInSheetTitle, timeout: timeout)
    }
}
