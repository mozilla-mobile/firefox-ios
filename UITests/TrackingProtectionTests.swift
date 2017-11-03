/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import EarlGrey
@testable import Client

class TrackingProtectionTests: KIFTestCase {
    
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

    private func checkTrackingProtection(isBlocking: Bool) {
        let url = "\(webRoot!)/tracking-protection-test.html"
        TrackingProtectionTests.checkIfImageLoaded(url: url, shouldBlockImage: isBlocking)
    }

    public static func checkIfImageLoaded(url: String, shouldBlockImage: Bool) {
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("url")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_replaceText(url))
        EarlGrey.select(elementWithMatcher: grey_accessibilityID("address")).perform(grey_typeText("\n"))
        
        let dialogAppeared = GREYCondition(name: "Wait for JS dialog") {
            var errorOrNil: NSError?
            EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("OK"))
                .inRoot(grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!))
                .assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil == nil
            return success
        }
        let success = dialogAppeared?.wait(withTimeout: 10)
        GREYAssertTrue(success!, reason: "Failed to display JS dialog")
        
        if shouldBlockImage {
            EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("image not loaded."))
                .assert(grey_notNil())
        } else {
            EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("image loaded."))
            .assert(grey_notNil())
        }
        
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("OK"))
            .inRoot(grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!))
            .assert(grey_enabled())
            .perform((grey_tap()))
    }
    
    func openTPSetting() {
        // Check tracking protection is enabled on private tabs only in Settings
        let menuAppeared = GREYCondition(name: "Wait for the Settings dialog to appear") {
            var errorOrNil: NSError?
            EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Logins")).assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil == nil
            return success
        }
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Menu")).perform(grey_tap())
        EarlGrey.select(elementWithMatcher: grey_text("Settings")).perform(grey_tap())
        let success = menuAppeared?.wait(withTimeout: 20)
        GREYAssertTrue(success!, reason: "Failed to display settings dialog")
        
        // Scroll to Tracking Protection Menu
        EarlGrey.select(elementWithMatcher:grey_accessibilityLabel("Tracking Protection"))
            .using(searchAction: grey_scrollInDirection(GREYDirection.down, 200),
                   onElementWithMatcher: grey_kindOfClass(UITableView.self))
            .assert(grey_notNil())
            .perform(grey_tap())
    }
    
    func closeTPSetting() {
        // Exit to main view
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Done")
    }
    
    func testNormalTrackingProtection() {
        
        openTPSetting()
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Private Browsing Mode Only")).perform(grey_tap())
        closeTPSetting()

        if BrowserUtils.iPad() {
        EarlGrey.select(elementWithMatcher:grey_accessibilityID("TopTabsViewController.tabsButton"))
                .perform(grey_tap())
        } else {
            EarlGrey.select(elementWithMatcher:grey_accessibilityID("TabToolbar.tabsButton"))
                .perform(grey_tap())
        }
        EarlGrey.select(elementWithMatcher:grey_accessibilityID("TabTrayController.addTabButton"))
            .perform(grey_tap())

        checkTrackingProtection(isBlocking: false)

        openTPSetting()
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Always On")).perform(grey_tap())
        closeTPSetting()

        // Now with the TP enabled, the image should be blocked
        checkTrackingProtection(isBlocking: true)
        openTPSetting()
        EarlGrey.select(elementWithMatcher: grey_accessibilityLabel("Private Browsing Mode Only")).perform(grey_tap())
        closeTPSetting()
    }
    
    func testPrivateTabPageTrackingProtection() {
        if BrowserUtils.iPad() {
            EarlGrey.select(elementWithMatcher:
                grey_accessibilityID("TopTabsViewController.tabsButton"))
                .perform(grey_tap())
        } else {
            EarlGrey.select(elementWithMatcher:grey_accessibilityID("TabToolbar.tabsButton"))
                .perform(grey_tap())
        }
        EarlGrey.select(elementWithMatcher:grey_accessibilityID("TabTrayController.maskButton"))
            .perform(grey_tap())
        EarlGrey.select(elementWithMatcher:grey_accessibilityID("TabTrayController.addTabButton"))
            .perform(grey_tap())

        checkTrackingProtection(isBlocking: true)
    }
}
