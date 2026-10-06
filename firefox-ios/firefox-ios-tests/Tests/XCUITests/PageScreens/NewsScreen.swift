// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class NewsScreen {
    /// Absence checks run once the homepage settled, so a short first probe is enough.
    static let absenceTimeout: TimeInterval = 3
    /// Grace period for the probes between swipes.
    static let absenceProbeTimeout: TimeInterval = 2

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

    /// Swipes while looking for the section, so one below the fold is not read as issue #35618.
    /// Returns whether the section is really absent.
    /// https://github.com/mozilla-mobile/firefox-ios/issues/35618
    @discardableResult
    func assertNewsSectionIsAbsent(maxSwipes: Int = 2, timeout: TimeInterval = NewsScreen.absenceTimeout) -> Bool {
        let newsSection = sel.NEWS_SECTION.element(in: app)
        var found = newsSection.mozWaitForElementToExist(timeout: timeout, failOnTimeout: false)
        var swipes = maxSwipes
        while !found && swipes > 0 {
            app.partialSwipeUp(distance: 0.2)
            swipes -= 1
            found = newsSection.mozWaitForElementToExist(timeout: NewsScreen.absenceProbeTimeout, failOnTimeout: false)
        }
        XCTAssertFalse(
            found,
            "News section rendered below iOS 17. Issue #35618 looks fixed, remove the version guard."
        )
        return !found
    }

    @discardableResult
    func assertNoStoryCellsExist(timeout: TimeInterval = NewsScreen.absenceProbeTimeout) -> Bool {
        let firstStoryCell = sel.FIRST_STORY_CELL.element(in: app).firstMatch
        let found = firstStoryCell.mozWaitForElementToExist(timeout: timeout, failOnTimeout: false)
        XCTAssertFalse(
            found,
            "Story cells rendered below iOS 17. Issue #35618 looks fixed, remove the version guard."
        )
        return !found
    }

    @discardableResult
    func assertNoCategoryButtonsExist(timeout: TimeInterval = NewsScreen.absenceProbeTimeout) -> Bool {
        let allCategoryButton = sel.ALL_CATEGORY_BUTTON.element(in: app)
        let found = allCategoryButton.mozWaitForElementToExist(timeout: timeout, failOnTimeout: false)
        XCTAssertFalse(
            found,
            "Story categories rendered below iOS 17. Issue #35618 looks fixed, remove the version guard."
        )
        let categoryCount = sel.CATEGORY_BUTTONS.query(in: app).count
        XCTAssertEqual(
            categoryCount,
            0,
            "Story categories rendered below iOS 17. Issue #35618 looks fixed, remove the version guard."
        )
        return !found && categoryCount == 0
    }
}
