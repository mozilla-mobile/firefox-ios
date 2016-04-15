/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
@testable import Client
import SwiftKeychainWrapper
import Shared

class AuthenticationManagerTests: KIFTestCase {

    override func tearDown() {
        super.tearDown()
        resetPasscode()
    }

    private func openAuthenticationManager() {
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")

        do {
            try tester().tryFindingViewWithAccessibilityLabel("Touch ID & Passcode")
            tester().tapViewWithAccessibilityLabel("Touch ID & Passcode")
        } catch {
            tester().tapViewWithAccessibilityLabel("Passcode")
        }
    }

    private func closeAuthenticationManager() {
        tester().tapViewWithAccessibilityLabel("Back")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    private func resetPasscode() {
        KeychainWrapper.setAuthenticationInfo(nil)
    }

    private func setPasscode(code: String, interval: PasscodeInterval) {
        let info = AuthenticationKeychainInfo(passcode: code)
        info.updateRequiredPasscodeInterval(interval)
        KeychainWrapper.setAuthenticationInfo(info)
    }

    private func enterPasscodeWithDigits(digits: String) {
        tester().tapViewWithAccessibilityLabel(String(digits.characters[digits.startIndex]))
        tester().tapViewWithAccessibilityLabel(String(digits.characters[digits.startIndex.advancedBy(1)]))
        tester().tapViewWithAccessibilityLabel(String(digits.characters[digits.startIndex.advancedBy(2)]))
        tester().tapViewWithAccessibilityLabel(String(digits.characters[digits.startIndex.advancedBy(3)]))
    }

    private func waitForPasscodeLabel() {
        do {
            try tester().tryFindingViewWithAccessibilityLabel("Passcode")
            tester().waitForViewWithAccessibilityLabel("Passcode")
        } catch {
            tester().waitForViewWithAccessibilityLabel("Touch ID & Passcode")
        }
    }

    func testTurnOnPasscodeSetsPasscodeAndInterval() {
        resetPasscode()

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Turn Passcode On")
        tester().waitForViewWithAccessibilityLabel("Enter a passcode")
        enterPasscodeWithDigits("1337")
        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")
        enterPasscodeWithDigits("1337")
        waitForPasscodeLabel()

        let info = KeychainWrapper.authenticationInfo()!
        XCTAssertEqual(info.passcode!, "1337")
        XCTAssertEqual(info.requiredPasscodeInterval, .Immediately)

        closeAuthenticationManager()
    }

    func testTurnOffPasscode() {
        setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Turn Passcode Off")
        tester().waitForViewWithAccessibilityLabel("Enter passcode")
        enterPasscodeWithDigits("1337")
        waitForPasscodeLabel()
        XCTAssertNil(KeychainWrapper.authenticationInfo())

        closeAuthenticationManager()
    }

    func testChangePasscode() {
        setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Change Passcode")
        tester().waitForViewWithAccessibilityLabel("Enter passcode")
        enterPasscodeWithDigits("1337")
        tester().waitForViewWithAccessibilityLabel("Enter a new passcode")
        enterPasscodeWithDigits("2337")
        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")
        enterPasscodeWithDigits("2337")
        waitForPasscodeLabel()

        let info = KeychainWrapper.authenticationInfo()!
        XCTAssertEqual(info.passcode!, "2337")

        closeAuthenticationManager()
    }

    func testChangePasscodeShowsErrorStates() {
        setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Change Passcode")
        tester().waitForViewWithAccessibilityLabel("Enter passcode")

        // Enter wrong passcode
        enterPasscodeWithDigits("2337")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))

