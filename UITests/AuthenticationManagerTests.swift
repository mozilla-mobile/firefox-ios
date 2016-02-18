/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
@testable import Client
import SwiftKeychainWrapper
import Shared

class AuthenticationManagerTests: KIFTestCase {
    var prefs: Prefs!

    override func setUp() {
        super.setUp()
        self.prefs = (UIApplication.sharedApplication().delegate as! AppDelegate).profile!.prefs
    }

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
        prefs.removeObjectForKey(PrefKeyRequirePasscodeInterval)
    }

    private func setPasscode(code: String, interval: PasscodeInterval) {
        KeychainWrapper.setString(code, forKey: KeychainKeyPasscode)
        prefs.setInt(interval.rawValue, forKey: PrefKeyRequirePasscodeInterval)
    }

    func testTurnOnPasscodeSetsPasscodeAndInterval() {
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
        XCTAssertNotNil(prefs.intForKey(PrefKeyRequirePasscodeInterval))
        XCTAssertEqual(prefs.intForKey(PrefKeyRequirePasscodeInterval), 0)

        closeAuthenticationManager()
        resetPasscode()
    }

    func testTurnOffPasscode() {
        setPasscode("1337", interval: .Immediately)

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
        XCTAssertNil(prefs.intForKey(PrefKeyRequirePasscodeInterval))

        closeAuthenticationManager()
    }

    func testChangePasscode() {
        setPasscode("1337", interval: .Immediately)

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

    func testChangeRequirePasscodeInterval() {
        setPasscode("1337", interval: .Immediately)

        openAuthenticationManager()
        tester().tapViewWithAccessibilityLabel("Require Passcode, Immediately")

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

        XCTAssertEqual(prefs.intForKey(PrefKeyRequirePasscodeInterval), PasscodeInterval.OneHour.rawValue)

        tester().tapViewWithAccessibilityLabel("Back")

        let settingsTableView = tester().waitForViewWithAccessibilityIdentifier("AuthenticationManager.settingsTableView") as! UITableView
        let requirePasscodeCell = settingsTableView.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 1))!
        XCTAssertEqual(requirePasscodeCell.detailTextLabel!.text, PasscodeInterval.OneHour.settingTitle)

        closeAuthenticationManager()
    }
}