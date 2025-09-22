// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

final class TopSitesScreen {
    private let app: XCUIApplication
    private let sel: TopSitesSelectorsSet

    init(app: XCUIApplication, selectors: TopSitesSelectorsSet = TopSitesSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var collectionView: XCUIElement { sel.COLLECTION_VIEW.element(in: app) }
    private var itemCellId: String { sel.TOP_SITE_ITEM_CELL.value }
    private var topSiteCellGroup: XCUIElement { sel.TOP_SITE_ITEM_CELL.element(in: app) }

    func assertVisible(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(app.links[itemCellId], timeout: timeout)
    }

    func assertTopSitesCount(_ expected: Int,
                             timeout: TimeInterval = TIMEOUT,
                             file: StaticString = #filePath, line: UInt = #line) {
        // Wait at least one link is available with the id
        BaseTestCase().mozWaitForElementToExist(app.links[itemCellId], timeout: timeout)

        // Count all the links inside the collectionView with that id
        let query = app.collectionViews.links.matching(identifier: itemCellId)

        // Ensure the first one exists
        BaseTestCase().mozWaitForElementToExist(query.firstMatch, timeout: timeout)

        // Compare with the total
        XCTAssertEqual(query.count, expected, "The number of Top Sites is not correct", file: file, line: line)
    }

    func assertDefaultTopSites(timeout: TimeInterval = TIMEOUT) {
        let names = ["X", "Amazon", "Wikipedia", "YouTube", "Facebook"]
        for name in names {
            // Search a link with the label = `name`
            let pred = NSPredicate(format: "label == %@", name)
            let link = collectionView.links.matching(pred).firstMatch
            BaseTestCase().mozWaitForElementToExist(link, timeout: timeout)
        }
    }

    func longPressOnSite(named name: String, duration: TimeInterval = 1.0) {
        let pred = NSPredicate(format: "label == %@", name)
        let site = collectionView.links.matching(pred).firstMatch
        BaseTestCase().mozWaitForElementToExist(site)
        site.press(forDuration: duration)
    }

    func assertVisibleTopSites(timeout: TimeInterval = TIMEOUT_LONG) {
        BaseTestCase().mozWaitForElementToExist(topSiteCellGroup, timeout: timeout)
    }

    func assertNotVisibleTopSites(timeout: TimeInterval = TIMEOUT_LONG) {
        BaseTestCase().mozWaitForElementToNotExist(topSiteCellGroup, timeout: timeout)
    }

    func isHittable() -> Bool {
        return app.links[itemCellId].isHittable
    }

    func assertNotHittable() {
        XCTAssertFalse(
            app.links[itemCellId].isHittable,
            "TopSites should not be visible or interactable on the current screen"
        )
    }
}
