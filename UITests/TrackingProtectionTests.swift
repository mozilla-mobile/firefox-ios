/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import EarlGrey
@testable import Client

func checkIfImageLoaded(url: String, shouldBlockImage: Bool) {
    BrowserUtils.enterUrlAddressBar(typeUrl: url)

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
    var stats = TPPageStats()
    var statsIncrement: XCTestExpectation?
    var statsZero: XCTestExpectation?

    override func setUp() {
        super.setUp()

        // IP addresses can't be used for allowlisted domains
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
        ContentBlocker.shared.clearSafelist() { clear.fulfill() }
        waitForExpectations(timeout: 2, handler: nil)

        register(self, forTabEvents: .didChangeContentBlocking)
    }

    func tabDidChangeContentBlocking(_ tab: Tab) {
        stats = tab.contentBlocker!.stats

        if (stats.total == 0) {
            statsZero?.fulfill()
            statsZero = nil
        } else {
            statsIncrement?.fulfill()
            statsIncrement = nil
        }
    }

    private func checkStrictTrackingProtection(isBlocking: Bool, isTPDisabled: Bool = false) {
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
        if BrowserUtils.iPad() {
            EarlGrey.selectElement(with: grey_accessibilityID("TabToolbar.menuButton")).perform(grey_tap())
        } else {
            EarlGrey.selectElement(with: grey_accessibilityLabel("Menu")).perform(grey_tap())
        }
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

    func enableStrictMode() {
        openTPSetting()
        EarlGrey.selectElement(with: grey_accessibilityID("prefkey.trackingprotection.normalbrowsing")).perform(grey_turnSwitchOn(true))
        // Lets enable Strict mode to block the image this is fixed:
        // https://github.com/mozilla-mobile/firefox-ios/pull/5274#issuecomment-516111508
        EarlGrey.selectElement(with: grey_accessibilityID("Settings.TrackingProtectionOption.BlockListStrict")).perform(grey_tap())

        // Accept the warning alert when Strict mode is enabled
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "OK, Got It")
        closeTPSetting()
    }

    func testStrictTrackingProtection() {
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

        checkStrictTrackingProtection(isBlocking: false, isTPDisabled: true)

        enableStrictMode()

        // Now with the TP enabled, the image should be blocked
        checkStrictTrackingProtection(isBlocking: true)
        openTPSetting()
        disableStrictTP()
        closeTPSetting()
    }

    func disableStrictTP() {
        EarlGrey.selectElement(with: grey_accessibilityID("Settings.TrackingProtectionOption.BlockListBasic")).perform(grey_tap())
    }

    func testSafelist() {
        // Enable strict mode
        enableStrictMode()

        let url = URL(string: "http://localhost")!

        let clear = self.expectation(description: "clearing")
        ContentBlocker.shared.clearSafelist() { clear.fulfill() }
        waitForExpectations(timeout: 10, handler: nil)
        checkStrictTrackingProtection(isBlocking: true)

        let expSafelist = self.expectation(description: "safelisted")
        ContentBlocker.shared.safelist(enable: true, url: url) { expSafelist.fulfill() }
        waitForExpectations(timeout: 10, handler: nil)
        // The image from ymail.com would normally be blocked, but in this case it is safelisted
        checkStrictTrackingProtection(isBlocking: false)

        let expRemove = self.expectation(description: "safelist removed")
        ContentBlocker.shared.safelist(enable: false,  url: url) { expRemove.fulfill() }
        waitForExpectations(timeout: 10, handler: nil)
        checkStrictTrackingProtection(isBlocking: true)

        let expSafelistAgain = self.expectation(description: "safelisted")
        ContentBlocker.shared.safelist(enable: true, url: url) { expSafelistAgain.fulfill() }
        waitForExpectations(timeout: 10, handler: nil)
        // The image from ymail.com would normally be blocked, but in this case it is safelisted
        checkStrictTrackingProtection(isBlocking: false)

        let clear1 = self.expectation(description: "clearing")
        ContentBlocker.shared.clearSafelist() { clear1.fulfill() }
        waitForExpectations(timeout: 10, handler: nil)
        checkStrictTrackingProtection(isBlocking: true)
    }
}