        enterPasscodeWithDigits("2337")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 1))

        enterPasscodeWithDigits("1337")
        tester().waitForViewWithAccessibilityLabel("Enter a new passcode")

        // Enter same passcode
        enterPasscodeWithDigits("1337")
        tester().waitForViewWithAccessibilityLabel("New passcode must be different than existing code.")

        enterPasscodeWithDigits("2337")
        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")

        // Enter mismatched passcode
        enterPasscodeWithDigits("3337")
        tester().waitForViewWithAccessibilityLabel("Passcodes didn't match. Try again.")

        enterPasscodeWithDigits("2337")
        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")

        enterPasscodeWithDigits("2337")

        let info = KeychainWrapper.authenticationInfo()!
        XCTAssertEqual(info.passcode!, "2337")

        closeAuthenticationManager()
    }

    func testChangeRequirePasscodeInterval() {
        setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Require Passcode, Immediately")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        enterPasscodeWithDigits("1337")

        let tableView = tester().waitForViewWithAccessibilityIdentifier("AuthenticationManager.passcodeIntervalTableView") as! UITableView
        var immediatelyCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))!
        var oneHourCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 5, inSection: 0))!

        XCTAssertEqual(immediatelyCell.accessoryType, UITableViewCellAccessoryType.Checkmark)
        XCTAssertEqual(oneHourCell.accessoryType, UITableViewCellAccessoryType.None)

        tester().tapRowAtIndexPath(NSIndexPath(forRow: 5, inSection: 0), inTableViewWithAccessibilityIdentifier: "AuthenticationManager.passcodeIntervalTableView")
        immediatelyCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0))!
        oneHourCell = tableView.cellForRowAtIndexPath(NSIndexPath(forRow: 5, inSection: 0))!

        XCTAssertEqual(immediatelyCell.accessoryType, UITableViewCellAccessoryType.None)
        XCTAssertEqual(oneHourCell.accessoryType, UITableViewCellAccessoryType.Checkmark)

        let info = KeychainWrapper.authenticationInfo()!
        XCTAssertEqual(info.requiredPasscodeInterval!, PasscodeInterval.OneHour)

        tester().tapViewWithAccessibilityLabel("Back")

        let settingsTableView = tester().waitForViewWithAccessibilityIdentifier("AuthenticationManager.settingsTableView") as! UITableView
        let requirePasscodeCell = settingsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1))!
        XCTAssertEqual(requirePasscodeCell.detailTextLabel!.text, PasscodeInterval.OneHour.settingTitle)

        closeAuthenticationManager()
    }

    func testEnteringLoginsUsingPasscode() {
        setPasscode("1337", interval: .Immediately)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        enterPasscodeWithDigits("1337")
        tester().waitForViewWithAccessibilityIdentifier("Login List")

        tester().tapViewWithAccessibilityLabel("Back")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testEnteringLoginsUsingPasscodeWithImmediateInterval() {
        setPasscode("1337", interval: .Immediately)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        enterPasscodeWithDigits("1337")
        tester().waitForViewWithAccessibilityIdentifier("Login List")
        tester().tapViewWithAccessibilityLabel("Back")

        // Trying again should display passcode screen since we've set the interval to be immediately.
        tester().tapViewWithAccessibilityLabel("Logins")
        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testEnteringLoginsUsingPasscodeWithFiveMinutesInterval() {
        setPasscode("1337", interval: .FiveMinutes)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        enterPasscodeWithDigits("1337")
        tester().waitForViewWithAccessibilityIdentifier("Login List")
        tester().tapViewWithAccessibilityLabel("Back")

        // Trying again should not display the passcode screen since the interval is 5 minutes
        tester().tapViewWithAccessibilityLabel("Logins")
        tester().waitForViewWithAccessibilityIdentifier("Login List")
        tester().tapViewWithAccessibilityLabel("Back")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testEnteringLoginsWithNoPasscode() {
        XCTAssertNil(KeychainWrapper.authenticationInfo())

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")
        tester().waitForViewWithAccessibilityIdentifier("Login List")

        tester().tapViewWithAccessibilityLabel("Back")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testWrongPasscodeDisplaysAttemptsAndMaxError() {
        setPasscode("1337", interval: .FiveMinutes)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")

        // Enter wrong passcode
        enterPasscodeWithDigits("1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))
        enterPasscodeWithDigits("1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 1))
        enterPasscodeWithDigits("1234")
        tester().waitForViewWithAccessibilityLabel(AuthenticationStrings.maximumAttemptsReachedNoTime)

        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testWrongPasscodeAttemptsPersistAcrossEntryAndConfirmation() {
        setPasscode("1337", interval: .FiveMinutes)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")

        // Enter wrong passcode
        enterPasscodeWithDigits("1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))

        tester().tapViewWithAccessibilityLabel("Cancel")

        do {
            try tester().tryFindingViewWithAccessibilityLabel("Passcode")
            tester().tapViewWithAccessibilityLabel("Passcode")
        } catch {
            tester().tapViewWithAccessibilityLabel("Touch ID & Passcode")
        }
        tester().tapViewWithAccessibilityLabel("Turn Passcode Off")

        // Enter wrong passcode, again
        enterPasscodeWithDigits("1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 1))
        tester().tapViewWithAccessibilityLabel("Cancel")
        closeAuthenticationManager()
    }

    func testChangedPasswordMustBeNew() {
        setPasscode("1337", interval: .FiveMinutes)
        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Change Passcode")

        tester().waitForViewWithAccessibilityLabel("Enter passcode")
        enterPasscodeWithDigits("1337")

        tester().waitForViewWithAccessibilityLabel("Enter a new passcode")
        enterPasscodeWithDigits("1337")

        // Should display error and take us back to first pane
        tester().waitForViewWithAccessibilityLabel("New passcode must be different than existing code.")
        tester().waitForViewWithAccessibilityLabel("Enter passcode")

        tester().tapViewWithAccessibilityLabel("Cancel")
        closeAuthenticationManager()
    }

    func testPasscodesMustMatchWhenCreating() {
        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Turn Passcode On")

        tester().waitForViewWithAccessibilityLabel("Enter a passcode")
        enterPasscodeWithDigits("1337")

        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")
        enterPasscodeWithDigits("1234")

        // Should display error and take us back to first pane
        tester().waitForViewWithAccessibilityLabel("Passcodes didn't match. Try again.")
        tester().waitForViewWithAccessibilityLabel("Enter a passcode")

        tester().tapViewWithAccessibilityLabel("Cancel")
        closeAuthenticationManager()
    }

    func testPasscodeMustBeCorrectWhenRemoving() {
        setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Turn Passcode Off")

        tester().waitForViewWithAccessibilityLabel("Enter passcode")
        enterPasscodeWithDigits("2337")

        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))

        enterPasscodeWithDigits("1337")

        closeAuthenticationManager()
    }
}
