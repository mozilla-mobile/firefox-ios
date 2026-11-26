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
    /// screen faded in behind the sheet has a "Close" button too. Nil if none is above the title.
    private var optInSheetCloseButton: XCUIElement? {
        return sel.CLOSE_BUTTON.query(in: app).allElementsBoundByIndex
            .filter { $0.isAbove(element: optInSheetTitle) }
            .max { $0.frame.minY < $1.frame.minY }
    }

    init(app: XCUIApplication, selectors: QuickAnswersSelectorsSet = QuickAnswersSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func assertOptInSheetShown(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(optInSheetTitle, timeout: timeout)
        XCTAssertTrue(optInSheetTitle.waitForFrameToSettle(), "The Quick Answers opt-in sheet kept moving")
        XCTAssertNotNil(optInSheetCloseButton, "The Quick Answers opt-in sheet has no \"Close\" button above its title")
    }

    /// Fails rather than tapping another "Close", whose X would also end the flow and hide a wrong tap.
    func closeOptInSheet() {
        guard let closeButton = optInSheetCloseButton else {
            XCTFail("The Quick Answers opt-in sheet has no \"Close\" button above its title")
            return
        }
        closeButton.waitAndTap()
    }

    func assertOptInSheetDismissed(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(optInSheetTitle, timeout: timeout)
    }
}
