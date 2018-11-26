/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import EarlGrey
@testable import Client

func checkIfImageLoaded(url: String, shouldBlockImage: Bool) {
    EarlGrey.selectElement(with: grey_accessibilityID("url")).perform(grey_tap())
    EarlGrey.selectElement(with: grey_accessibilityID("address")).perform(grey_replaceText(url))
    EarlGrey.selectElement(with: grey_accessibilityID("address")).perform(grey_typeText("\n"))

    let dialogAppeared = GREYCondition(name: "Wait for JS dialog") {
        var errorOrNil: NSError?
        EarlGrey.selectElement(with: grey_accessibilityLabel("OK"))
            .inRoot(grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!))
            .assert(grey_notNil(), error: &errorOrNil)
        let success = errorOrNil == nil
        return success
    }
    let success = dialogAppeared.wait(withTimeout: 10)
    GREYAssertTrue(success, reason: "Failed to display JS dialog")

    if shouldBlockImage {
        EarlGrey.selectElement(with: grey_accessibilityLabel("image not loaded."))
            .assert(grey_notNil())
    } else {
        EarlGrey.selectElement(with: grey_accessibilityLabel("image loaded."))
            .assert(grey_notNil())
    }

    EarlGrey.selectElement(with: grey_accessibilityLabel("OK"))
        .inRoot(grey_kindOfClass(NSClassFromString("_UIAlertControllerActionView")!))
        .assert(grey_enabled())
        .perform((grey_tap()))
}

class TrackingProtectionTests: KIFTestCase, TabEventHandler {

    private var webRoot: String!
    private var tabObservers: TabObservers!
    var stats = TPPageStats()
    var statsIncrement: XCTestExpectation?
    var statsZero: XCTestExpectation?

