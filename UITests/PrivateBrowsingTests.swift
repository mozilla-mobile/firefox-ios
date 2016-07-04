/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class PrivateBrowsingTests: KIFTestCase {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    override func tearDown() {
        do {
            try tester().tryFindingTappableViewWithAccessibilityLabel("home")
            tester().tapViewWithAccessibilityLabel("home")
        } catch _ {
        }
        BrowserUtils.resetToAboutHome(tester())
    }

    func testPrivateTabDoesntTrackHistory() {
        // First navigate to a normal tab and see that it tracks
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        tester().waitForTimeInterval(3)

        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityIdentifier("HomePanels.History")

        var tableView = tester().waitForViewWithAccessibilityIdentifier("History List") as! UITableView
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 1)
        tester().tapViewWithAccessibilityLabel("Cancel")

        // Then try doing the same thing for a private tab
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Private Tab")
        tester().tapViewWithAccessibilityIdentifier("url")

        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapViewWithAccessibilityIdentifier("url")
        tester().tapViewWithAccessibilityIdentifier("HomePanels.History")

        tableView = tester().waitForViewWithAccessibilityIdentifier("History List") as! UITableView
        XCTAssertEqual(tableView.numberOfRowsInSection(0), 1)

        // Exit private mode
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Private Mode")
        tester().tapViewWithAccessibilityLabel("Page 1")
    }

    func testTabCountShowsOnlyNormalOrPrivateTabCount() {
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Add two tabs and make sure we see the right tab count
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Tab")
        tester().waitForAnimationsToFinish()
        var tabButton = tester().waitForViewWithAccessibilityLabel("Show Tabs") as! UIControl
        XCTAssertEqual(tabButton.accessibilityValue, "2", "Tab count shows 2 tabs")

        // Add a private tab and make sure we only see the private tab in the count, and not the normal tabs
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Private Tab")
        tester().waitForAnimationsToFinish()

        tabButton = tester().waitForViewWithAccessibilityLabel("Show Tabs") as! UIControl
        XCTAssertEqual(tabButton.accessibilityValue, "1", "Private tab count should show 1 tab opened")

        // Switch back to normal tabs and make sure the private tab doesnt get added to the count
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Private Mode")
        tester().tapViewWithAccessibilityLabel("Page 1")

        tabButton = tester().waitForViewWithAccessibilityLabel("Show Tabs") as! UIControl
        XCTAssertEqual(tabButton.accessibilityValue, "2", "Tab count shows 2 tabs")
    }

    func testNoPrivateTabsShowsAndHidesEmptyView() {
        // Do we show the empty private tabs panel view?
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Private Mode")
        var emptyView = tester().waitForViewWithAccessibilityLabel("Private Browsing")
        XCTAssertTrue(emptyView.superview!.alpha == 1)

        // Do we hide it when we add a tab?
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Private Tab")
        tester().waitForViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Show Tabs")

        tester().waitForAbsenceOfViewWithAccessibilityLabel("Private Browsing")

        // Remove the private tab - do we see the empty view now?
        let tabsView = tester().waitForViewWithAccessibilityLabel("Tabs Tray").subviews.first as! UICollectionView
        while tabsView.numberOfItemsInSection(0) > 0 {
            let cell = tabsView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0))!
            tester().swipeViewWithAccessibilityLabel(cell.accessibilityLabel, inDirection: KIFSwipeDirection.Left)
            tester().waitForAbsenceOfViewWithAccessibilityLabel(cell.accessibilityLabel)
        }

        emptyView = tester().waitForViewWithAccessibilityLabel("Private Browsing")
        XCTAssertTrue(emptyView.superview!.alpha == 1)

        // Exit private mode
        tester().tapViewWithAccessibilityLabel("Private Mode")
    }

    func testClosePrivateTabsClosesPrivateTabs() {
        // First, make sure that selecting the option to ON will close the tabs
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        MenuUtils.openSettings(tester())

        let label = "Close Private Tabs, When Leaving Private Browsing"
        tester().scrollViewWithAccessibilityIdentifier("AppSettingsTableViewController.tableView", toViewWithAccessibilityLabel: label)
        tester().setOn(true, forSwitchWithAccessibilityLabel: label)
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("Private Mode")

        XCTAssertEqual(numberOfTabs(), 0)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Private Tab")
        tester().waitForViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Show Tabs")

        XCTAssertEqual(numberOfTabs(), 1)

        tester().tapViewWithAccessibilityLabel("Private Mode")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Private Mode")

        XCTAssertEqual(numberOfTabs(), 0)

        tester().tapViewWithAccessibilityLabel("Private Mode")

        // Second, make sure selecting the option to OFF will not close the tabs
        MenuUtils.openSettings(tester())
        tester().scrollViewWithAccessibilityIdentifier("AppSettingsTableViewController.tableView", toViewWithAccessibilityLabel: label)
        tester().setOn(false, forSwitchWithAccessibilityLabel: label)
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("Private Mode")

        XCTAssertEqual(numberOfTabs(), 0)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Private Tab")
        tester().waitForViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Show Tabs")

        XCTAssertEqual(numberOfTabs(), 1)

        tester().tapViewWithAccessibilityLabel("Private Mode")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Private Mode")

        XCTAssertEqual(numberOfTabs(), 1)

        tester().tapViewWithAccessibilityLabel("Private Mode")
    }

    private func numberOfTabs() -> Int {
        let tabsView = tester().waitForViewWithAccessibilityLabel("Tabs Tray").subviews.first as! UICollectionView
        return tabsView.numberOfItemsInSection(0)
    }
}
