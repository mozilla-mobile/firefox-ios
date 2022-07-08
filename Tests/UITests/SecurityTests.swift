// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import WebKit
@testable import Client

class SecurityTests: KIFTestCase {
    fileprivate var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
        super.setUp()
    }

    override func beforeEach() {
        let testURL = "\(webRoot!)/localhostLoad.html"
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().wait(forTimeInterval: 3)
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: testURL)

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
        tester().wait(forTimeInterval: 5)
    }

    /// Tap the Error exploit button, which tries to load the error page on localhost
    /// in a new tab via window.open(). Make sure nothing happens.
    func testErrorExploit() {
        // We should only have one tab open.
        let tabcount:String?
        if BrowserUtils.iPad() {
            tabcount = tester().waitForView(withAccessibilityIdentifier: "TopTabsViewController.tabsButton")?.accessibilityValue
        } else {
            tabcount = tester().waitForView(withAccessibilityIdentifier: "TabToolbar.tabsButton")?.accessibilityValue
        }

        // make sure a new tab wasn't opened.
        tester().tapWebViewElementWithAccessibilityLabel("Error exploit")
        tester().wait(forTimeInterval: 1.0)
        let newTabcount:String?
        if BrowserUtils.iPad() {
            newTabcount = tester().waitForView(withAccessibilityIdentifier: "TopTabsViewController.tabsButton")?.accessibilityValue
        } else {
            newTabcount = tester().waitForView(withAccessibilityIdentifier: "TabToolbar.tabsButton")?.accessibilityValue
        }
        XCTAssert(tabcount != nil && tabcount == newTabcount)
        }

    /// Tap the New tab exploit button, which tries to piggyback off of an error page
    /// to load the session restore exploit. A new tab will load showing an error page,
    /// but we shouldn't be able to load session restore.
    func testWindowExploit() {
        tester().wait(forTimeInterval: 3)
        tester().tapWebViewElementWithAccessibilityLabel("New tab exploit")
        tester().wait(forTimeInterval: 3)
        let webView = tester().waitForView(withAccessibilityLabel: "Web content") as! WKWebView

        // Make sure the URL doesn't change.
        XCTAssert(webView.url == nil)

        // Also make sure the XSS alert doesn't appear.
        XCTAssertFalse(tester().viewExistsWithLabel("Local page loaded"))

        // Workaround number of tabs not updated
        tester().tapView(withAccessibilityIdentifier: "TabToolbar.tabsButton")
        tester().tapView(withAccessibilityIdentifier: "closeAllTabsButtonTabTray")
        tester().tapView(withAccessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCloseAllButton)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
    }

    /// Tap the URL spoof button, which opens a new window to a host with an invalid port.
    /// Since the window has no origin before load, the page is able to modify the document,
    /// so make sure we don't show the URL.
    func testSpoofExploit() {
        tester().wait(forTimeInterval: 3)
        tester().tapWebViewElementWithAccessibilityLabel("URL spoof")

        // Wait for the window to open.
        tester().waitForTappableView(withAccessibilityLabel: "Show Tabs", value: "2", traits: UIAccessibilityTraits.button)
        tester().waitForAnimationsToFinish()

        // Make sure the URL bar doesn't show the URL since it hasn't loaded.
        XCTAssertFalse(tester().viewExistsWithLabel("http://1.2.3.4:1234/"))

        // Workaround number of tabs not updated
        tester().tapView(withAccessibilityIdentifier: "TabToolbar.tabsButton")
        tester().tapView(withAccessibilityIdentifier: "closeAllTabsButtonTabTray")
        tester().tapView(withAccessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCloseAllButton)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        tester().wait(forTimeInterval: 5)
    }

    // For blob URLs, just show "blob:" to the user (see bug 1446227)
    func testBlobUrlShownAsSchemeOnly() {
        let url = "\(webRoot!)/blobURL.html"
        // script that will load a blob url
        tester().wait(forTimeInterval: 3)
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)
        tester().wait(forTimeInterval: 1)
        let webView = tester().waitForView(withAccessibilityLabel: "Web content") as! WKWebView
        XCTAssert(webView.url!.absoluteString.starts(with: "blob:http://")) // webview internally has "blob:<rest of url>"
        let bvc = UIApplication.shared.keyWindow!.rootViewController?.children[0] as! BrowserViewController
        XCTAssertEqual(bvc.urlBar.locationView.urlTextField.text, "blob:") // only display "blob:"
    }

    // Web pages can't have firefox: urls, these should be used external to the app only (see bug 1447853)
    func testFirefoxSchemeBlockedOnWebpages() {
        let url = "\(webRoot!)/firefoxScheme.html"
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)
        tester().tapWebViewElementWithAccessibilityLabel("go")

        tester().wait(forTimeInterval: 1)
        let webView = tester().waitForView(withAccessibilityLabel: "Web content") as! WKWebView
        // Make sure the URL doesn't change.
        XCTAssertEqual(webView.url!.absoluteString, url)
    }

      func closeAllTabs() {
        tester().tapView(withAccessibilityIdentifier: "TabTrayController.removeTabsButton")
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().tapView(withAccessibilityIdentifier: AccessibilityIdentifiers.TabTray.deleteCloseAllButton)
        
      }

    override func tearDown() {
        tester().wait(forTimeInterval: 5)
        BrowserUtils.resetToAboutHomeKIF(tester())
        tester().wait(forTimeInterval: 5)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        super.tearDown()
    }
}
