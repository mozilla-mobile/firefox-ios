// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import UIKit

class ToolbarTests: KIFTestCase, UITextFieldDelegate {
    fileprivate var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    func testURLEntry() {
        let textField = tester().waitForView(withAccessibilityIdentifier: "url") as! UITextField
        tester().tapView(withAccessibilityIdentifier: "url")
        tester().enterText(intoCurrentFirstResponder: "foobar")
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        XCTAssertNotEqual(textField.text, "foobar", "Verify that the URL bar text clears on about:home")

        // 127.0.0.1 doesn't cause http:// to be hidden. localhost does. Both will work.
        let localhostURL = webRoot.replacingOccurrences(of: "127.0.0.1", with: "localhost")
        let url = "\(localhostURL)/numberedPage.html?page=1"

        // URL without "http://".
        let displayURL = "\(localhostURL)/numberedPage.html?page=1".substring(from: url.index(url.startIndex, offsetBy: "http://".count))

        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)

        tester().waitForAnimationsToFinish()
        XCTAssertEqual(textField.text, displayURL, "URL matches page URL")

        tester().tapView(withAccessibilityIdentifier: "url")
        tester().enterText(intoCurrentFirstResponder: "foobar")
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        tester().waitForAnimationsToFinish()
        XCTAssertEqual(textField.text, displayURL, "Verify that text reverts to page URL after entering text")

        tester().tapView(withAccessibilityIdentifier: "url")
        tester().enterText(intoCurrentFirstResponder: " ")

        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        tester().waitForAnimationsToFinish()
        XCTAssertEqual(textField.text, displayURL, "Verify that text reverts to page URL after clearing text")
    }

    func testUserInfoRemovedFromURL() {
        let hostWithUsername = webRoot.replacingOccurrences(of: "127.0.0.1", with: "username:password@127.0.0.1")
        let urlWithUserInfo = "\(hostWithUsername)/numberedPage.html?page=1"
        let url = "\(webRoot!)/numberedPage.html?page=1"

        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: urlWithUserInfo)
        tester().waitForAnimationsToFinish()
        tester().waitForWebViewElementWithAccessibilityLabel("Page 1")

        let urlField = tester().waitForView(withAccessibilityIdentifier: "url") as! UITextField
        XCTAssertEqual("http://" + urlField.text!, url)
    }

    override func tearDown() {
        let previousOrientation = UIDevice.current.value(forKey: "orientation") as! Int
        if previousOrientation == UIInterfaceOrientation.landscapeLeft.rawValue {
            // Rotate back to portrait
            let value = UIInterfaceOrientation.portrait.rawValue
            UIDevice.current.setValue(value, forKey: "orientation")
        }
        BrowserUtils.resetToAboutHomeKIF(tester())
        tester().wait(forTimeInterval: 3)
        BrowserUtils.clearPrivateDataKIF(tester())
        super.tearDown()
    }
}
