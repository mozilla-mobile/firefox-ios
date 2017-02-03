/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class PrivateBrowsingTests: KIFTestCase {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }

    func testPrivateTabDoesntTrackHistory() {
        // First navigate to a normal tab and see that it tracks
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        tester().wait(forTimeInterval: 3)

        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "History")

        var tableView = tester().waitForView(withAccessibilityIdentifier: "History List") as! UITableView
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)
        tester().tapView(withAccessibilityLabel: "Cancel")

        // Then try doing the same thing for a private tab
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "New Private Tab")
        tester().tapView(withAccessibilityIdentifier: "url")

        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapView(withAccessibilityIdentifier: "url")
        tester().tapView(withAccessibilityLabel: "History")

        tableView = tester().waitForView(withAccessibilityIdentifier: "History List") as! UITableView
        XCTAssertEqual(tableView.numberOfRows(inSection: 0), 1)

        // Exit private mode
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Private Mode")
        tester().tapView(withAccessibilityLabel: "Page 1")
    }

    func testTabCountShowsOnlyNormalOrPrivateTabCount() {
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Add two tabs and make sure we see the right tab count
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "New Tab")
        tester().waitForAnimationsToFinish()
        var tabButton = tester().waitForView(withAccessibilityLabel: "Show Tabs") as! UIControl
        // Since a new tab is created in setup, the total tab count here is 3
        XCTAssertEqual(tabButton.accessibilityValue, "2", "Tab count shows 2 tabs")

        // Add a private tab and make sure we only see the private tab in the count, and not the normal tabs
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "New Private Tab")
        tester().waitForAnimationsToFinish()

        tabButton = tester().waitForView(withAccessibilityLabel: "Show Tabs") as! UIControl
        XCTAssertEqual(tabButton.accessibilityValue, "1", "Private tab count should show 1 tab opened")

        // Switch back to normal tabs and make sure the private tab doesnt get added to the count
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Private Mode")
        tester().tapView(withAccessibilityLabel: "Page 1")

        tabButton = tester().waitForView(withAccessibilityLabel: "Show Tabs") as! UIControl
        XCTAssertEqual(tabButton.accessibilityValue, "2", "Tab count shows 2 tabs")
    }

    func testNoPrivateTabsShowsAndHidesEmptyView() {
        // Do we show the empty private tabs panel view?
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Private Mode")
        var emptyView = tester().waitForView(withAccessibilityLabel: "Private Browsing")
        XCTAssertTrue(emptyView?.superview!.alpha == 1)

        // Do we hide it when we add a tab?
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "New Private Tab")
        tester().waitForView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Show Tabs")

        var visible = true
        do {
            try tester().tryFindingView(withAccessibilityLabel: "Private Browsing")
        } catch {
            // Label is no longer visible when a tab is present
            visible = false
        }
        XCTAssertFalse(visible)
        // Remove the private tab - do we see the empty view now?
        let tabsView = tester().waitForView(withAccessibilityLabel: "Tabs Tray").subviews.first as! UICollectionView
        while tabsView.numberOfItems(inSection: 0) > 0 {
            let cell = tabsView.cellForItem(at: IndexPath(item: 0, section: 0))!
            tester().swipeView(withAccessibilityLabel: cell.accessibilityLabel, in: KIFSwipeDirection.left)
            tester().waitForAbsenceOfView(withAccessibilityLabel: cell.accessibilityLabel)
        }

        emptyView = tester().waitForView(withAccessibilityLabel: "Private Browsing")
        XCTAssertTrue(emptyView?.superview!.alpha == 1)

        // Exit private mode
        tester().tapView(withAccessibilityLabel: "Private Mode")
    }

    func testClosePrivateTabsClosesPrivateTabs() {
        // First, make sure that selecting the option to ON will close the tabs
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().waitForView(withAccessibilityLabel: "Privacy")
        
        // In simulator, need to manually scroll to so the menu is visible
        tester().scrollView(withAccessibilityLabel: "Privacy", byFractionOfSizeHorizontal: 0, vertical: -3)
        
        tester().waitForView(withAccessibilityLabel: "Close Private Tabs, When Leaving Private Browsing")
        tester().setOn(true, forSwitchWithAccessibilityLabel: "Close Private Tabs, When Leaving Private Browsing")
        tester().tapView(withAccessibilityLabel: "Done")
        tester().tapView(withAccessibilityLabel: "Private Mode")

        XCTAssertEqual(numberOfTabs(), 0)

        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "New Private Tab")
        tester().waitForView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Show Tabs")

        XCTAssertEqual(numberOfTabs(), 1)

        tester().tapView(withAccessibilityLabel: "Private Mode")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Private Mode")

        XCTAssertEqual(numberOfTabs(), 0)

        tester().tapView(withAccessibilityLabel: "Private Mode")

        // Second, make sure selecting the option to OFF will not close the tabs
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().waitForView(withAccessibilityLabel: "Privacy")
        tester().scrollView(withAccessibilityLabel: "Privacy", byFractionOfSizeHorizontal: 0, vertical: -3)
        tester().waitForView(withAccessibilityLabel: "Close Private Tabs, When Leaving Private Browsing")
        tester().setOn(false, forSwitchWithAccessibilityLabel: "Close Private Tabs, When Leaving Private Browsing")
        tester().tapView(withAccessibilityLabel: "Done")
        tester().tapView(withAccessibilityLabel: "Private Mode")

        XCTAssertEqual(numberOfTabs(), 0)

        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "New Private Tab")
        tester().waitForView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Show Tabs")

        XCTAssertEqual(numberOfTabs(), 1)

        tester().tapView(withAccessibilityLabel: "Private Mode")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Private Mode")

        XCTAssertEqual(numberOfTabs(), 1)

        tester().tapView(withAccessibilityLabel: "Private Mode")
    }

    fileprivate func numberOfTabs() -> Int {
        let tabsView = tester().waitForView(withAccessibilityLabel: "Tabs Tray").subviews.first as! UICollectionView
        return tabsView.numberOfItems(inSection: 0)
    }
}
