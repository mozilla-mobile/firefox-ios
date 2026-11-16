// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/
import Shared
import XCTest

/// What the Tracker Blocker module shows: the pill, the weekly panel's counts, and how much of each category row
/// its bar's colour covers, or nil for a row that isn't fully on screen, as a bar off screen reads as empty.
struct TrackerBlockerValues {
    let pill: Int
    let weekly: Int
    let lifetime: Int
    let categories: [Int]
    let barFills: [Double?]
}

@MainActor
final class HomePageScreen {
    private let app: XCUIApplication
    private let sel: HomePageSelectorsSet
    private let topSitesSel: TopSitesSelectorsSet
    private let jumpBackInSel: JumpBackInSelectorsSet

    private var collection: XCUIElement { sel.COLLECTION_VIEW.element(in: app) }
    private var tabsButton: XCUIElement { sel.TABS_BUTTON.element(in: app) }
    private var homeLogo: XCUIElement { sel.HOME_LOGO.element(in: app) }
    private var privHomepageTitle: XCUIElement { sel.PRIVATE_HOME_TITLE.element(in: app) }
    private var trackerBlockerPill: XCUIElement { sel.TRACKER_BLOCKER_PILL.element(in: app) }

    init(
        app: XCUIApplication,
        selectors: HomePageSelectorsSet = HomePageSelectors(),
        topSitesSelectors: TopSitesSelectorsSet = TopSitesSelectors(),
        jumpBackInSelectors: JumpBackInSelectorsSet = JumpBackInSelectors()
    ) {
        self.app = app
        self.sel = selectors
        self.topSitesSel = topSitesSelectors
        self.jumpBackInSel = jumpBackInSelectors
    }

    func swipeToCustomizeHomeOption() {
        if UIDevice.current.userInterfaceIdiom != .pad {
            BaseTestCase().mozWaitForElementToExist(collection)
            collection.swipeUp()
            collection.swipeUp()
        }
    }

    func assertTabsButtonExists() {
        BaseTestCase().mozWaitForElementToExist(tabsButton)
    }

    func waitUntilTabsButtonHittable(timeout: TimeInterval = 2.0) {
        BaseTestCase().mozWaitElementHittable(element: tabsButton, timeout: timeout)
    }

    func assertHomepageIsDisplayed() {
        BaseTestCase().waitForElementsToExist([collection, homeLogo])
    }

    func assertHomeLogoExists() {
        BaseTestCase().mozWaitForElementToExist(homeLogo)
    }

    func assertPrivateHomeTitleExists() {
        BaseTestCase().mozWaitForElementToExist(privHomepageTitle)
    }

    func privateHomeTitleExists(timeout: TimeInterval = TIMEOUT) -> Bool {
        BaseTestCase().mozWaitForElementToExist(privHomepageTitle, timeout: timeout, failOnTimeout: false)
    }

    func validateHomeLogoPosition(isPrivate: Bool = false) {
        if !isPrivate {
            XCTAssertTrue(homeLogo.isAbove(
                element: topSitesSel.TOP_SITE_ITEM_CELL.element(in: app).firstMatch),
                          "Firefox Home logo should be above the top sites section")
        } else {
            XCTAssertTrue(homeLogo.isAbove(
                element: privHomepageTitle),
                          "Firefox Home logo should be above the home page title in private mode")
        }
    }

    func validateHomePageLogo(isPrivate: Bool) {
        assertHomeLogoExists()
        validateHomeLogoPosition(isPrivate: isPrivate)
    }

    func assertTrackerBlockerPillDoesNotExist(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToNotExist(trackerBlockerPill, timeout: timeout)
    }

    /// Reads the lifetime count from the pill label, e.g. "Trackers Blocked: 6". Fails when no count is shown.
    private func trackerBlockerCount(timeout: TimeInterval = TIMEOUT) -> Int {
        let prefix = String(format: .FirefoxHomepage.TrackerBlocker.TrackersBlockedTemp, "")
        return number(in: trackerBlockerPill, after: prefix, timeout: timeout)
    }

