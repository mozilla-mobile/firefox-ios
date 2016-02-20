/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class NavigationTests: KIFTestCase, UITextFieldDelegate {
    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
    }

    /**
     * Tests basic page navigation with the URL bar.
     */
    func testNavigation() {
        tester().tapViewWithAccessibilityIdentifier("url")
        var textView = tester().waitForViewWithAccessibilityLabel("Address and Search") as? UITextField
        XCTAssertTrue(textView!.text!.isEmpty, "Text is empty")
        XCTAssertNotNil(textView!.placeholder, "Text view has a placeholder to show when its empty")

        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapViewWithAccessibilityIdentifier("url")
        textView = tester().waitForViewWithAccessibilityLabel("Address and Search") as? UITextField
        XCTAssertEqual(textView!.text, url1, "Text is url")

        let url2 = "\(webRoot)/numberedPage.html?page=2"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url2)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")

        tester().tapViewWithAccessibilityLabel("Back")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapViewWithAccessibilityLabel("Forward")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")
    }

    func testScrollsToTopWithMultipleTabs() {
        // test scrollsToTop works with 1 tab
        tester().tapViewWithAccessibilityIdentifier("url")
        let url = "\(webRoot)/scrollablePage.html?page=1"
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Top")

//        var webView = tester().waitForViewWithAccessibilityLabel("Web content") as? WKWebView
        tester().scrollViewWithAccessibilityIdentifier("contentView", byFractionOfSizeHorizontal: -0.9, vertical: -0.9)
        tester().waitForWebViewElementWithAccessibilityLabel("Bottom")

        tester().tapStatusBar()
        tester().waitForWebViewElementWithAccessibilityLabel("Top")

        // now open another tab and test it works too
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        let addTabButton = tester().waitForViewWithAccessibilityLabel("Add Tab") as? UIButton
        addTabButton?.tap()
        tester().waitForViewWithAccessibilityLabel("Web content")
        let url2 = "\(webRoot)/scrollablePage.html?page=2"
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(url2)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Top")

        tester().scrollViewWithAccessibilityIdentifier("contentView", byFractionOfSizeHorizontal: -0.9, vertical: -0.9)
        tester().waitForWebViewElementWithAccessibilityLabel("Bottom")

        tester().tapStatusBar()
        tester().waitForWebViewElementWithAccessibilityLabel("Top")
    }

    func testTapSignInShowsFxAFromRemoteTabPanel() {
        tester().tapViewWithAccessibilityLabel("Synced tabs")
        tester().tapViewWithAccessibilityLabel("Sign in")
        tester().waitForViewWithAccessibilityLabel("Web content")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Sign in")
    }

    func testTapSignInShowsFxAFromTour() {
        // Launch the tour from the settings
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Show Tour")
        tester().waitForAnimationsToFinish()

        // Swipe to the end of the tour
        tester().swipeViewWithAccessibilityLabel("Intro Tour Carousel", inDirection: KIFSwipeDirection.Left)
        tester().swipeViewWithAccessibilityLabel("Intro Tour Carousel", inDirection: KIFSwipeDirection.Left)

        tester().tapViewWithAccessibilityLabel("Sign in to Firefox")
        tester().waitForViewWithAccessibilityLabel("Web content")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("home")
    }

    func testTapSigninShowsFxAFromSettings() {
        // Navigation to the settings to select the signin option
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Sign In to Firefox")
        tester().waitForViewWithAccessibilityLabel("Web content")

        // Go back to the home screen
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")
    }

    func testToggleBetweenMobileAndDesktopSite() {
        // Load URL and ensure that we are on the mobile site initially
        loadURL("\(webRoot)/numberedPage.html?page=1", webViewElementAccessibilityLabel: "Page 1")
        ensureMobileSite()

        // Request desktop site and ensure that we get it
        requestDesktopSite("Page 1")
        ensureDesktopSite()

        // Request mobile site and ensure that we get it
        requestMobileSite("Page 1")
        ensureMobileSite()
    }

    func testNavigationPreservesDesktopSiteOnSameHost() {
        // Load URL and ensure that we are on the mobile site initially
        loadURL("\(webRoot)/numberedPage.html?page=1", webViewElementAccessibilityLabel: "Page 1")
        ensureMobileSite()

        // Request desktop site and ensure that we get it
        requestDesktopSite("Page 1")
        ensureDesktopSite()

        // Navigate to different URL on the same host and ensure that we are still on the desktop site
        loadURL("\(webRoot)/numberedPage.html?page=2", webViewElementAccessibilityLabel: "Page 2")
        ensureDesktopSite()

        // Navigate to different host and ensure that we get the mobile site again
        loadURL("http://localhost")
        ensureMobileSite()
    }

    func testReloadPreservesMobileOrDesktopSite() {
        // Load URL and ensure that we are on the mobile site initially
        loadURL("\(webRoot)/numberedPage.html?page=1", webViewElementAccessibilityLabel: "Page 1")
        ensureMobileSite()

        // Reload and ensure that we are still on the mobile site
        reload("Page 1")
        ensureMobileSite()

        // Request desktop site and ensure that we get it
        requestDesktopSite("Page 1")
        ensureDesktopSite()

        // Reload and ensure that we are still on the desktop site
        reload("Page 1")
        ensureDesktopSite()
    }

    func testBackForwardNavigationRestoresMobileOrDesktopSite() {
        // Load first URL and ensure that we are on the mobile site initially
        loadURL("\(webRoot)/numberedPage.html?page=1", webViewElementAccessibilityLabel: "Page 1")
        ensureMobileSite()

        // Navigate to second URL and ensure that we are still on the mobile site
        loadURL("\(webRoot)/numberedPage.html?page=2", webViewElementAccessibilityLabel: "Page 2")
        ensureMobileSite()

        // Request desktop site and ensure that we get it
        requestDesktopSite("Page 2")
        ensureDesktopSite()

        // Navigate back and ensure that we are on the mobile site again
        tester().tapViewWithAccessibilityLabel("Back")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        ensureMobileSite()

        // Navigate forward and ensure that we are on the desktop site again
        tester().tapViewWithAccessibilityLabel("Forward")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")
        ensureDesktopSite()
    }

    private func loadURL(url: String, webViewElementAccessibilityLabel: String? = nil) {
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder(url + "\n")
        if let label = webViewElementAccessibilityLabel {
            tester().waitForWebViewElementWithAccessibilityLabel(label)
        } else {
            tester().waitForTimeInterval(5)
        }
    }

    private func reload(webViewElementAccessibilityLabel: String) {
        tester().tapViewWithAccessibilityLabel("Reload")
        tester().waitForWebViewElementWithAccessibilityLabel(webViewElementAccessibilityLabel)
    }

    private func ensureMobileSite() {
        tester().longPressViewWithAccessibilityLabel("Reload", duration: 1)
        tester().waitForViewWithAccessibilityLabel("Request Desktop Site")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Request Desktop Site")
    }
    
    private func ensureDesktopSite() {
        tester().longPressViewWithAccessibilityLabel("Reload", duration: 1)
        tester().waitForViewWithAccessibilityLabel("Request Mobile Site")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForAbsenceOfViewWithAccessibilityLabel("Request Mobile Site")
    }

    private func requestMobileSite(webViewElementAccessibilityLabel: String) {
        tester().longPressViewWithAccessibilityLabel("Reload", duration: 1)
        tester().waitForViewWithAccessibilityLabel("Request Mobile Site")
        tester().tapViewWithAccessibilityLabel("Request Mobile Site")
        tester().waitForWebViewElementWithAccessibilityLabel(webViewElementAccessibilityLabel)
    }

    private func requestDesktopSite(webViewElementAccessibilityLabel: String) {
        tester().longPressViewWithAccessibilityLabel("Reload", duration: 1)
        tester().waitForViewWithAccessibilityLabel("Request Desktop Site")
        tester().tapViewWithAccessibilityLabel("Request Desktop Site")
        tester().waitForWebViewElementWithAccessibilityLabel(webViewElementAccessibilityLabel)
    }

    override func tearDown() {
        BrowserUtils.clearHistoryItems(tester(), numberOfTests: 5)
    }
}
