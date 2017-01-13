/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
@testable import Client
import SwiftKeychainWrapper
import Shared

class AuthenticationManagerTests: KIFTestCase {

    override func setUp() {
        super.setUp()
        BrowserUtils.dismissFirstRunUI(tester())
    }
    
    override func tearDown() {
        super.tearDown()
        PasscodeUtils.resetPasscode()
        BrowserUtils.resetToAboutHome(tester())
        BrowserUtils.clearPrivateData(tester: tester())
    }

    fileprivate func openAuthenticationManager() {
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")

        do {
            try tester().tryFindingView(withAccessibilityLabel: "Touch ID & Passcode")
            tester().tapView(withAccessibilityLabel: "Touch ID & Passcode")
        } catch {
            tester().tapView(withAccessibilityLabel: "Passcode")
        }
    }

    fileprivate func closeAuthenticationManager() {
        tester().tapView(withAccessibilityLabel: "Back")
        tester().tapView(withAccessibilityLabel: "Done")
    }

    func testTurnOnPasscodeSetsPasscodeAndInterval() {
        PasscodeUtils.resetPasscode()

        openAuthenticationManager()
        tester().tapView(withAccessibilityLabel: "Turn Passcode On")
        tester().waitForView(withAccessibilityLabel: "Enter a passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForView(withAccessibilityLabel: "Re-enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForView(withAccessibilityLabel: "Turn Passcode Off")

        let info = KeychainWrapper.defaultKeychainWrapper().authenticationInfo()!
        XCTAssertEqual(info.passcode!, "1337")
        XCTAssertEqual(info.requiredPasscodeInterval, .Immediately)

        closeAuthenticationManager()
    }

    func testTurnOffPasscode() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapView(withAccessibilityLabel: "Turn Passcode Off")
        tester().waitForView(withAccessibilityLabel: "Enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForView(withAccessibilityLabel: "Turn Passcode On")
        XCTAssertNil(KeychainWrapper.defaultKeychainWrapper().authenticationInfo())

        closeAuthenticationManager()
    }

    func testChangePasscode() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapView(withAccessibilityLabel: "Change Passcode")
        tester().waitForView(withAccessibilityLabel: "Enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForView(withAccessibilityLabel: "Enter a new passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tester().waitForView(withAccessibilityLabel: "Re-enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tester().waitForView(withAccessibilityLabel: "Change Passcode")

        let info = KeychainWrapper.defaultKeychainWrapper().authenticationInfo()!
        XCTAssertEqual(info.passcode!, "2337")

        closeAuthenticationManager()
    }

    func testChangePasscodeShowsErrorStates() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapView(withAccessibilityLabel: "Change Passcode")
        tester().waitForView(withAccessibilityLabel: "Enter passcode")

        // Enter wrong passcode
        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))

        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 1))

        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForView(withAccessibilityLabel: "Enter a new passcode")

        // Enter same passcode
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForView(withAccessibilityLabel: "New passcode must be different than existing code.")

        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tester().waitForView(withAccessibilityLabel: "Re-enter passcode")

        // Enter mismatched passcode
        PasscodeUtils.enterPasscode(tester(), digits: "3337")
        tester().waitForView(withAccessibilityLabel: "Passcodes didn't match. Try again.")

        PasscodeUtils.enterPasscode(tester(), digits: "2337")
        tester().waitForView(withAccessibilityLabel: "Re-enter passcode")

        PasscodeUtils.enterPasscode(tester(), digits: "2337")

        let info = KeychainWrapper.defaultKeychainWrapper().authenticationInfo()!
        XCTAssertEqual(info.passcode!, "2337")

        closeAuthenticationManager()
    }

    func testChangeRequirePasscodeInterval() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapView(withAccessibilityLabel: "Require Passcode, Immediately")

        tester().waitForView(withAccessibilityLabel: "Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForAnimationsToFinish()

        let tableView = tester().waitForView(withAccessibilityIdentifier: "AuthenticationManager.passcodeIntervalTableView") as! UITableView
        var immediatelyCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))!
        var oneHourCell = tableView.cellForRow(at: IndexPath(row: 5, section: 0))!

        XCTAssertEqual(immediatelyCell.accessoryType, UITableViewCellAccessoryType.checkmark)
        XCTAssertEqual(oneHourCell.accessoryType, UITableViewCellAccessoryType.none)

        tester().tapRow(at: IndexPath(row: 5, section: 0), inTableViewWithAccessibilityIdentifier: "AuthenticationManager.passcodeIntervalTableView")
        immediatelyCell = tableView.cellForRow(at: IndexPath(row: 0, section: 0))!
        oneHourCell = tableView.cellForRow(at: IndexPath(row: 5, section: 0))!

        XCTAssertEqual(immediatelyCell.accessoryType, UITableViewCellAccessoryType.none)
        XCTAssertEqual(oneHourCell.accessoryType, UITableViewCellAccessoryType.checkmark)

        let info = KeychainWrapper.defaultKeychainWrapper().authenticationInfo()!
        XCTAssertEqual(info.requiredPasscodeInterval!, PasscodeInterval.OneHour)

        tester().tapView(withAccessibilityLabel: "Back")

        let settingsTableView = tester().waitForView(withAccessibilityIdentifier: "AuthenticationManager.settingsTableView") as! UITableView
        let requirePasscodeCell = settingsTableView.cellForRow(at: IndexPath(row: 0, section: 1))!
        XCTAssertEqual(requirePasscodeCell.detailTextLabel!.text, PasscodeInterval.OneHour.settingTitle)

        closeAuthenticationManager()
    }

    func testEnteringLoginsUsingPasscode() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Logins")

        tester().waitForView(withAccessibilityLabel: "Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForView(withAccessibilityIdentifier: "Login List")

        tester().tapView(withAccessibilityLabel: "Back")
        tester().tapView(withAccessibilityLabel: "Done")
    }

    func testEnteringLoginsUsingPasscodeWithImmediateInterval() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Logins")

        tester().waitForView(withAccessibilityLabel: "Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForView(withAccessibilityIdentifier: "Login List")
        tester().tapView(withAccessibilityLabel: "Back")

        // Trying again should display passcode screen since we've set the interval to be immediately.
        tester().waitForView(withAccessibilityLabel: "Logins")
        tester().tapView(withAccessibilityLabel: "Logins")
        tester().waitForView(withAccessibilityLabel: "Enter Passcode")
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().tapView(withAccessibilityLabel: "Done")
    }

    func testEnteringLoginsUsingPasscodeWithFiveMinutesInterval() {
        PasscodeUtils.setPasscode("1337", interval: .FiveMinutes)

        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Logins")

        tester().waitForView(withAccessibilityLabel: "Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForView(withAccessibilityIdentifier: "Login List")
        tester().tapView(withAccessibilityLabel: "Back")

        // Trying again should not display the passcode screen since the interval is 5 minutes
        tester().tapView(withAccessibilityLabel: "Logins")
        tester().waitForView(withAccessibilityIdentifier: "Login List")
        tester().tapView(withAccessibilityLabel: "Back")
        tester().tapView(withAccessibilityLabel: "Done")
    }

    func testEnteringLoginsWithNoPasscode() {
        XCTAssertNil(KeychainWrapper.defaultKeychainWrapper().authenticationInfo())

        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Logins")
        tester().waitForView(withAccessibilityIdentifier: "Login List")

        tester().tapView(withAccessibilityLabel: "Back")
        tester().tapView(withAccessibilityLabel: "Done")
    }

    func testWrongPasscodeDisplaysAttemptsAndMaxError() {
        PasscodeUtils.setPasscode("1337", interval: .FiveMinutes)

        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Logins")

        tester().waitForView(withAccessibilityLabel: "Enter Passcode")

        // Enter wrong passcode
        PasscodeUtils.enterPasscode(tester(), digits: "1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))
        PasscodeUtils.enterPasscode(tester(), digits: "1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 1))
        PasscodeUtils.enterPasscode(tester(), digits: "1234")
        tester().waitForViewWithAccessibilityLabel(AuthenticationStrings.maximumAttemptsReachedNoTime)

        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().tapView(withAccessibilityLabel: "Done")
    }

    func testWrongPasscodeAttemptsPersistAcrossEntryAndConfirmation() {
        PasscodeUtils.setPasscode("1337", interval: .FiveMinutes)

        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Logins")

        tester().waitForView(withAccessibilityLabel: "Enter Passcode")

        // Enter wrong passcode
        PasscodeUtils.enterPasscode(tester(), digits: "1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))

        tester().tapView(withAccessibilityLabel: "Cancel")

        do {
            try tester().tryFindingView(withAccessibilityLabel: "Passcode")
            tester().tapView(withAccessibilityLabel: "Passcode")
        } catch {
            tester().tapView(withAccessibilityLabel: "Touch ID & Passcode")
        }
        tester().tapView(withAccessibilityLabel: "Turn Passcode Off")

        // Enter wrong passcode, again
        PasscodeUtils.enterPasscode(tester(), digits: "1234")
        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 1))
        tester().tapView(withAccessibilityLabel: "Cancel")
        closeAuthenticationManager()
    }

    func testChangedPasswordMustBeNew() {
        PasscodeUtils.setPasscode("1337", interval: .FiveMinutes)
        openAuthenticationManager()
        tester().tapView(withAccessibilityLabel: "Change Passcode")

        tester().waitForView(withAccessibilityLabel: "Enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")

        tester().waitForView(withAccessibilityLabel: "Enter a new passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")

        // Should display error and take us back to first pane
        tester().waitForView(withAccessibilityLabel: "New passcode must be different than existing code.")
        tester().waitForView(withAccessibilityLabel: "Enter passcode")

        tester().tapView(withAccessibilityLabel: "Cancel")
        closeAuthenticationManager()
    }

    func testPasscodesMustMatchWhenCreating() {
        openAuthenticationManager()
        tester().tapView(withAccessibilityLabel: "Turn Passcode On")

        tester().waitForView(withAccessibilityLabel: "Enter a passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")

        tester().waitForView(withAccessibilityLabel: "Re-enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1234")

        // Should display error and take us back to first pane
        tester().waitForView(withAccessibilityLabel: "Passcodes didn't match. Try again.")
        tester().waitForView(withAccessibilityLabel: "Enter a passcode")

        tester().tapView(withAccessibilityLabel: "Cancel")
        closeAuthenticationManager()
    }

    func testPasscodeMustBeCorrectWhenRemoving() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapView(withAccessibilityLabel: "Turn Passcode Off")

        tester().waitForView(withAccessibilityLabel: "Enter passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "2337")

        tester().waitForViewWithAccessibilityLabel(String(format: AuthenticationStrings.incorrectAttemptsRemaining, 2))

        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForView(withAccessibilityLabel: "Turn Passcode On")

        closeAuthenticationManager()
    }

    func testChangingIntervalResetsValidationTimer() {
        PasscodeUtils.setPasscode("1337", interval: .Immediately)

        // Navigate to logins and input our passcode
        tester().tapView(withAccessibilityLabel: "Show Tabs")
        tester().tapView(withAccessibilityLabel: "Menu")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Logins")
        tester().waitForView(withAccessibilityLabel: "Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForView(withAccessibilityLabel: "Logins")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Done")
        openAuthenticationManager()
        
        // Change the require interval of the passcode
        tester().tapView(withAccessibilityLabel: "Require Passcode, Immediately")

        tester().waitForView(withAccessibilityLabel: "Enter Passcode")
        PasscodeUtils.enterPasscode(tester(), digits: "1337")
        tester().waitForAnimationsToFinish()

        tester().tapRow(at: IndexPath(row: 5, section: 0), inTableViewWithAccessibilityIdentifier: "AuthenticationManager.passcodeIntervalTableView")

        // Go back to logins and make sure it asks us for the passcode again
        tester().tapView(withAccessibilityLabel: "Back")
        tester().tapView(withAccessibilityLabel: "Settings")
        tester().tapView(withAccessibilityLabel: "Logins")
        tester().waitForView(withAccessibilityLabel: "Enter Passcode")
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().tapView(withAccessibilityLabel: "Done")
    }
}