    /// Asserts the pill shows a count of at least `minimum` and returns it.
    @discardableResult
    func assertTrackerBlockerCount(atLeast minimum: Int, timeout: TimeInterval = TIMEOUT) -> Int {
        let count = trackerBlockerCount(timeout: timeout)
        XCTAssertGreaterThanOrEqual(count, minimum, "The Tracker Blocker pill count is lower than expected")
        return count
    }

    func assertTrackerBlockerCount(equals expected: Int, timeout: TimeInterval = TIMEOUT) {
        let count = trackerBlockerCount(timeout: timeout)
        XCTAssertEqual(count, expected, "The Tracker Blocker pill count is not the expected total")
    }

    /// Reads the pill and the weekly panel, then asserts the pill shows the footer's lifetime total, which the
    /// weekly count can't exceed. With `previous`, also asserts that each total grew by `blocked`. Leaves the panel open.
    @discardableResult
    func assertTrackerBlockerTotals(
        previous: TrackerBlockerValues? = nil,
        increasedBy blocked: Int = 0
    ) -> TrackerBlockerValues {
        let current = recordTrackerBlockerValues()
        XCTAssertEqual(current.pill, current.lifetime, "The pill should show the lifetime total from the footer chip")
        XCTAssertLessThanOrEqual(current.weekly, current.lifetime, "The weekly count should not exceed the lifetime total")
        if let previous {
            XCTAssertEqual(current.pill, previous.pill + blocked, "The pill should grow by the trackers just blocked")
            assertPanelTotalsGrew(from: previous, to: current, by: blocked)
        }
        return current
    }

    /// Reads the large count, which VoiceOver reads as "Trackers blocked this week: 6".
    private func trackerBlockerWeeklyCount(timeout: TimeInterval = TIMEOUT) -> Int {
        let prefix = String(format: .PrivacyDashboard.HeaderLabelAccessibilityLabel, "")
        return number(in: sel.TRACKER_BLOCKER_SHEET_WEEKLY_COUNT.element(in: app), after: prefix, timeout: timeout)
    }

    /// Reads the lifetime count the footer chip starts with, e.g. "5,305 since 2/13/2026 🎉".
    private func trackerBlockerLifetimeTotal(timeout: TimeInterval = TIMEOUT) -> Int {
        return number(in: sel.TRACKER_BLOCKER_SHEET_TOTAL.element(in: app), after: "", timeout: timeout)
    }

    /// Reads the pill, then opens the weekly panel and records its values, leaving it open.
    func recordTrackerBlockerValues() -> TrackerBlockerValues {
        let pill = trackerBlockerCount()
        tapTrackerBlockerPill()
        let rows = categoryRows
        BaseTestCase().waitForElementsToExist(rows)
        return TrackerBlockerValues(
            pill: pill,
            weekly: trackerBlockerWeeklyCount(),
            lifetime: trackerBlockerLifetimeTotal(),
            categories: zip(rows, trackerBlockerCategoryTitles).map { row, title in
                let prefix = String(format: .PrivacyDashboard.CategoryAccessibilityLabel, title, "")
                return number(in: row, after: prefix, timeout: TIMEOUT)
            },
            barFills: rows.map { row in
                app.windows.firstMatch.frame.contains(row.frame) ? row.saturatedPixelRatio() : nil
            }
        )
    }

    /// Opens the weekly panel and asserts it shows fresh values: the weekly total and the lifetime chip grew by
    /// `blocked`, each category by its `blockedByCategory` count, and every bar was redrawn against the new total.
    func assertTrackerBlockerPanelRefreshed(
        from previous: TrackerBlockerValues,
        blocked: Int,
        blockedByCategory: [Int]
    ) {
        let current = recordTrackerBlockerValues()
        assertPanelTotalsGrew(from: previous, to: current, by: blocked)
        for (index, title) in trackerBlockerCategoryTitles.enumerated() {
            XCTAssertEqual(
                current.categories[index],
                previous.categories[index] + blockedByCategory[index],
                "\(title) should grow by the trackers just blocked in that category"
            )
            assertBarRedrawn(title: title, index: index, previous: previous, current: current)
        }
        XCTAssertTrue(
            blockedByCategory.indices.contains { blockedByCategory[$0] == 0 && previous.categories[$0] > 0 },
            "No category with a bar kept its value, so no bar could be checked to get shorter"
        )
    }

