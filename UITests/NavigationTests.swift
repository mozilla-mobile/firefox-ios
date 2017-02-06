/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

class NavigationTests: KIFTestCase, UITextFieldDelegate {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    /**
     * Tests basic page navigation with the URL bar.
     * This only works on iPhone, not iPad
     */
    
    func testNavigation() {
        tester().tapView(withAccessibilityIdentifier: "url")
        var textView = tester().waitForView(withAccessibilityLabel: "Address and Search") as? UITextField
        XCTAssertTrue(textView!.text!.isEmpty, "Text is empty")
        XCTAssertNotNil(textView!.placeholder, "Text view has a placeholder to show when its empty")

        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapView(withAccessibilityIdentifier: "url")
        textView = tester().waitForView(withAccessibilityLabel: "Address and Search") as? UITextField
        XCTAssertEqual(textView!.text, url1, "Text is url")

        let url2 = "\(webRoot)/numberedPage.html?page=2"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url2)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")

        tester().tapView(withAccessibilityLabel: "Back")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapView(withAccessibilityLabel: "Forward")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")
    }

    func testScrollsToTopWithMultipleTabs() {
        // test scrollsToTop works with 1 tab
        tester().tapView(withAccessibilityIdentifier: "url")
        let url = "\(webRoot)/scrollablePage.html?page=1"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Top")

//        var webView = tester().waitForViewWithAccessibilityLabel("Web content") as? WKWebView
        tester().scrollView(withAccessibilityIdentifier: "contentView", byFractionOfSizeHorizontal: -0.9, vertical: -0.9)
        tester().waitForWebViewElementWithAccessibilityLabel("Bottom")

        tester().tapStatusBar()
        tester().waitForWebViewElementWithAccessibilityLabel("Top")

        // now open another tab and test it works too
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "New Tab")
        tester().waitForView(withAccessibilityLabel: "Web content")
        let url2 = "\(webRoot)/scrollablePage.html?page=2"
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url2)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Top")

        tester().scrollView(withAccessibilityIdentifier: "contentView", byFractionOfSizeHorizontal: -0.9, vertical: -0.9)
        tester().waitForWebViewElementWithAccessibilityLabel("Bottom")

        tester().tapStatusBar()
        tester().waitForWebViewElementWithAccessibilityLabel("Top")
    }

    func testTapSignInShowsFxAFromRemoteTabPanel() {
        tester().tapView(withAccessibilityLabel: "History")
        tester().tapView(withAccessibilityLabel: "Synced devices")
        tester().tapView(withAccessibilityLabel: "Sign in")
        tester().waitForView(withAccessibilityLabel: "Web content")
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForView(withAccessibilityLabel: "Sign in")
    }

    func testTapSignInShowsFxAFromTour() {
        // Launch the tour from the settings
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Show Tour")
        tester().waitForAnimationsToFinish()

        // Swipe to the end of the tour
        tester().swipeView(withAccessibilityLabel: "Intro Tour Carousel", in: KIFSwipeDirection.left)
        tester().swipeView(withAccessibilityLabel: "Intro Tour Carousel", in: KIFSwipeDirection.left)

        tester().tapView(withAccessibilityLabel: "Sign in to Firefox")
        tester().waitForView(withAccessibilityLabel: "Web content")
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForAnimationsToFinish()
    }

    func testTapSigninShowsFxAFromSettings() {
        // Navigation to the settings to select the signin option
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Sign In to Firefox")
        tester().waitForView(withAccessibilityLabel: "Web content")

        // Go back to the home screen
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Done")
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

    func testToggleBetweenMobileAndDesktopSiteFromMenu() {
        // Load URL and ensure that we are on the mobile site initially
        loadURL("\(webRoot)/numberedPage.html?page=1", webViewElementAccessibilityLabel: "Page 1")
        ensureMobileSiteFromMenu()

        // Request desktop site and ensure that we get it
        requestDesktopSiteFromMenu("Page 1")
        ensureDesktopSiteFromMenu()

        // Request mobile site and ensure that we get it
        requestMobileSiteFromMenu("Page 1")
        ensureMobileSiteFromMenu()
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
        tester().tapView(withAccessibilityLabel: "Back")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")
        ensureMobileSite()

        // Navigate forward and ensure that we are on the desktop site again
        tester().tapView(withAccessibilityLabel: "Forward")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")
        ensureDesktopSite()
    }

    fileprivate func loadURL(_ url: String, webViewElementAccessibilityLabel: String? = nil) {
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: url + "\n")
        if let label = webViewElementAccessibilityLabel {
            tester().waitForWebViewElementWithAccessibilityLabel(label)
        } else {
            tester().wait(forTimeInterval: 5)
        }
    }

    fileprivate func reload(_ webViewElementAccessibilityLabel: String) {
        tester().tapView(withAccessibilityLabel: "Reload")
        tester().waitForWebViewElementWithAccessibilityLabel(webViewElementAccessibilityLabel)
    }

    fileprivate func ensureMobileSite() {
        tester().longPressView(withAccessibilityLabel: "Reload", duration: 1)
        tester().waitForView(withAccessibilityLabel: "Request Desktop Site")
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Request Desktop Site")
    }
    
    fileprivate func ensureDesktopSite() {
        tester().longPressView(withAccessibilityLabel: "Reload", duration: 1)
        tester().waitForView(withAccessibilityLabel: "Request Mobile Site")
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "Request Mobile Site")
    }

    fileprivate func requestMobileSite(_ webViewElementAccessibilityLabel: String) {
        tester().longPressView(withAccessibilityLabel: "Reload", duration: 1)
        tester().waitForView(withAccessibilityLabel: "Request Mobile Site")
        tester().tapView(withAccessibilityLabel: "Request Mobile Site")
        tester().waitForWebViewElementWithAccessibilityLabel(webViewElementAccessibilityLabel)
    }

    fileprivate func requestDesktopSite(_ webViewElementAccessibilityLabel: String) {
        tester().longPressView(withAccessibilityLabel: "Reload", duration: 1)
        tester().waitForView(withAccessibilityLabel: "Request Desktop Site")
        tester().tapView(withAccessibilityLabel: "Request Desktop Site")
        tester().waitForWebViewElementWithAccessibilityLabel(webViewElementAccessibilityLabel)
    }

    fileprivate func requestDesktopSiteFromMenu(_ webViewElementAccessibilityLabel: String) {
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().waitForView(withAccessibilityLabel: "Request Desktop Site")
        tester().tapView(withAccessibilityLabel: "Request Desktop Site")
        tester().waitForWebViewElementWithAccessibilityLabel(webViewElementAccessibilityLabel)
    }

    fileprivate func requestMobileSiteFromMenu(_ webViewElementAccessibilityLabel: String) {
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().waitForView(withAccessibilityLabel: "Request Mobile Site")
        tester().tapView(withAccessibilityLabel: "Request Mobile Site")
        tester().waitForWebViewElementWithAccessibilityLabel(webViewElementAccessibilityLabel)
    }

    fileprivate func ensureMobileSiteFromMenu() {
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().waitForView(withAccessibilityLabel: "Request Desktop Site")
        tester().tapView(withAccessibilityLabel: "Close Menu")
    }

    fileprivate func ensureDesktopSiteFromMenu() {
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().waitForView(withAccessibilityLabel: "Request Mobile Site")
        tester().tapView(withAccessibilityLabel: "Close Menu")
    }

    override func tearDown() {
        super.tearDown()
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }
}
