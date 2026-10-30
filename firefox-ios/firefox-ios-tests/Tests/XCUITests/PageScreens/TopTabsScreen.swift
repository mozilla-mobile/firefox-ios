// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

/// The Top Tabs bar of iPad. Tabs scrolled out of the bar are absent from the accessibility tree.
@MainActor
final class TopTabsScreen {
    private let app: XCUIApplication
    private let sel: TopTabsSelectorsSet

    init(app: XCUIApplication, selectors: TopTabsSelectorsSet = TopTabsSelectors()) {
        self.app = app
        self.sel = selectors
    }

    private var collectionView: XCUIElement { sel.COLLECTION_VIEW.element(in: app) }
    private var privateModeButton: XCUIElement { sel.PRIVATE_MODE_BUTTON.element(in: app) }

    private func selectedTab(titled title: String) -> XCUIElement {
        let label = "\(title). \(String.TabsTray.TabTrayCurrentlySelectedTabAccessibilityLabel)"
        return collectionView.cells.matching(NSPredicate(format: "label == %@", label)).firstMatch
    }

    private func isInsideBar(_ tab: XCUIElement) -> Bool {
        guard tab.exists else { return false }
        let bar = collectionView.frame
        return tab.frame.minX >= bar.minX - 1 && tab.frame.maxX <= bar.maxX + 1
    }

    private func isPartlyInsideBar(_ tab: XCUIElement) -> Bool {
        tab.exists && tab.frame.intersects(collectionView.frame)
    }

    func assertPrivateModeButtonExists() {
        BaseTestCase().mozWaitForElementToExist(privateModeButton)
    }

    func tapPrivateModeButton() {
        privateModeButton.waitAndTap()
    }

    /// Checks the selected tab is fully shown in the bar, not clipped at either edge.
    func assertSelectedTabIsShown(titled title: String, timeout: TimeInterval = TIMEOUT) {
        let tab = selectedTab(titled: title)
        BaseTestCase().mozWaitForElementToExist(tab, timeout: timeout)
        let predicate = NSPredicate { _, _ in self.isInsideBar(tab) }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        if XCTWaiter().wait(for: [expectation], timeout: timeout) != .completed {
            XCTFail("Selected tab '\(title)' at \(tab.frame) is not fully inside the Top Tabs bar \(collectionView.frame)")
        }
    }

    func assertSelectedTabIsScrolledOut(titled title: String) {
        XCTAssertFalse(isPartlyInsideBar(selectedTab(titled: title)), "Selected tab '\(title)' is still shown in the Top Tabs bar")
    }

    /// A swipe can stop a few points short of the end, so the tab only needs to be back in view.
    func assertSelectedTabIsScrolledIn(titled title: String) {
        let tab = selectedTab(titled: title)
        BaseTestCase().mozWaitForElementToExist(tab)
        XCTAssertTrue(isPartlyInsideBar(tab), "Selected tab '\(title)' at \(tab.frame) is not shown in the Top Tabs bar")
    }

    func scrollToFirstTabs() {
        collectionView.swipeRight()
    }

    func scrollToLastTabs() {
        collectionView.swipeLeft()
    }

    func closeSelectedTab(titled title: String) {
        let closeLabel = String(format: .TopSitesRemoveButtonAccessibilityLabel, title)
        selectedTab(titled: title).buttons[closeLabel].waitAndTap()
    }

    func assertTabDoesNotExist(titled title: String) {
        let predicate = NSPredicate(format: "label == %@ OR label BEGINSWITH %@", title, "\(title).")
        BaseTestCase().mozWaitForElementToNotExist(collectionView.cells.matching(predicate).firstMatch)
    }

    /// Checks the tabs shown in the bar sit side by side with an equal gap and no overlap.
    func assertTabsAreAligned() {
        BaseTestCase().mozWaitForElementToExist(collectionView.cells.firstMatch)
        let frames = collectionView.cells.allElementsBoundByIndex.map(\.frame).sorted { $0.minX < $1.minX }
        let gaps = zip(frames, frames.dropFirst()).map { $1.minX - $0.maxX }
        guard let firstGap = gaps.first else { return }
        for gap in gaps {
            XCTAssertGreaterThanOrEqual(gap, 0, "Top tabs overlap: \(frames)")
            XCTAssertEqual(gap, firstGap, accuracy: 1, "Top tabs are not evenly spaced: \(frames)")
        }
    }

    func assertBarIsHidden(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitForElementToExist(collectionView)
        let predicate = NSPredicate { _, _ in self.collectionView.frame.maxY <= 0 }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        if XCTWaiter().wait(for: [expectation], timeout: timeout) != .completed {
            XCTFail("Top Tabs bar is still on screen at \(collectionView.frame)")
        }
    }

    func assertBarIsShown(timeout: TimeInterval = TIMEOUT) {
        BaseTestCase().mozWaitElementHittable(element: collectionView, timeout: timeout)
    }

    /// Tapping the status bar reveals the bars hidden by scrolling, as on iPhone.
    func tapStatusBar() {
        XCUIApplication(bundleIdentifier: "com.apple.springboard").statusBars.element(boundBy: 1).tap(force: true)
    }
}
