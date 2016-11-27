/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class HomePageSettingsUITests: KIFTestCase {

    private var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        UIPasteboard.generalPasteboard().string = " "
        BrowserUtils.dismissFirstRunUI(tester())
    }

    override func tearDown() {
        super.tearDown()
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }    

    func testNavigation() {
        HomePageUtils.navigateToHomePageSettings(tester())
        // if we can't find the home paget text view, then this will time out.
        tester().tapViewWithAccessibilityIdentifier("HomePageSetting")
        HomePageUtils.navigateFromHomePageSettings(tester())
    }

    func testTyping() {
        HomePageUtils.navigateToHomePageSettings(tester())
        tester().tapViewWithAccessibilityIdentifier("ClearHomePage")
        XCTAssertEqual("", HomePageUtils.homePageSetting(tester()))

        tester().tapViewWithAccessibilityIdentifier("HomePageSetting")

        let webPageString = "http://www.mozilla.com/typing"
        tester().enterTextIntoCurrentFirstResponder(webPageString)
        XCTAssertEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        // check if it's saved
        HomePageUtils.navigateFromHomePageSettings(tester())
        HomePageUtils.navigateToHomePageSettings(tester())
        XCTAssertEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        // teardown.
        tester().tapViewWithAccessibilityIdentifier("ClearHomePage")
        HomePageUtils.navigateFromHomePageSettings(tester())
    }

    func testTypingBadURL() {
        HomePageUtils.navigateToHomePageSettings(tester())
        tester().tapViewWithAccessibilityIdentifier("ClearHomePage")
        XCTAssertEqual("", HomePageUtils.homePageSetting(tester()))

        tester().tapViewWithAccessibilityIdentifier("HomePageSetting")

        let webPageString = "not a webpage"
        tester().enterTextIntoCurrentFirstResponder(webPageString)
        XCTAssertEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        // check if it's saved
        HomePageUtils.navigateFromHomePageSettings(tester())
        HomePageUtils.navigateToHomePageSettings(tester())
        XCTAssertNotEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        // teardown.
        tester().tapViewWithAccessibilityIdentifier("ClearHomePage")
        HomePageUtils.navigateFromHomePageSettings(tester())
    }

    // This test will fail on simulator
    func testCurrentPage() {
        let webPageString = "\(webRoot)/numberedPage.html?page=1"
        tester().tapViewWithAccessibilityIdentifier("url")

        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("\(webPageString)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // now go to settings.
        //HomePageUtils.navigateToHomePageSettings(tester())
        tester().waitForAnimationsToFinish()
        tester().tapViewWithAccessibilityLabel("Menu")
        
        // Below call is only needed for the emulator. In emulator, it does not see the settings in the next page
        tester().swipeViewWithAccessibilityLabel("Set Homepage", inDirection:KIFSwipeDirection.Left)
        
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityIdentifier("HomePageSetting")
        tester().tapViewWithAccessibilityIdentifier("ClearHomePage")
        XCTAssertEqual("", HomePageUtils.homePageSetting(tester()))

        tester().tapViewWithAccessibilityIdentifier("UseCurrentTab")
        XCTAssertEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        tester().tapViewWithAccessibilityIdentifier("ClearHomePage")
        HomePageUtils.navigateFromHomePageSettings(tester())
        BrowserUtils.resetToAboutHome(tester())
    }

    func testClipboard() {
        let webPageString = "https://www.mozilla.org/clipboard"
        UIPasteboard.generalPasteboard().string = webPageString
        HomePageUtils.navigateToHomePageSettings(tester())

        tester().tapViewWithAccessibilityIdentifier("UseCopiedLink")
        XCTAssertEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        tester().tapViewWithAccessibilityIdentifier("ClearHomePage")
        XCTAssertEqual("", HomePageUtils.homePageSetting(tester()))
        HomePageUtils.navigateFromHomePageSettings(tester())
    }


    func testDisabledClipboard() {
        let webPageString = "not a url"
        UIPasteboard.generalPasteboard().string = webPageString
        HomePageUtils.navigateToHomePageSettings(tester())

        tester().tapViewWithAccessibilityIdentifier("UseCopiedLink")
        XCTAssertNotEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        tester().tapViewWithAccessibilityIdentifier("ClearHomePage")
        XCTAssertEqual("", HomePageUtils.homePageSetting(tester()))
        HomePageUtils.navigateFromHomePageSettings(tester())
    }


}
