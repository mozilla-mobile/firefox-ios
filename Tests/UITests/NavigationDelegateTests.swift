// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
@testable import Client

// WKWebView's WKNavigationDelegate is used for custom URL handling
// such as telephone links, app store links, etc.

class NavigationDelegateTests: KIFTestCase {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI(tester())
    }

    override func tearDown() {
        BrowserUtils.resetToAboutHomeKIF(tester())
        tester().wait(forTimeInterval: 3)
        BrowserUtils.clearPrivateDataKIF(tester())
        super.tearDown()
    }

    func testAppStoreLinkShowsConfirmation() {
        let url = "\(webRoot!)/navigationDelegate.html"
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        tester().waitForAnimationsToFinish(withTimeout: 3)
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)
        tester().waitForAnimationsToFinish()
        tester().waitForWebViewElementWithAccessibilityLabel("link")
        tester().tapWebViewElementWithAccessibilityLabel("link")
        tester().wait(forTimeInterval: 2)
        tester().tapView(withAccessibilityIdentifier: "CancelOpenInAppStore")
    }
}
