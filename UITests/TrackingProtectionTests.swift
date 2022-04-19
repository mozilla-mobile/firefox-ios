// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Storage
@testable import Client
import KIF


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
        BrowserUtils.dismissFirstRunUI(tester())

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
        waitForExpectations(timeout: 15, handler: nil)

        register(self, forTabEvents: .didChangeContentBlocking)
    }
    
    func checkIfImageLoaded(url: String, shouldBlockImage: Bool) {
        tester().waitForAnimationsToFinish(withTimeout: 3)
        BrowserUtils.enterUrlAddressBar(tester(), typeUrl: url)

        tester().waitForAnimationsToFinish(withTimeout: 3)

            if shouldBlockImage {
                tester().waitForView(withAccessibilityLabel: "image not loaded.")
            } else {
                tester().waitForView(withAccessibilityLabel: "image loaded.")

            }
        tester().tapView(withAccessibilityLabel: "OK")
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
        tester().waitForAnimationsToFinish()
        // Check tracking protection is enabled on private tabs only in Settings

        if BrowserUtils.iPad() {
            tester().tapView(withAccessibilityIdentifier: AccessibilityIdentifiers.Toolbar.settingsMenuButton)
        } else {
            tester().tapView(withAccessibilityLabel: "Menu")
        }
        tester().tapView(withAccessibilityLabel: "Settings")

        tester().accessibilityScroll(.down)
        tester().tapView(withAccessibilityLabel: "Tracking Protection")
    }

    func closeTPSetting() {
        // Exit to main view
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Done")
    }

    func enableStrictMode() {
        openTPSetting()
        tester().tapView(withAccessibilityIdentifier: "prefkey.trackingprotection.normalbrowsing")
        // Lets enable Strict mode to block the image this is fixed:
        // https://github.com/mozilla-mobile/firefox-ios/pull/5274#issuecomment-516111508

        tester().tapView(withAccessibilityIdentifier: "Settings.TrackingProtectionOption.BlockListStrict")

        // Accept the warning alert when Strict mode is enabled
        tester().waitForAnimationsToFinish(withTimeout: 3)
        tester().tapView(withAccessibilityLabel: "OK, Got It")
        closeTPSetting()
    }

    func testStrictTrackingProtection() {
        openTPSetting()
        tester().tapView(withAccessibilityIdentifier: "prefkey.trackingprotection.normalbrowsing")
        closeTPSetting()

        if BrowserUtils.iPad() {
            tester().tapView(withAccessibilityIdentifier: "TopTabsViewController.tabsButton")
        } else {
            tester().tapView(withAccessibilityIdentifier: "TabToolbar.tabsButton")
        }

        tester().tapView(withAccessibilityIdentifier: "newTabButtonTabTray")
        tester().tapView(withAccessibilityIdentifier: "urlBar-cancel")
        checkStrictTrackingProtection(isBlocking: false, isTPDisabled: true)
        enableStrictMode()

        // Now with the TP enabled, the image should be blocked
        checkStrictTrackingProtection(isBlocking: true)
        openTPSetting()
        disableStrictTP()
        closeTPSetting()
    }

    func disableStrictTP() {
        tester().tapView(withAccessibilityIdentifier: "Settings.TrackingProtectionOption.BlockListBasic")
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
        openTPSetting()
        disableStrictTP()
        closeTPSetting()
    }
}
