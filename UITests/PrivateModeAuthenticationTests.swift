/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import SwiftKeychainWrapper
@testable import Client

class PrivateModeAuthenticationTests: KIFTestCase {

    private static let passcode = "0000"

    override func tearDown() {
        super.tearDown()
        PasscodeUtils.resetPasscode()
        BrowserUtils.resetToAboutHome(tester())
    }

    private func getBrowserViewController() -> BrowserViewController {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).browserViewController
    }

    private func enablePasscodeAuthentication() {
        PasscodeUtils.setPasscode(PrivateModeAuthenticationTests.passcode, interval: .Immediately)
    }

    private func checkBrowsingMode(isPrivate isPrivate: Bool) {
        let bvc = getBrowserViewController()
        tester().waitForAnimationsToFinish()
        XCTAssert(isPrivate ? bvc.tabManager.isInPrivateMode : !bvc.tabManager.isInPrivateMode)
    }

    private func enterCorrectPasscode() {
        checkBrowsingMode(isPrivate: false)
        PasscodeUtils.enterPasscode(tester(), digits: PrivateModeAuthenticationTests.passcode)
        checkBrowsingMode(isPrivate: true)
    }

    func testPasscodeAuthenticationFromTabTray() {
        enablePasscodeAuthentication()
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        checkBrowsingMode(isPrivate: false)
        tester().tapViewWithAccessibilityLabel("Private Mode")
        enterCorrectPasscode()
        tester().tapViewWithAccessibilityLabel("Private Mode")
        checkBrowsingMode(isPrivate: false)
    }

    func testPasscodeAuthenticationFromTopTabs() {
        let bvc = getBrowserViewController()
        guard bvc.shouldShowTopTabsForTraitCollection(bvc.traitCollection) else {
            return
        }
        enablePasscodeAuthentication()
        checkBrowsingMode(isPrivate: false)
        tester().tapViewWithAccessibilityLabel("Private Tab")
        enterCorrectPasscode()
        tester().tapViewWithAccessibilityLabel("Private Tab")
        checkBrowsingMode(isPrivate: false)
    }

    func testPasscodeAuthenticationForNewPrivateTab() {
        enablePasscodeAuthentication()
        checkBrowsingMode(isPrivate: false)
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Private Tab")
        enterCorrectPasscode()
    }
    
    func testPasscodeAuthenticationForNewPrivateTabFromTabTray() {
        enablePasscodeAuthentication()
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        checkBrowsingMode(isPrivate: false)
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("New Private Tab")
        enterCorrectPasscode()
    }
}
