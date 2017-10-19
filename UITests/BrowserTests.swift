/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import EarlGrey
@testable import Client

class BrowserTests: KIFTestCase {
    
    private var webRoot: String!
    
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

    // Disabled with https://bugzilla.mozilla.org/show_bug.cgi?id=1409851
    func testDisplaySharesheetWhileJSPromptOccurs() {
        let url = "\(webRoot!)/JSPrompt.html"
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_replaceText(url))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_typeText("\n"))
        tester().waitForWebViewElementWithAccessibilityLabel("JS Prompt")
        //EarlGrey.select(elementWithMatcher: grey_kindOfClass(NSClassFromString("_UIAlertControllerInterfaceActionGroupView")!))
        //    .assert(grey_sufficientlyVisible())
        
        // Show share sheet and wait for the JS prompt to fire
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Share")).perform(grey_tap())
        
        if BrowserUtils.iPad() {
            // iPad does not have cancel btn to close dialog
            EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Share")).perform(grey_tap())
        } else {
            let matcher = grey_allOf([grey_accessibilityLabel("Cancel"),
                                      grey_accessibilityTrait(UIAccessibilityTraitButton),
                                      grey_sufficientlyVisible()])
            EarlGrey.select(elementWithMatcher: matcher).perform(grey_tap())
        }
        
        // Check to see if the JS Prompt is dequeued and showing
        tester().waitForView(withAccessibilityLabel: "OK")
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("OK"))
            .inRoot(grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!))
            .assert(grey_enabled())
            .perform((grey_tap()))
    }
}