    override func setUp() {
        super.setUp()

        // IP addresses can't be used for whitelisted domains
        SimplePageServer.useLocalhostInsteadOfIP = true
        webRoot = SimplePageServer.start()
        BrowserUtils.configEarlGrey()
        BrowserUtils.dismissFirstRunUI()

        // Check TP is ready manually as NSPredicate-based expectation on a primitive type doesn't work.
        let setup = self.expectation(description: "setup")
        func checkIsSetup() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if ContentBlocker.shared.setupCompleted {
                    setup.fulfill()
                    return
                }
                checkIsSetup()
            }
        }
        checkIsSetup()
        wait(for: [setup], timeout: 5)

        let clear = self.expectation(description: "clearing")
        ContentBlocker.shared.clearWhitelist() { clear.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)

        NotificationCenter.default.addObserver(forName: .didChangeContentBlocking, object: nil, queue: nil) { arg in
            let tab = arg.userInfo!.first!.value as! Tab
            self.tabDidChangeContentBlockerStatus(tab)
        }
    }

    func tabDidChangeContentBlockerStatus(_ tab: Tab) {
        stats = tab.contentBlocker!.stats

        if (stats.total == 0) {
            statsZero?.fulfill()
        } else {
            statsIncrement?.fulfill()
        }
    }

    private func checkTrackingProtection(isBlocking: Bool, isTPDisabled: Bool = false) {
        if !isTPDisabled {
            if isBlocking {
                statsIncrement = expectation(description: "stats increment")
            } else {
                statsZero = expectation(description: "stats zero")
            }
        }

        let url = "\(webRoot!)/tracking-protection-test.html"
        checkIfImageLoaded(url: url, shouldBlockImage: isBlocking)

        if !isTPDisabled {
            waitForExpectations(timeout: 2, handler: nil)
        }

        statsIncrement = nil
        statsZero = nil
    }

    func openTPSetting() {
        // Check tracking protection is enabled on private tabs only in Settings
        let menuAppeared = GREYCondition(name: "Wait for the Settings dialog to appear") {
            var errorOrNil: NSError?
            EarlGrey.selectElement(with: grey_accessibilityLabel("Search")).assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil == nil
            return success
        }

        EarlGrey.selectElement(with: grey_accessibilityLabel("Menu")).perform(grey_tap())
        EarlGrey.selectElement(with: grey_text("Settings")).perform(grey_tap())

        let success = menuAppeared.wait(withTimeout: 20)
        GREYAssertTrue(success, reason: "Failed to display settings dialog")

        // Scroll to Tracking Protection Menu
        EarlGrey.selectElement(with:grey_accessibilityLabel("Tracking Protection"))
            .using(searchAction: grey_scrollInDirection(GREYDirection.down, 400),
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
        EarlGrey.selectElement(with: grey_accessibilityID("prefkey.trackingprotection.normalbrowsing")).perform(grey_turnSwitchOn(false))
        closeTPSetting()

        if BrowserUtils.iPad() {
        EarlGrey.selectElement(with:grey_accessibilityID("TopTabsViewController.tabsButton"))
                .perform(grey_tap())
        } else {
            EarlGrey.selectElement(with:grey_accessibilityID("TabToolbar.tabsButton"))
                .perform(grey_tap())
        }
        EarlGrey.selectElement(with:grey_accessibilityID("TabTrayController.addTabButton"))
            .perform(grey_tap())

        checkTrackingProtection(isBlocking: false, isTPDisabled: true)

        openTPSetting()
        EarlGrey.selectElement(with: grey_accessibilityID("prefkey.trackingprotection.normalbrowsing")).perform(grey_turnSwitchOn(true))
        closeTPSetting()

        // Now with the TP enabled, the image should be blocked
        checkTrackingProtection(isBlocking: true)
        openTPSetting()
        EarlGrey.selectElement(with: grey_accessibilityID("prefkey.trackingprotection.normalbrowsing")).perform(grey_turnSwitchOn(false))
        closeTPSetting()
    }

    func testWhitelist() {
        let url = URL(string: "http://localhost")!

        let clear = self.expectation(description: "clearing")
        ContentBlocker.shared.clearWhitelist() { clear.fulfill() }
        waitForExpectations(timeout: 10, handler: nil)
        checkTrackingProtection(isBlocking: true)

        let expWhitelist = self.expectation(description: "whitelisted")
        ContentBlocker.shared.whitelist(enable: true, url: url) { expWhitelist.fulfill() }
        waitForExpectations(timeout: 10, handler: nil)
        // The image from ymail.com would normally be blocked, but in this case it is whitelisted
        checkTrackingProtection(isBlocking: false)

        let expRemove = self.expectation(description: "whitelist removed")
        ContentBlocker.shared.whitelist(enable: false,  url: url) { expRemove.fulfill() }
        waitForExpectations(timeout: 10, handler: nil)
        checkTrackingProtection(isBlocking: true)

        let expWhitelistAgain = self.expectation(description: "whitelisted")
        ContentBlocker.shared.whitelist(enable: true, url: url) { expWhitelistAgain.fulfill() }
        waitForExpectations(timeout: 10, handler: nil)
        // The image from ymail.com would normally be blocked, but in this case it is whitelisted
        checkTrackingProtection(isBlocking: false)

        let clear1 = self.expectation(description: "clearing")
        ContentBlocker.shared.clearWhitelist() { clear1.fulfill() }
        waitForExpectations(timeout: 10, handler: nil)
        checkTrackingProtection(isBlocking: true)
    }

    func testPrivateTabPageTrackingProtection() {

        if BrowserUtils.iPad() {
            EarlGrey.selectElement(with:
                grey_accessibilityID("TopTabsViewController.tabsButton"))
                .perform(grey_tap())
        } else {
            EarlGrey.selectElement(with:grey_accessibilityID("TabToolbar.tabsButton"))
                .perform(grey_tap())
        }
        EarlGrey.selectElement(with:grey_accessibilityID("TabTrayController.maskButton"))
            .perform(grey_tap())
        EarlGrey.selectElement(with:grey_accessibilityID("TabTrayController.addTabButton"))
            .perform(grey_tap())

        checkTrackingProtection(isBlocking: true)
    }
}
