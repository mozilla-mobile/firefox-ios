// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class NewsScreen {
    private let app: XCUIApplication
    private let sel: NewsSelectorsSet

    init(app: XCUIApplication, selectors: NewsSelectorsSet = NewsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    func scrollToNewsSection() {
        app.partialSwipeUp(distance: 0.2)
    }

    func assertNewsSectionExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.NEWS_SECTION.element(in: app), timeout: timeout)
    }

    func assertAllCategoryButtonExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.ALL_CATEGORY_BUTTON.element(in: app), timeout: timeout)
    }

    func assertCategoryCount(minimum: Int) {
        let categoryButtons = sel.CATEGORY_BUTTONS.query(in: app)
        XCTAssertGreaterThanOrEqual(
            categoryButtons.count,
            minimum,
            "Expected at least \(minimum) story category buttons."
        )
    }

    func tapCategoryButton(at index: Int) {
        sel.CATEGORY_BUTTONS.query(in: app).element(boundBy: index).waitAndTap()
    }

    func tapAllCategoryButton() {
        sel.ALL_CATEGORY_BUTTON.element(in: app).waitAndTap()
    }

    func assertFirstStoryCellExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(sel.FIRST_STORY_CELL.element(in: app).firstMatch, timeout: timeout)
    }
}
