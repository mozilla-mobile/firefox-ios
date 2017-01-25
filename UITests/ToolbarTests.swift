/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import UIKit

class ToolbarTests: KIFTestCase, UITextFieldDelegate {
    fileprivate var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    /**
     * Tests landscape page navigation enablement with the URL bar with tab switching.
     */
    func testLandscapeNavigationWithTabSwitch() {
        let previousOrientation = UIDevice.current.value(forKey: "orientation") as! Int

        // Rotate to landscape.
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")

        tester().tapView(withAccessibilityIdentifier: "url")
        let textView = tester().waitForView(withAccessibilityLabel: "Address and Search") as! UITextField
        XCTAssertTrue(textView.text!.isEmpty, "Text is empty")
        XCTAssertNotNil(textView.placeholder, "Text view has a placeholder to show when it's empty")

        // Navigate to two pages and press back once so that all buttons are enabled in landscape mode.
        let url1 = "\(webRoot)/numberedPage.html?page=1"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url1)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        tester().tapView(withAccessibilityIdentifier: "url")
        let textView2 = tester().waitForView(withAccessibilityLabel: "Address and Search") as! UITextField
        XCTAssertEqual(textView2.text, url1, "Text is url")

        let url2 = "\(webRoot)/numberedPage.html?page=2"
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "\(url2)\n")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 2")

        tester().tapView(withAccessibilityLabel: "Back")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Open new tab and then go back to previous tab to test navigation buttons.
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "New Tab")
        tester().waitForView(withAccessibilityLabel: "Web content")

        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Page 1")
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        // Test to see if all the buttons are enabled then close tab.
        tester().waitForTappableView(withAccessibilityLabel: "Back")
        tester().waitForTappableView(withAccessibilityLabel: "Forward")
        tester().waitForTappableView(withAccessibilityLabel: "Reload")
        tester().waitForTappableView(withAccessibilityLabel: "Share")
        tester().waitForTappableView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().swipeView(withAccessibilityLabel: "Page 1", in: KIFSwipeDirection.left)

        // Go Back to other tab to see if all buttons are disabled.
        tester().tapView(withAccessibilityLabel: "home")
        tester().waitForView(withAccessibilityLabel: "Web content")

        let back = tester().waitForView(withAccessibilityLabel: "Back") as! UIButton
        let forward = tester().waitForView(withAccessibilityLabel: "Forward") as! UIButton
        let reload = tester().waitForView(withAccessibilityLabel: "Reload") as! UIButton
        let share = tester().waitForView(withAccessibilityLabel: "Share") as! UIButton
        let menu = tester().waitForView(withAccessibilityLabel: "Menu") as! UIButton
        
        XCTAssertFalse(back.isEnabled, "Back button should be disabled")
        XCTAssertFalse(forward.isEnabled, "Forward button should be disabled")
        XCTAssertFalse(reload.isEnabled, "Reload button should be disabled")
        XCTAssertFalse(share.isEnabled, "Share button should be disabled")
        XCTAssertTrue(menu.isEnabled, "Menu button should be enabled")

        // Rotates back to previous orientation
        UIDevice.current.setValue(previousOrientation, forKey: "orientation")
    }

    func testURLEntry() {
        let textField = tester().waitForView(withAccessibilityIdentifier: "url") as! UITextField
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().enterText(intoCurrentFirstResponder: "foobar")
        tester().tapView(withAccessibilityLabel: "Cancel")
        XCTAssertEqual(textField.text, "", "Verify that the URL bar text clears on about:home")

        // 127.0.0.1 doesn't cause http:// to be hidden. localhost does. Both will work.
        let localhostURL = webRoot.replacingOccurrences(of: "127.0.0.1", with: "localhost", options: NSString.CompareOptions(), range: nil)
        let url = "\(localhostURL)/numberedPage.html?page=1"

        // URL without "http://".
        let displayURL = "\(localhostURL)/numberedPage.html?page=1".substring(from: url.characters.index(url.startIndex, offsetBy: "http://".characters.count))

        tester().tapView(withAccessibilityIdentifier: "url")
        tester().enterText(intoCurrentFirstResponder: "\(url)\n")
        XCTAssertEqual(textField.text, displayURL, "URL matches page URL")

        tester().tapView(withAccessibilityIdentifier: "url")
        tester().enterText(intoCurrentFirstResponder: "foobar")
        tester().tapView(withAccessibilityLabel: "Cancel")
        XCTAssertEqual(textField.text, displayURL, "Verify that text reverts to page URL after entering text")

        tester().tapView(withAccessibilityIdentifier: "url")
        tester().clearTextFromFirstResponder()
        tester().tapView(withAccessibilityLabel: "Cancel")
        XCTAssertEqual(textField.text, displayURL, "Verify that text reverts to page URL after clearing text")
    }

    func testClearURLTextUsingBackspace() {
        // 127.0.0.1 doesn't cause http:// to be hidden. localhost does. Both will work.
        let localhostURL = webRoot.replacingOccurrences(of: "127.0.0.1", with: "localhost", options: NSString.CompareOptions(), range: nil)
        let url = "\(localhostURL)/numberedPage.html?page=1"

        _ = tester().waitForView(withAccessibilityIdentifier: "url") as! UITextField
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().enterText(intoCurrentFirstResponder: url+"\n")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().waitForKeyInputReady()
        tester().enterText(intoCurrentFirstResponder: "\u{8}")

        let autocompleteField = tester().waitForView(withAccessibilityIdentifier: "address") as! UITextField
        XCTAssertEqual(autocompleteField.text, "", "Verify that backspace keypress deletes text when url is highlighted")
    }

    func testUserInfoRemovedFromURL() {
        let hostWithUsername = webRoot.replacingOccurrences(of: "127.0.0.1", with: "username:password@127.0.0.1", options: NSString.CompareOptions(), range: nil)
        let urlWithUserInfo = "\(hostWithUsername)/numberedPage.html?page=1"
        let url = "\(webRoot)/numberedPage.html?page=1"

        _ = tester().waitForView(withAccessibilityIdentifier: "url") as! UITextField
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().enterText(intoCurrentFirstResponder: urlWithUserInfo+"\n")
        tester().waitForAnimationsToFinish()

        let urlField = tester().waitForView(withAccessibilityIdentifier: "url") as! UITextField
        XCTAssertEqual(urlField.text, url)
    }

    override func tearDown() {
        let previousOrientation = UIDevice.current.value(forKey: "orientation") as! Int
        if previousOrientation == UIInterfaceOrientation.landscapeLeft.rawValue {
            // Rotate back to portrait
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
        
    }
}
