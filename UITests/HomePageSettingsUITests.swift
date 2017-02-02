/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

class HomePageSettingsUITests: KIFTestCase {

    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        UIPasteboard.general.string = " "
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
        XCTAssertTrue(tester().viewExistsWithLabel("Homepage Settings"), "title should be visible")
        HomePageUtils.navigateFromHomePageSettings(tester())
    }

    func testTyping() {
        HomePageUtils.navigateToHomePageSettings(tester())
        tester().tapView(withAccessibilityIdentifier: "ClearHomePage")
        XCTAssertEqual("", HomePageUtils.homePageSetting(tester()))

        tester().tapView(withAccessibilityLabel: "Enter a webpage")

        let webPageString = "http://www.mozilla.com/typing"
        tester().enterText(intoCurrentFirstResponder: webPageString)
        XCTAssertEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        // check if it's saved
        HomePageUtils.navigateFromHomePageSettings(tester())
        HomePageUtils.navigateToHomePageSettings(tester())
        XCTAssertEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        // teardown.
        tester().tapView(withAccessibilityIdentifier: "ClearHomePage")
        HomePageUtils.navigateFromHomePageSettings(tester())
    }

    func testTypingBadURL() {
        HomePageUtils.navigateToHomePageSettings(tester())
        tester().tapView(withAccessibilityIdentifier: "ClearHomePage")
        XCTAssertEqual("", HomePageUtils.homePageSetting(tester()))

        tester().tapView(withAccessibilityLabel: "Enter a webpage")

        let webPageString = "not a webpage"
        tester().enterText(intoCurrentFirstResponder: webPageString)
        XCTAssertEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        // check if it's saved
        HomePageUtils.navigateFromHomePageSettings(tester())
        HomePageUtils.navigateToHomePageSettings(tester())
        XCTAssertNotEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        // teardown.
        tester().tapView(withAccessibilityIdentifier: "ClearHomePage")
        HomePageUtils.navigateFromHomePageSettings(tester())
    }

    func testClipboard() {
        let webPageString = "https://www.mozilla.org/clipboard"
        UIPasteboard.general.string = webPageString
        HomePageUtils.navigateToHomePageSettings(tester())

        tester().tapView(withAccessibilityIdentifier: "UseCopiedLink")
        XCTAssertEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        tester().tapView(withAccessibilityIdentifier: "ClearHomePage")
        XCTAssertEqual("", HomePageUtils.homePageSetting(tester()))
        HomePageUtils.navigateFromHomePageSettings(tester())
    }


    func testDisabledClipboard() {
        let webPageString = "not a url"
        UIPasteboard.general.string = webPageString
        HomePageUtils.navigateToHomePageSettings(tester())

        tester().tapView(withAccessibilityIdentifier: "UseCopiedLink")
        XCTAssertNotEqual(webPageString, HomePageUtils.homePageSetting(tester()))

        tester().tapView(withAccessibilityIdentifier: "ClearHomePage")
        XCTAssertEqual("", HomePageUtils.homePageSetting(tester()))
        HomePageUtils.navigateFromHomePageSettings(tester())
    }


}
