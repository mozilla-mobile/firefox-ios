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
        BrowserUtils.dismissFirstRunUI()
    }
    
    override func tearDown() {
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
        super.tearDown()
    }
    
    func enterUrl(url: String) {
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_replaceText(url))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_typeText("\n"))
    }
    
    func testAppStoreLinkShowsConfirmation() {
        let url = "\(webRoot!)/navigationDelegate.html"
        enterUrl(url: url)
        tester().tapWebViewElementWithAccessibilityLabel("link")
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("CancelOpenInAppStore")).perform(grey_tap())
    }
}
