/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Foundation
import Shared
import Storage

import XCTest

class TestTopTabs: XCTestCase {

    var window: UIWindow!
    var manager: TabManager!
    var tabVC: TopTabsViewController!
    var bvc: BrowserViewController! //Needed because of delegates dawg

    //Give some time for animations to finish
    func verifyAfter(block: () -> Void) {
        let seconds: Double = 1
        let dispatchTime: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_main_queue(), block)
    }

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 500, height: 500))
        let profile = TabManagerMockProfile()
        //This prevent the "whats new" tab from opening. Tests dont care 👯
        profile.prefs.setString(AppInfo.appVersion, forKey: LatestAppVersionProfileKey)
        self.manager = TabManager(prefs: profile.prefs, imageStore: nil)
        self.bvc = BrowserViewController(profile: profile, tabManager: manager)
        window.addSubview(bvc.view)
    }

    // We do this AFTER we've setup the TabManger with the state we want
    //This is a way of tricking TopTabs from not animating while I setup the correct state
    private func createTopTabsVC() {
        tabVC = TopTabsViewController(tabManager: manager)
        tabVC.delegate = bvc
        bvc.topTabsViewController = tabVC
        window.addSubview(tabVC.view)
        tabVC.collectionView.reloadData()
        tabVC.collectionView.layoutIfNeeded()
    }


    func testAddingTab() {
        createTopTabsVC()

        let countBefore = tabVC.collectionView.numberOfItemsInSection(0)
        XCTAssertEqual(1, countBefore, "Make sure only one tab is open.")
        tabVC.newTabTapped()
        let expectation = expectationWithDescription("A single tab is Added")

        verifyAfter { 
            let countAfter = self.tabVC.collectionView.numberOfItemsInSection(0)
            XCTAssertEqual(countBefore + 1, countAfter, "There should be one more tab after the newTab button is tapped")
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testRemoveTab() {
        manager.selectTab(manager.addTab())
        createTopTabsVC()

        let countBefore = tabVC.collectionView.numberOfItemsInSection(0)
        let cell = tabVC.collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! TopTabCell
        XCTAssertNotNil(cell)
        cell.closeTab()
        let expectation = expectationWithDescription("A single tab is removed")

        verifyAfter {
            let countAfter = self.tabVC.collectionView.numberOfItemsInSection(0)
            XCTAssertEqual(countBefore - 1, countAfter, "There should be one less tab after the newTab button is tapped")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }

    func testRemoveLastNormalTab() {
        createTopTabsVC()

        let countBefore = tabVC.collectionView.numberOfItemsInSection(0)
        XCTAssertEqual(countBefore, 1)
        let cell = tabVC.collectionView.cellForItemAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! TopTabCell
        XCTAssertNotNil(cell)
        cell.closeTab()
        let expectation = expectationWithDescription("A single tab is removed")

        verifyAfter {
            let countAfter = self.tabVC.collectionView.numberOfItemsInSection(0)
            XCTAssertEqual(countBefore, countAfter, "A new tab should have been added.")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }


    // We should keep the tab state while toggling private mode
    func testCorrectTabSelectedWhileTogglingPrivateMode() {
        (0..<10).forEach {_ in manager.addTab() }
        let normalSelectedTab = manager.normalTabs[3]
        manager.selectTab(normalSelectedTab)
        createTopTabsVC()

        tabVC.togglePrivateModeTapped()
        let expectation = expectationWithDescription("Private Mode is selected.")

        verifyAfter {
            XCTAssertTrue(self.manager.selectedTab!.isPrivate, "We should have created and selected a private tab")
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)

        tabVC.togglePrivateModeTapped()
        let normalModeExpectation = expectationWithDescription("Normal mode selected")
        verifyAfter {
            XCTAssertTrue(!self.manager.selectedTab!.isPrivate, "We should have created and selected a private tab")
            XCTAssertEqual(normalSelectedTab, self.manager.selectedTab, "The selectedtab should be equal to the previous normal tab")
            normalModeExpectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: nil)
    }
    

}
