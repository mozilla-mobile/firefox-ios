/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
@testable import Storage
@testable import Client

// This test is only for devices that does not have Panel implementation (e.g. iPad):
// https://github.com/mozilla-mobile/firefox-ios/blob/master/Client/Frontend/Home/HomePanels.swift#L23
// When running on iPhone, this test will fail, because the Collectionview does not have an identifier
class TopTabsTests: KIFTestCase {
    fileprivate var webRoot: String!
    let numberOfTabs = 4
    lazy var collection: UICollectionView = self.tester().waitForView(withAccessibilityIdentifier: "Top Tabs View") as! UICollectionView
    
    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
         BrowserUtils.dismissFirstRunUI(tester())
    }
    
    override func tearDown() {
        super.tearDown()
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
    
    fileprivate func clearPrivateDataFromHome() {
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Clear Private Data")
        tester().tapView(withAccessibilityLabel: "Clear Private Data", traits: UIAccessibilityTraitButton)
        tester().tapView(withAccessibilityLabel: "OK")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Done")
        tester().tapView(withAccessibilityLabel: "home")
    }
    
    fileprivate func topTabsEnabled() -> Bool {
        let bvc = getBrowserViewController()
        return bvc.shouldShowTopTabsForTraitCollection(bvc.traitCollection)
    }
    
    fileprivate func getBrowserViewController() -> BrowserViewController {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).browserViewController
    }
    
    func testTopTabs() {
        guard topTabsEnabled() else {
            return
        }
    
        AddTab()
        UndoCloseAll()
        SwitchTabs()
        PrivateModeButton()
        CloseTab()
    }
    
    fileprivate func AddTab() {
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        
        tester().tapView(withAccessibilityIdentifier: "url")
        
        for i in 0..<numberOfTabs {
            let url = "\(webRoot)/numberedPage.html?page=\(i)"
            tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url)\n")
            tester().waitForWebViewElementWithAccessibilityLabel("Page \(i)")
            tester().tapView(withAccessibilityLabel: "New Tab")
        }
        
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: String(1+numberOfTabs), traits: UIAccessibilityTraitButton)
    }
    
    fileprivate func UndoCloseAll() {
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Close All Tabs")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Undo")
    }
    
    fileprivate func SwitchTabs() {
        let urlField = tester().waitForView(withAccessibilityIdentifier: "url") as! UITextField
        
        tester().tapView(withAccessibilityLabel: "Page 2")
        tester().waitForAnimationsToFinish()
        XCTAssertEqual(urlField.text, "\(webRoot)/numberedPage.html?page=2")
        
        tester().tapView(withAccessibilityLabel: "Page 1")
        tester().waitForAnimationsToFinish()
        XCTAssertEqual(urlField.text, "\(webRoot)/numberedPage.html?page=1")
    }
    
    fileprivate func PrivateModeButton() {
        let tabManager = (UIApplication.sharedApplication().delegate as! AppDelegate).tabManager
        
        tester().tapView(withAccessibilityLabel: "Private Mode")
        XCTAssertTrue(tabManager.selectedTab!.isPrivate)
        
        tester().tapView(withAccessibilityLabel: "Private Mode")
        XCTAssertFalse(tabManager.selectedTab!.isPrivate)
        
        tester().tapView(withAccessibilityLabel: "Private Mode")
        tester().tapView(withAccessibilityLabel: "Remove page - New Tab")
        XCTAssertFalse(tabManager.selectedTab!.isPrivate)
    }
    
    fileprivate func CloseTab() {
        tester().tapView(withAccessibilityLabel: "Remove page - New Tab")
        for i in 0...(numberOfTabs-1) {
            tester().tapView(withAccessibilityLabel: "Remove page - Page \(i)")
        }
    }
    
    func testCloseAll() {
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        
        tester().tapView(withAccessibilityLabel: "New Tab")
        tester().tapView(withAccessibilityLabel: "New Tab")
        
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Close All Tabs")
        tester().waitForAnimationsToFinish()
        
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells.count, 1)
    }
    
    func testAddTabFromContext() {
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells.count, 1)
        
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "New Tab")
        tester().waitForAnimationsToFinish()
        
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "2", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells.count, 2)
        
        tester().tapView(withAccessibilityLabel: "Remove page - New Tab")
    }
    
    func testAddAndCloseTabFromTabTray() {
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells.count, 1)
        
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Add Tab")
        tester().waitForAnimationsToFinish()
        
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "2", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells.count, 2)
        
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        
        let tabsView = tester().waitForView(withAccessibilityLabel: "Tabs Tray").subviews.first as! UICollectionView
        
        if let cell = tabsView.cellForItem(at: IndexPath(item: 1, section: 0)) {
            tester().swipeView(withAccessibilityLabel: cell.accessibilityLabel, in: KIFSwipeDirection.left)
        }
        
        if let cell = tabsView.cellForItem(at: IndexPath(item: 0, section: 0)) {
            let view = tester().waitForTappableView(withAccessibilityLabel: cell.accessibilityLabel)
            view?.tap(at: CGPoint.zero)
        }
        
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        XCTAssertEqual(collection.visibleCells.count, 1)
    }
}