    private func assertPanelTotalsGrew(
        from previous: TrackerBlockerValues,
        to current: TrackerBlockerValues,
        by blocked: Int
    ) {
        XCTAssertEqual(
            current.weekly,
            previous.weekly + blocked,
            "The weekly count should grow by the trackers just blocked"
        )
        XCTAssertEqual(
            current.lifetime,
            previous.lifetime + blocked,
            "The lifetime total should grow by the trackers just blocked"
        )
    }

    /// A bar covers the category's share of the weekly total, so it must grow or shrink as that share does.
    private func assertBarRedrawn(
        title: String,
        index: Int,
        previous: TrackerBlockerValues,
        current: TrackerBlockerValues
    ) {
        let previousShare = Double(previous.categories[index]) / Double(max(previous.weekly, 1))
        let currentShare = Double(current.categories[index]) / Double(max(current.weekly, 1))
        guard currentShare != previousShare else { return }
        guard let previousFill = previous.barFills[index], let currentFill = current.barFills[index] else {
            XCTFail("The \(title) row isn't fully on screen, so its bar can't be measured")
            return
        }
        if currentShare < previousShare {
            XCTAssertLessThan(currentFill, previousFill, "The \(title) bar should be shorter against the new weekly total")
        } else if currentShare > previousShare {
            XCTAssertGreaterThan(currentFill, previousFill, "The \(title) bar should be longer against the new weekly total")
        }
    }

    private var categoryRows: [XCUIElement] {
        trackerBlockerCategoryTitles.indices.map { sel.trackerBlockerSheetCategoryRow($0).element(in: app) }
    }

    private var trackerBlockerCategoryTitles: [String] {
        [
            .PrivacyDashboard.CrossSiteTrackers,
            .PrivacyDashboard.Fingerprinters,
            .PrivacyDashboard.TrackingContent,
            .PrivacyDashboard.SocialTrackers
        ]
    }

    func closeTrackerBlockerSheet() {
        let closeButton = sel.TRACKER_BLOCKER_SHEET_CLOSE_BUTTON.element(in: app)
        closeButton.waitAndTap()
        BaseTestCase().mozWaitForElementToNotExist(closeButton)
    }

    private func number(in element: XCUIElement, after prefix: String, timeout: TimeInterval) -> Int {
        BaseTestCase().mozWaitForElementToExist(element, timeout: timeout)
        guard let number = element.wholeNumberInLabel(after: prefix, timeout: timeout) else {
            XCTFail("No count after '\(prefix)' in '\(element.label)' (\(element.identifier))")
            return 0
        }
        return number
    }

    func assertTrackerBlockerPillIsBetweenShortcutsAndJumpBackIn() {
        let topSites = topSitesSel.TOP_SITE_ITEM_CELL.query(in: app)
        let jumpBackInTitle = jumpBackInSel.SECTION_TITLE.element(in: app)
        BaseTestCase().waitForElementsToExist([topSites.firstMatch, trackerBlockerPill, jumpBackInTitle])
        let lastTopSite = topSites.element(boundBy: topSites.count - 1)
        XCTAssertTrue(trackerBlockerPill.isBelow(element: lastTopSite), "The pill should be below the Shortcuts grid")
        XCTAssertTrue(trackerBlockerPill.isAbove(element: jumpBackInTitle), "The pill should be above Jump Back In")
    }

    func tapTrackerBlockerPill() {
        trackerBlockerPill.waitAndTap()
    }

    /// Asserts the weekly total and exactly the four category rows are shown.
    func assertTrackerBlockerWeeklySheet() {
        BaseTestCase().waitForElementsToExist([sel.TRACKER_BLOCKER_SHEET_WEEKLY_COUNT.element(in: app)] + categoryRows)
        let rowAfterLast = sel.trackerBlockerSheetCategoryRow(trackerBlockerCategoryTitles.count).element(in: app)
        BaseTestCase().mozWaitForElementToNotExist(rowAfterLast)
    }
}
