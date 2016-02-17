/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
@testable import Client
import SwiftKeychainWrapper

class AuthenticationManagerTests: KIFTestCase {

    private func openAuthenticationManager() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Touch ID & Passcode")
    }

    private func closeAuthenticationManager() {
        tester().tapViewWithAccessibilityLabel("Back")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")
    }

    private func resetPasscode() {
        KeychainWrapper.removeObjectForKey(KeychainKeyPasscode)
    }

    private func setPasscode(code: String) {
        KeychainWrapper.setString(code, forKey: KeychainKeyPasscode)
    }

    func testTurnOnPasscodeSetsPasscode() {
        resetPasscode()

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Turn Passcode On")
        tester().waitForViewWithAccessibilityLabel("Enter a passcode")

        // Enter a passcode
        tester().tapViewWithAccessibilityLabel("1")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("7")

        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")

        // Enter same passcode when confirming
        tester().tapViewWithAccessibilityLabel("1")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("7")

        tester().waitForViewWithAccessibilityLabel("Touch ID & Passcode")

        XCTAssertEqual(KeychainWrapper.stringForKey(KeychainKeyPasscode)!, "1337")

        closeAuthenticationManager()
        resetPasscode()
    }

    func testTurnOffPasscode() {
        setPasscode("1337")

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Turn Passcode Off")
        tester().waitForViewWithAccessibilityLabel("Enter a passcode")

        // Enter a passcode
        tester().tapViewWithAccessibilityLabel("1")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("7")

        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")

        // Enter same passcode when confirming
        tester().tapViewWithAccessibilityLabel("1")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("7")

        tester().waitForViewWithAccessibilityLabel("Touch ID & Passcode")
        XCTAssertNil(KeychainWrapper.stringForKey(KeychainKeyPasscode))

        closeAuthenticationManager()
    }

    func testChangePasscode() {
        setPasscode("1337")

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Change Passcode")
        tester().waitForViewWithAccessibilityLabel("Enter a passcode")

        // Enter a passcode
        tester().tapViewWithAccessibilityLabel("1")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("7")

        tester().waitForViewWithAccessibilityLabel("Enter a new passcode")

        // Enter same passcode when confirming
        tester().tapViewWithAccessibilityLabel("2")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("3")
        tester().tapViewWithAccessibilityLabel("7")

        tester().waitForViewWithAccessibilityLabel("Touch ID & Passcode")
        XCTAssertEqual(KeychainWrapper.stringForKey(KeychainKeyPasscode), "2337")

        closeAuthenticationManager()
    }
}