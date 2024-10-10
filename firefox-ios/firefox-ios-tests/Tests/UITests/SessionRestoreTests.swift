// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import WebKit
import Shared
@testable import Client

class SessionRestoreTests: KIFTestCase {
    fileprivate var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
        super.setUp()
    }

    func testTabRestore() {
        let url1 = "\(webRoot!)/numberedPage.html?page=1"
        let url2 = "\(webRoot!)/numberedPage.html?page=2"
        let url3 = "\(webRoot!)/numberedPage.html?page=3"

        // Build a session restore URL from the current homepage URL.
        var jsonDict = [String: Any]()
        jsonDict["history"] = [url1, url2, url3]
        jsonDict["currentPage"] = -1 as Any?
        let escapedJSON = jsonDict.asString?.addingPercentEncoding(withAllowedCharacters: .URLAllowed)
        _ = tester().waitForView(withAccessibilityLabel: "Web content") as! WKWebView
        let restoreURL = PrivilegedRequest(url: URL(string: "\(InternalURL.baseUrl)/\(InternalURL.Path.sessionrestore.rawValue)?history=\(escapedJSON!)")!).url

        // Enter the restore URL and verify the back/forward history.
        // After triggering the restore, the session should look like this:
        //   about:home, page1, *page2*, page3
        // where page2 is active.
        tester().wait(forTimeInterval: 3)
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: restoreURL!.absoluteString)
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")
        tester().tapView(withAccessibilityLabel: AccessibilityIdentifiers.Toolbar.backButton)

        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        tester().tapView(withAccessibilityLabel: AccessibilityIdentifiers.Toolbar.backButton)

        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        tester().waitForAnimationsToFinish(withTimeout: 5)

        let canGoBack: Bool
        do {
            try tester().tryFindingTappableView(withAccessibilityLabel: AccessibilityIdentifiers.Toolbar.backButton)
            canGoBack = true
        } catch _ {
            canGoBack = false
        }

        XCTAssertFalse(canGoBack, "Reached the beginning of browser history")

        tester().tapView(withAccessibilityLabel: AccessibilityIdentifiers.Toolbar.forwardButton)
        tester().tapView(withAccessibilityLabel: AccessibilityIdentifiers.Toolbar.forwardButton)
        tester().tapView(withAccessibilityLabel: AccessibilityIdentifiers.Toolbar.forwardButton)

        tester().waitForAnimationsToFinish(withTimeout: 5)
        tester().waitForWebViewElementWithAccessibilityLabel("Page 3")
        let canGoForward: Bool
        do {
            try tester().tryFindingTappableView(withAccessibilityLabel: AccessibilityIdentifiers.Toolbar.forwardButton)
            canGoForward = true
        } catch _ {
            canGoForward = false
        }
        XCTAssertFalse(canGoForward, "Reached the end of browser history")
    }

    override func tearDown() {
        tester().wait(forTimeInterval: 3)
        BrowserUtils.resetToAboutHomeKIF(tester())
        tester().wait(forTimeInterval: 3)
        BrowserUtils.clearPrivateDataKIF(tester())
        super.tearDown()
    }
}
