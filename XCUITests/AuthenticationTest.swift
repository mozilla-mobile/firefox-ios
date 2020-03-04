/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class AuthenticationTest: BaseTestCase {

    fileprivate func setInterval(_ interval: String = "Immediately") {
        navigator.goto(PasscodeIntervalSettings)
        let table = Base.app.tables["AuthenticationManager.settingsTableView"]
        Base.app.staticTexts[interval].tap()
        navigator.goto(PasscodeSettings)
        Base.helper.waitForExistence(table.staticTexts[interval])
    }

    func testTurnOnOff() {
        navigator.performAction(Action.SetPasscode)
        setInterval("Immediately")
        XCTAssertTrue(Base.app.staticTexts["Immediately"].exists)
        navigator.performAction(Action.DisablePasscode)
    }

    func testChangePassCode() {
        navigator.performAction(Action.SetPasscode)

        userState.newPasscode = "222222"
        navigator.performAction(Action.ChangePasscode)
        Base.helper.waitForExistence(Base.app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"])
        navigator.performAction(Action.DisablePasscode)
    }

    // Smoketest
    func testPromptPassCodeUponReentry() {
        navigator.performAction(Action.SetPasscode)
        navigator.goto(SettingsScreen)
        navigator.performAction(Action.UnlockLoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])

        //send app to background, and re-enter
        XCUIDevice.shared.press(.home)
        Base.app.activate()
        let contentView = Base.app.navigationBars["Client.FxAContentView"]
        if contentView.exists {
            Base.app.navigationBars["Client.FxAContentView"].buttons["Settings"].tap()
        }
        navigator.nowAt(SettingsScreen)
        navigator.goto(LockedLoginsSettings)
        Base.helper.waitForExistence(Base.app.navigationBars["Enter Passcode"])
    }

    func testPromptPassCodeUponReentryWithDelay() {
        navigator.performAction(Action.SetPasscode)
        setInterval("After 5 minutes")
        navigator.performAction(Action.UnlockLoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])

        // Send app to background, and re-enter
        XCUIDevice.shared.press(.home)
        Base.app.activate()
        let contentView = Base.app.navigationBars["Client.FxAContentView"]
        if contentView.exists {
            Base.app.navigationBars["Client.FxAContentView"].buttons["Settings"].tap()
        }
        navigator.nowAt(SettingsScreen)
        navigator.goto(LockedLoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])
    }

    func testChangePasscodeShowsErrorStates() {
        navigator.performAction(Action.SetPasscode)

        userState.passcode = "222222"
        navigator.performAction(Action.ConfirmPasscodeToChangePasscode)
        Base.helper.waitForExistence(Base.app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        navigator.performAction(Action.ConfirmPasscodeToChangePasscode)
        Base.helper.waitForExistence(Base.app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])

        userState.passcode = "111111"
        navigator.performAction(Action.ConfirmPasscodeToChangePasscode)
        Base.helper.waitForExistence(Base.app.staticTexts["Enter a new passcode"])

        // Enter same passcode as new one
        userState.newPasscode = "111111"
        navigator.performAction(Action.ChangePasscodeTypeOnce)
        Base.helper.waitForExistence(Base.app.staticTexts["New passcode must be different than existing code."])

        // Enter mismatched passcode
        userState.newPasscode = "444444"
        navigator.performAction(Action.ChangePasscodeTypeOnce)
        Base.helper.waitForExistence(Base.app.staticTexts["Re-enter passcode"])
        userState.newPasscode = "444445"
        navigator.performAction(Action.ChangePasscodeTypeOnce)
        Base.helper.waitForExistence(Base.app.staticTexts["Passcodes didn’t match. Try again."])

        // Put proper password
        userState.newPasscode = "555555"
        XCTAssertTrue(Base.app.staticTexts["Enter a new passcode"].exists)
        navigator.performAction(Action.ChangePasscodeTypeOnce)
        Base.helper.waitForExistence(Base.app.staticTexts["Re-enter passcode"])
        navigator.performAction(Action.ChangePasscodeTypeOnce)
        Base.helper.waitForExistence(Base.app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"])
    }

    func testChangeRequirePasscodeInterval() {
        navigator.performAction(Action.SetPasscode)
        navigator.goto(PasscodeIntervalSettings)

        Base.helper.waitForExistence(Base.app.staticTexts["Immediately"])
        XCTAssertTrue(Base.app.staticTexts["After 1 minute"].exists)
        XCTAssertTrue(Base.app.staticTexts["After 5 minutes"].exists)
        XCTAssertTrue(Base.app.staticTexts["After 10 minutes"].exists)
        XCTAssertTrue(Base.app.staticTexts["After 15 minutes"].exists)
        XCTAssertTrue(Base.app.staticTexts["After 1 hour"].exists)

        Base.app.staticTexts["After 15 minutes"].tap()
        navigator.goto(PasscodeSettings)
        let table = Base.app.tables["AuthenticationManager.settingsTableView"]
        Base.helper.waitForExistence(table.staticTexts["After 15 minutes"])

        // Since we set to 15 min, it shouldn't ask for password again, but it skips verification
        // only when timing isn't changed. (could be due to timer reset?)
        // For clarification, raised Bug 1325439
        navigator.goto(PasscodeIntervalSettings)
        navigator.goto(PasscodeSettings)
        Base.helper.waitForExistence(table.staticTexts["After 15 minutes"])
        navigator.performAction(Action.DisablePasscode)
    }

    func testEnteringLoginsUsingPasscode() {
        navigator.performAction(Action.SetPasscode)

        // Enter login
        navigator.performAction(Action.UnlockLoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])
        navigator.goto(SettingsScreen)
        // Trying again should display passcode screen since we've set the interval to be immediately.
        navigator.goto(LockedLoginsSettings)
        Base.helper.waitForExistence(Base.app.navigationBars["Enter Passcode"], timeout: 3)
        Base.app.buttons["Cancel"].tap()
        navigator.nowAt(SettingsScreen)
        navigator.goto(PasscodeSettings)
        navigator.performAction(Action.DisablePasscode)
    }

    func testEnteringLoginsUsingPasscodeWithFiveMinutesInterval() {
        navigator.performAction(Action.SetPasscode)
        setInterval("After 5 minutes")

        // Now we've changed the timeout, we should prompt next time for passcode.
        navigator.performAction(Action.UnlockLoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])

        // Trying again should not display the passcode screen since the interval is 5 minutes
        navigator.goto(SettingsScreen)
        navigator.goto(LockedLoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])

        navigator.goto(PasscodeSettings)
        Base.helper.waitForExistence(Base.app.staticTexts["After 5 minutes"])
        navigator.performAction(Action.DisablePasscode)
    }

    func testEnteringLoginsWithNoPasscode() {
        // It is disabled
        navigator.goto(PasscodeSettings)
        Base.helper.waitForExistence(Base.app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])

        navigator.goto(LoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])
    }

    func testWrongPasscodeDisplaysAttemptsAndMaxError() {
        navigator.performAction(Action.SetPasscode)
        setInterval("After 5 minutes")

        // Enter wrong passcode
        navigator.goto(LockedLoginsSettings)
        Base.helper.waitForExistence(Base.app.navigationBars["Enter Passcode"])

        navigator.performAction(Action.LoginPasscodeTypeIncorrectOne)
        Base.helper.waitForExistence(Base.app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        navigator.nowAt(LockedLoginsSettings)
        navigator.performAction(Action.LoginPasscodeTypeIncorrectOne)
        Base.helper.waitForExistence(Base.app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        navigator.nowAt(LockedLoginsSettings)
        navigator.performAction(Action.LoginPasscodeTypeIncorrectOne)
        Base.helper.waitForExistence(Base.app.staticTexts["Maximum attempts reached. Please try again later."])
    }

    func testWrongPasscodeAttemptsPersistAcrossEntryAndConfirmation() {
         navigator.performAction(Action.SetPasscode)

        // Enter wrong passcode on Logins
        navigator.goto(LockedLoginsSettings)
        Base.helper.waitForExistence(Base.app.navigationBars["Enter Passcode"])

        navigator.performAction(Action.LoginPasscodeTypeIncorrectOne)
        Base.helper.waitForExistence(Base.app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        Base.app.buttons["Cancel"].tap()

        // Go back to Passcode, and enter a wrong passcode, notice the error count
        navigator.goto(PasscodeSettings)
        userState.passcode = "222222"
        navigator.performAction(Action.ConfirmPasscodeToChangePasscode)

        Base.helper.waitForExistence(Base.app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        Base.app.buttons["Cancel"].tap()

        userState.passcode = "111111"
        navigator.nowAt(PasscodeSettings)
        navigator.performAction(Action.DisablePasscode)
        Base.helper.waitForExistence(Base.app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
    }

    func testChangedPasswordMustBeNew() {
        navigator.performAction(Action.SetPasscode)
        userState.newPasscode = "111111"

        navigator.performAction(Action.ChangePasscode)
        Base.helper.waitForExistence(Base.app.staticTexts["New passcode must be different than existing code."])
        Base.app.navigationBars["Change Passcode"].buttons["Cancel"].tap()

        navigator.performAction(Action.DisablePasscode)
        Base.helper.waitForExistence(Base.app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
    }

    func testPasscodesMustMatchWhenCreating() {
        navigator.performAction(Action.SetPasscodeTypeOnce)
        Base.helper.waitForExistence(Base.app.staticTexts["Re-enter passcode"])

        // Enter a passcode that does not match
        userState.newPasscode = "333333"
        navigator.performAction(Action.SetPasscodeTypeOnce)
        Base.helper.waitForExistence(Base.app.staticTexts["Passcodes didn’t match. Try again."])
        Base.helper.waitForExistence(Base.app.staticTexts["Enter a passcode"])
    }

    func testPasscodeMustBeCorrectWhenRemoving() {
        navigator.performAction(Action.SetPasscode)
        XCTAssertTrue(Base.app.staticTexts["Immediately"].exists)

        navigator.performAction(Action.DisablePasscodeTypeIncorrectPasscode)
        Base.helper.waitForExistence(Base.app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])

        navigator.performAction(Action.DisablePasscode)
        Base.helper.waitForExistence(Base.app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
    }

    func testChangingIntervalResetsValidationTimer() {
        navigator.performAction(Action.SetPasscode)

        // Enter login, since the default is 'set immediately,' it will ask for passcode
        navigator.performAction(Action.UnlockLoginsSettings)
        Base.helper.waitForExistence(Base.app.tables["Login List"])

        // Change it to 15 minutes
        navigator.goto(PasscodeSettings)
        setInterval("After 15 minutes")

        // Enter login, since the interval is reset, it will ask for password again
        navigator.goto(LockedLoginsSettings)
        Base.helper.waitForExistence(Base.app.navigationBars["Enter Passcode"])
        navigator.performAction(Action.UnlockLoginsSettings)
    }
}
