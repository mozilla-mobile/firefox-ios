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
        tester().tapViewWithAccessibilityLabel("Sign In")
        tester().waitForViewWithAccessibilityLabel("Web content")

        // Go back to the home screen
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")
    }

    func testToggleBetweenMobileAndDesktopSite() {
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(webRoot)/numberedPage.html?page=1\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Initially the mobile site should be loaded with an offer to request the desktop site
        tester().longPressViewWithAccessibilityLabel("Reload", duration: 1)
        tester().waitForViewWithAccessibilityLabel("Request Desktop Site")

        // Request desktop site
        tester().tapViewWithAccessibilityLabel("Request Desktop Site")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // After requesting the desktop site we should offer to request the mobile site
        tester().longPressViewWithAccessibilityLabel("Reload", duration: 1)
        tester().waitForViewWithAccessibilityLabel("Request Mobile Site")

        // Request mobile site
        tester().tapViewWithAccessibilityLabel("Request Mobile Site")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // After requesting the mobile site we should offer to request the desktop site again
        tester().longPressViewWithAccessibilityLabel("Reload", duration: 1)
        tester().waitForViewWithAccessibilityLabel("Request Desktop Site")

        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    func testNewNavigationLoadsMobileSite() {
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(webRoot)/numberedPage.html?page=1\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Initially the mobile site should be loaded with an offer to request the desktop site
        tester().longPressViewWithAccessibilityLabel("Reload", duration: 1)
        tester().waitForViewWithAccessibilityLabel("Request Desktop Site")

        // Request desktop site
        tester().tapViewWithAccessibilityLabel("Request Desktop Site")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // After requesting the desktop site we should offer to request the mobile site
        tester().longPressViewWithAccessibilityLabel("Reload", duration: 1)
        tester().waitForViewWithAccessibilityLabel("Request Mobile Site")

        // Navigate to different URL
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().tapViewWithAccessibilityIdentifier("url")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(webRoot)/numberedPage.html?page=2\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")

        // The new navigation should load the mobile site with an offer to request the desktop site
        tester().longPressViewWithAccessibilityLabel("Reload", duration: 1)
        tester().waitForViewWithAccessibilityLabel("Request Desktop Site")

        tester().tapViewWithAccessibilityLabel("Cancel")
    }

    override func tearDown() {
        BrowserUtils.clearHistoryItems(tester(), numberOfTests: 5)
    }
}
