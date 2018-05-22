/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import EarlGrey
@testable import Client

// WKWebView's WKNavigationDelegate is used for custom URL handling
// such as telephone links, app store links, etc.

class NavigationDelegateTests: KIFTestCase {
    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.configEarlGrey()
        BrowserUtils.dismissFirstRunUI()
    }
    
    override func tearDown() {
        BrowserUtils.resetToAboutHome()
        BrowserUtils.clearPrivateData()
        super.tearDown()
    }
    
    func enterUrl(url: String) {
        EarlGrey.selectElement(with: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.selectElement(with: grey_accessibilityID("address")).perform(grey_replaceText(url))
        EarlGrey.selectElement(with: grey_accessibilityID("address")).perform(grey_typeText("\n"))
    }
    
    func testAppStoreLinkShowsConfirmation() {
        let url = "\(webRoot!)/navigationDelegate.html"
        enterUrl(url: url)
        tester().waitForAnimationsToFinish()
        tester().waitForWebViewElementWithAccessibilityLabel("link")
        tester().tapWebViewElementWithAccessibilityLabel("link")
        tester().wait(forTimeInterval: 2)
        EarlGrey.selectElement(with: grey_accessibilityID("CancelOpenInAppStore")).perform(grey_tap())
    }
}
