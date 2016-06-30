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

        do {
            try tester().tryFindingViewWithAccessibilityLabel("Search or enter address")
        } catch {
            closeAuthenticationManager()
        }
        PasscodeUtils.resetPasscode()
    }

    private func openAuthenticationManager() {
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")

        tapTouchIDAndPasscode()
    }

    func tapTouchIDAndPasscode() {
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

    func testTurnOnPasscodeSetsPasscodeAndInterval() {
        PasscodeUtils.resetPasscode()

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Turn Passcode On")
        tester().waitForViewWithAccessibilityLabel("Enter a passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tapTouchIDAndPasscode()

        let info = KeychainWrapper.authenticationInfo()!
        XCTAssertEqual(info.passcode!, "1337")
        XCTAssertEqual(info.requiredPasscodeInterval, .Immediately)

        closeAuthenticationManager()
    }

    func testTurnOffPasscode() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Turn Passcode Off")
        tester().waitForViewWithAccessibilityLabel("Enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tapTouchIDAndPasscode()
        XCTAssertNil(KeychainWrapper.authenticationInfo())

        closeAuthenticationManager()
    }

    func testChangePasscode() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Change Passcode")
        tester().waitForViewWithAccessibilityLabel("Enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForViewWithAccessibilityLabel("Enter a new passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tapTouchIDAndPasscode()

        let info = KeychainWrapper.authenticationInfo()!
        XCTAssertEqual(info.passcode!, "2337")

        closeAuthenticationManager()
    }

    func testChangePasscodeShowsErrorStates() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Change Passcode")
        tester().waitForViewWithAccessibilityLabel("Enter passcode")

        // Enter wrong passcode
        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))

        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 1))

        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForViewWithAccessibilityLabel("Enter a new passcode")

        // Enter same passcode
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForViewWithAccessibilityLabel("New passcode must be different than existing code.")

        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")

        // Enter mismatched passcode
        PasscodeUtils.enterPasscode(tester(), digits: "3337")
        tester().waitForViewWithAccessibilityLabel("Passcodes didn't match. Try again.")

        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")

        PasscodeUtils.enterPasscode(tester(), digits: "2337")

        let info = KeychainWrapper.authenticationInfo()!
        XCTAssertEqual(info.passcode!, "2337")

        closeAuthenticationManager()
    }

    func testChangeRequirePasscodeInterval() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Require Passcode, Immediately")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForAnimationsToFinish()

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
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForViewWithAccessibilityIdentifier("Login List")

        tester().tapViewWithAccessibilityLabel("Back")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testEnteringLoginsUsingPasscodeWithImmediateInterval() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForViewWithAccessibilityIdentifier("Login List")
        tester().tapViewWithAccessibilityLabel("Back")

        // Trying again should display passcode screen since we've set the interval to be immediately.
        tester().tapViewWithAccessibilityLabel("Logins")
        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testEnteringLoginsUsingPasscodeWithFiveMinutesInterval() {
        PasscodeUtils.setPasscode("1337", interval: .FiveMinutes)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
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
        PasscodeUtils.setPasscode("1337", interval: .FiveMinutes)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")

        // Enter wrong passcode
        PasscodeUtils.enterPasscode(tester(), digits: "1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))
        PasscodeUtils.enterPasscode(tester(), digits: "1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 1))
        PasscodeUtils.enterPasscode(tester(), digits: "1234")
        tester().waitForViewWithAccessibilityLabel(AuthenticationStrings.maximumAttemptsReachedNoTime)

        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().tapViewWithAccessibilityLabel("Done")
    }

    func testWrongPasscodeAttemptsPersistAcrossEntryAndConfirmation() {
        PasscodeUtils.setPasscode("1337", interval: .FiveMinutes)

        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")

        // Enter wrong passcode
        PasscodeUtils.enterPasscode(tester(), digits: "1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))

        tester().tapViewWithAccessibilityLabel("Cancel")

        tapTouchIDAndPasscode()
        tester().tapViewWithAccessibilityLabel("Turn Passcode Off")

        // Enter wrong passcode, again
        PasscodeUtils.enterPasscode(tester(), digits: "1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 1))
        tester().tapViewWithAccessibilityLabel("Cancel")
        closeAuthenticationManager()
    }

    func testChangedPasswordMustBeNew() {
        PasscodeUtils.setPasscode("1337", interval: .FiveMinutes)
        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Change Passcode")

        tester().waitForViewWithAccessibilityLabel("Enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")

        tester().waitForViewWithAccessibilityLabel("Enter a new passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")

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
        PasscodeUtils.enterPasscode(tester(), digits: "1337")

        tester().waitForViewWithAccessibilityLabel("Re-enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1234")

        // Should display error and take us back to first pane
        tester().waitForViewWithAccessibilityLabel("Passcodes didn't match. Try again.")
        tester().waitForViewWithAccessibilityLabel("Enter a passcode")

        tester().tapViewWithAccessibilityLabel("Cancel")
        closeAuthenticationManager()
    }

    func testPasscodeMustBeCorrectWhenRemoving() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Turn Passcode Off")

        tester().waitForViewWithAccessibilityLabel("Enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "2337")

        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))

        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tapTouchIDAndPasscode()

        closeAuthenticationManager()
    }

    func testChangingIntervalResetsValidationTimer() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        // Navigate to logins and input our passcode
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Menu")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")
        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForViewWithAccessibilityLabel("Logins")
        tester().tapViewWithAccessibilityLabel("Settings")
        tapTouchIDAndPasscode()

        // Change the require interval of the passcode
        tester().tapViewWithAccessibilityLabel("Require Passcode, Immediately")

        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForAnimationsToFinish()

        tester().tapRowAtIndexPath(NSIndexPath(forRow: 5, inSection: 0), inTableViewWithAccessibilityIdentifier: "AuthenticationManager.passcodeIntervalTableView")

        // Go back to logins and make sure it asks us for the passcode again
        tester().tapViewWithAccessibilityLabel("Back")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")
        tester().waitForViewWithAccessibilityLabel("Enter Passcode")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")
    }
}
