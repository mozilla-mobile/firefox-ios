/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import EarlGrey
@testable import Client

class ReopenLastTabTests: KIFTestCase {
    
    private var webRoot: String!
    
    var closeButtonMatchers: [GREYMatcher] {
        return [
            grey_accessibilityID("TabTrayController.deleteButton.closeAll"),
            grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!)
        ]
    }
    
    var reopenButtonMatchers: [GREYMatcher] {
        return [
            grey_accessibilityID("BrowserViewController.ReopenLastTabAlert.ReopenButton"),
            grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!)
        ]
    }
    
    override func setUp() {
        super.setUp()
        webRoot = SimplePageServer.start()
        BrowserUtils.dismissFirstRunUI()
    }
    
    
    func testReopenLastTab() {
        openReadablePage()
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")
        
        openTabsController()
        closeAllTabs()
        EarlGrey.shakeDevice()
        
        reopenLastPage()
        tester().waitForWebViewElementWithAccessibilityLabel("Readable Page")

    }
    
    func openReadablePage() {
        let url = "\(webRoot!)/readablePage.html"
        EarlGrey.selectElement(with: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.selectElement(with: grey_accessibilityID("address")).perform(grey_replaceText(url))
        EarlGrey.selectElement(with: grey_accessibilityID("address")).perform(grey_typeText("\n"))
    }
    
    func openTabsController() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            EarlGrey
                .selectElement(with: grey_accessibilityID("TopTabsViewController.tabsButton"))
                .perform(grey_tap())
        } else {
            EarlGrey
                .selectElement(with: grey_accessibilityID("TabToolbar.tabsButton"))
                .perform(grey_tap())
        }
    }
    
    func closeAllTabs() {
        EarlGrey.selectElement(with: grey_accessibilityID("TabTrayController.removeTabsButton")).perform(grey_tap())
        EarlGrey.selectElement(with: grey_allOf(closeButtonMatchers)).perform(grey_tap())
    }
    
    func reopenLastPage() {
        EarlGrey.selectElement(with: grey_allOf(reopenButtonMatchers)).perform(grey_tap())
    }
}
