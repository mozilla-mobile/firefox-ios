/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import EarlGrey

class SecurityTests: KIFTestCase {
    fileprivate var webRoot: String!
    
    override func setUp() {
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI()
        super.setUp()
    }
    
    func enterUrl(url: String) {
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url"))
            .perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address"))
            .perform(grey_typeText("\(url)\n"))
    }
    
    override func beforeEach() {
        let testURL = "\(webRoot!)/localhostLoad.html"
        enterUrl(url: testURL)
        tester().waitForView(withAccessibilityLabel: "Web content")
        tester().waitForWebViewElementWithAccessibilityLabel("Session exploit")
    }
    
    /// Tap the Session exploit button, which tries to load the session restore page on localhost
    /// in the current tab. Make sure nothing happens.
    func testSessionExploit() {
        tester().tapWebViewElementWithAccessibilityLabel("Session exploit")
        tester().wait(forTimeInterval: 1)
        
        // Make sure the URL doesn't change.
        let webView = tester().waitForView(withAccessibilityLabel: "Web content") as! WKWebView
        XCTAssertEqual(webView.url!.path, "/localhostLoad.html")
        
        // Also make sure the XSS alert doesn't appear.
        XCTAssertFalse(tester().viewExistsWithLabel("Local page loaded"))
    }
    
    /// Tap the Error exploit button, which tries to load the error page on localhost
    /// in a new tab via window.open(). Make sure nothing happens.
    func testErrorExploit() {
        // We should only have one tab open.
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
        
        tester().tapWebViewElementWithAccessibilityLabel("Error exploit")
        
        // Make sure a new tab wasn't opened.
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "1", traits: UIAccessibilityTraitButton)
    }
    
    /// Tap the New tab exploit button, which tries to piggyback off of an error page
    /// to load the session restore exploit. A new tab will load showing an error page,
    /// but we shouldn't be able to load session restore.
    func testWindowExploit() {
        tester().tapWebViewElementWithAccessibilityLabel("New tab exploit")
        tester().wait(forTimeInterval: 30)
        let webView = tester().waitForView(withAccessibilityLabel: "Web content") as! WKWebView
        
        // Make sure the URL doesn't change.
        XCTAssertEqual(webView.url!.path, "/errors/error.html")
        
        // Also make sure the XSS alert doesn't appear.
        XCTAssertFalse(tester().viewExistsWithLabel("Local page loaded"))
    }
    
    /// Tap the URL spoof button, which opens a new window to a host with an invalid port.
    /// Since the window has no origin before load, the page is able to modify the document,
    /// so make sure we don't show the URL.
    func testSpoofExploit() {
        tester().tapWebViewElementWithAccessibilityLabel("URL spoof")
        
        // Wait for the window to open.
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "2", traits: UIAccessibilityTraitButton)
        tester().waitForAnimationsToFinish()
        
        // Make sure the URL bar doesn't show the URL since it hasn't loaded.
        XCTAssertFalse(tester().viewExistsWithLabel("http://1.2.3.4:1234/"))
        
        // Since the newly opened tab doesn't have a URL/title we can't find its accessibility
        // element to close it in teardown. Workaround: load another page first.
        enterUrl(url: webRoot!)
    }
    
    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
        super.tearDown()
    }
}
