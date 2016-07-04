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
    
    override func setUp() {
        webRoot = SimplePageServer.start()
    }
    
    func testTopTabs() {
        testAddTab()
        testSwitchTabs()
        testPrivateModeButton()
        testCloseTab()
    }
    
    private func testAddTab() {
        tester().waitForTappableViewWithAccessibilityLabel("Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        
        tester().tapViewWithAccessibilityIdentifier("url")
        
        for i in 0...(numberOfTabs-1) {
            let url = "\(webRoot)/numberedPage.html?page=\(i)"
            tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
            tester().waitForWebViewElementWithAccessibilityLabel("Page \(i)")
            tester().tapViewWithAccessibilityLabel("New Tab")
        }
        
        tester().waitForTappableViewWithAccessibilityLabel("Show Tabs", value: String(1+numberOfTabs), traits: UIAccessibilityTraitButton)
    }
    
    private func testSwitchTabs() {
        let urlField = tester().waitForViewWithAccessibilityIdentifier("url") as! UITextField
        
        tester().tapViewWithAccessibilityLabel("Page 2")
        tester().waitForAnimationsToFinish()
        tester().waitForTimeInterval(0.2)
        XCTAssertEqual(urlField.text, "\(webRoot)/numberedPage.html?page=2")
        
        tester().tapViewWithAccessibilityLabel("Page 1")
        tester().waitForAnimationsToFinish()
        tester().waitForTimeInterval(0.2)
        XCTAssertEqual(urlField.text, "\(webRoot)/numberedPage.html?page=1")
    }
    
    private func testPrivateModeButton() {
        let tabManager = (UIApplication.sharedApplication().delegate as! AppDelegate).tabManager
        
        tester().tapViewWithAccessibilityLabel("Private Tab")
        XCTAssertTrue(tabManager.selectedTab!.isPrivate)
        
        tester().tapViewWithAccessibilityLabel("Private Tab")
        XCTAssertFalse(tabManager.selectedTab!.isPrivate)
    }
    
    private func testCloseTab() {
        tester().tapViewWithAccessibilityLabel("Remove page - New Tab")
        for i in 0...(numberOfTabs-1) {
            tester().tapViewWithAccessibilityLabel("Remove page - Page \(i)")
        }
    }
    
    override func tearDown() {
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
}
