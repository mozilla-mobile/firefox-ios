/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
@testable import Storage
@testable import Client

class TopTabsTests: KIFTestCase {
    private var webRoot: String!
    let numberOfTabs = 4
    lazy var collection : UICollectionView = self.tester().waitForViewWithAccessibilityIdentifier("Top Tabs View") as! UICollectionView
    
    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
    }
    
    override func tearDown() {
        super.tearDown()
        BrowserUtils.resetToAboutHome(tester())
        clearPrivateDataFromHome()
    }
    
    private func clearPrivateDataFromHome() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Clear Private Data")
        tester().tapViewWithAccessibilityLabel("Clear Private Data", traits: UIAccessibilityTraitButton)
        tester().tapViewWithAccessibilityLabel("OK")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")
    }
    
    private func topTabsEnabled() -> Bool {
        let bvc = getBrowserViewController()
        return bvc.shouldShowTopTabsForTraitCollection(bvc.traitCollection)
    }
    
    private func getBrowserViewController() -> BrowserViewController {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).browserViewController
    }
    
    func testTopTabs() {
        guard topTabsEnabled() else {
            return
        }
        
        testAddTab()
        testUndoCloseAll()
        testSwitchTabs()
        testPrivateModeButton()
        testCloseTab()
    }
    
    private func testAddTab() {
        tester().waitForTappableViewWithAccessibilityLabel("Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        
        tester().tapViewWithAccessibilityIdentifier("url")
        
        for i in 0..<numberOfTabs {
            let url = "\(webRoot)/numberedPage.html?page=\(i)"
            tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
            tester().waitForWebViewElementWithAccessibilityLabel("Page \(i)")
            tester().tapViewWithAccessibilityLabel("New Tab")
        }
        
        tester().waitForTappableViewWithAccessibilityLabel("Show Tabs", value: String(1+numberOfTabs), traits: UIAccessibilityTraitButton)
    }
    
    private func testUndoCloseAll() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Close All Tabs")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Undo")
    }
    
    private func testSwitchTabs() {
        let urlField = tester().waitForViewWithAccessibilityIdentifier("url") as! UITextField
        
        tester().tapViewWithAccessibilityLabel("Page 2")
        tester().waitForAnimationsToFinish()
        XCTAssertEqual(urlField.text, "\(webRoot)/numberedPage.html?page=2")
        
        tester().tapViewWithAccessibilityLabel("Page 1")
        tester().waitForAnimationsToFinish()
        XCTAssertEqual(urlField.text, "\(webRoot)/numberedPage.html?page=1")
    }
    
    private func testPrivateModeButton() {
        let tabManager = (UIApplication.sharedApplication().delegate as! AppDelegate).tabManager
        
        tester().tapViewWithAccessibilityLabel("Private Mode")
        XCTAssertTrue(tabManager.selectedTab!.isPrivate)
        
        tester().tapViewWithAccessibilityLabel("Private Mode")
        XCTAssertFalse(tabManager.selectedTab!.isPrivate)
        
        tester().tapViewWithAccessibilityLabel("Private Mode")
        tester().tapViewWithAccessibilityLabel("Remove page - New Tab")
        XCTAssertFalse(tabManager.selectedTab!.isPrivate)
    }
    
    private func testCloseTab() {
        tester().tapViewWithAccessibilityLabel("Remove page - New Tab")
        for i in 0...(numberOfTabs-1) {
            tester().tapViewWithAccessibilityLabel("Remove page - Page \(i)")
        }
    }
    
    func testCloseAll() {
        tester().waitForTappableViewWithAccessibilityLabel("Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        
        tester().tapViewWithAccessibilityLabel("New Tab")
        tester().tapViewWithAccessibilityLabel("New Tab")
        
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Close All Tabs")
        tester().waitForAnimationsToFinish()
        
        tester().waitForTappableViewWithAccessibilityLabel("Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells().count, 1)
    }
    
    func testAddTabFromContext() {
        tester().waitForTappableViewWithAccessibilityLabel("Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells().count, 1)
        
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Tab")
        tester().waitForAnimationsToFinish()
        
        tester().waitForTappableViewWithAccessibilityLabel("Show Tabs", value: "2", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells().count, 2)
        
        tester().tapViewWithAccessibilityLabel("Remove page - New Tab")
    }
    
    func testAddAndCloseTabFromTabTray() {
        tester().waitForTappableViewWithAccessibilityLabel("Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells().count, 1)
        
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Add Tab")
        tester().waitForAnimationsToFinish()
        
        tester().waitForTappableViewWithAccessibilityLabel("Show Tabs", value: "2", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells().count, 2)
        
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        
        let tabsView = tester().waitForViewWithAccessibilityLabel("Tabs Tray").subviews.first as! UICollectionView
        
        if let cell = tabsView.cellForItemAtIndexPath(NSIndexPath(forItem: 1, inSection: 0)) {
            tester().swipeViewWithAccessibilityLabel(cell.accessibilityLabel, inDirection: KIFSwipeDirection.Left)
        }
        
        if let cell = tabsView.cellForItemAtIndexPath(NSIndexPath(forItem: 0, inSection: 0)) {
            let view = tester().waitForTappableViewWithAccessibilityLabel(cell.accessibilityLabel)
            view.tapAtPoint(CGPoint.zero)
        }
        
        tester().waitForTappableViewWithAccessibilityLabel("Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells().count, 1)
    }
}
