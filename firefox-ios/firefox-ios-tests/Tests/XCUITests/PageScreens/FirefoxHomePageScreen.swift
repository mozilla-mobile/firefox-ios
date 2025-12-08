// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

@MainActor
final class FirefoxHomePageScreen {
    private let app: XCUIApplication
    private let sel: FirefoxHomePageSelectorsSet

    init(app: XCUIApplication, selectors: FirefoxHomePageSelectorsSet = FirefoxHomePageSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var customizeHomepage: XCUIElement { sel.CUSTOMIZE_HOMEPAGE.element(in: app) }

    func assertTopSitesItemCellExist(timeout: TimeInterval = TIMEOUT) {
        let topSites_ItemCell = sel.TOPSITES_ITEMCELL.element(in: app)

        BaseTestCase().mozWaitForElementToExist(topSites_ItemCell, timeout: timeout)
    }

    func assertBookmarksItemCellToNotExist(timeout: TimeInterval = TIMEOUT) {
        let bookmarks_ItemCell = sel.BOOKMARKS_ITEMCELL.element(in: app)
        BaseTestCase().mozWaitForElementToNotExist(bookmarks_ItemCell, timeout: timeout)
    }

    func assertBookmarksItemCellExist(timeout: TimeInterval = TIMEOUT) {
        let bookmarks_ItemCell = sel.BOOKMARKS_ITEMCELL.element(in: app)
        BaseTestCase().mozWaitForElementToExist(bookmarks_ItemCell, timeout: timeout)
    }

    func tapOnCustomizeHomePageOption(timeout: TimeInterval = TIMEOUT) {
        customizeHomepage.waitAndTap()
    }

    func assertCustomizeHomePageOptionExists(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(customizeHomepage)
    }
}
