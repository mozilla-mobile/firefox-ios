/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared


/// This test should be disabled since session restore does not seem to work
class SessionRestoreTests: KIFTestCase {
    fileprivate var webRoot: String!
    
    override func setUp() {
        BrowserUtils.dismissFirstRunUI(tester())
        webRoot = SimplePageServer.start()
        super.setUp()
    }
    
    func testTabRestore() {
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        let url2 = "\(webRoot)/numberedPage.html?page=2"
        let url3 = "\(webRoot)/numberedPage.html?page=3"
        
        // Build a session restore URL from the current homepage URL.
        var jsonDict = [String: AnyObject]()
        jsonDict["history"] = [url1, url2, url3]
        jsonDict["currentPage"] = -1 as AnyObject?
        let escapedJSON = JSON.stringify(jsonDict, pretty: false).stringByAddingPercentEncodingWithAllowedCharacters(CharacterSet.URLQueryAllowedCharacterSet())!
        let webView = tester().waitForView(withAccessibilityLabel: "Web content") as! WKWebView
        let restoreURL = URL(string: "/about/sessionrestore?history=\(escapedJSON)", relativeToURL: webView.URL!)
        
        // Enter the restore URL and verify the back/forward history.
        // After triggering the restore, the session should look like this:
        //   about:home, page1, *page2*, page3
        // where page2 is active.
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(restoreURL!.absoluteString!)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")
        tester().tapView(withAccessibilityLabel: "Back")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        tester().tapView(withAccessibilityLabel: "Back")
        tester().waitForView(withAccessibilityLabel: "Top sites")
        let canGoBack: Bool
        do {
            try tester().tryFindingTappableView(withAccessibilityLabel: "Back")
            canGoBack = true
        } catch _ {
            canGoBack = false
        }
        XCTAssertFalse(canGoBack, "Reached the beginning of browser history")
        tester().tapView(withAccessibilityLabel: "Forward")
        tester().tapView(withAccessibilityLabel: "Forward")
        tester().tapView(withAccessibilityLabel: "Forward")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 3")
        let canGoForward: Bool
        do {
            try tester().tryFindingTappableView(withAccessibilityLabel: "Forward")
            canGoForward = true
        } catch _ {
            canGoForward = false
        }
        XCTAssertFalse(canGoForward, "Reached the end of browser history")
    }
    
    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
}
