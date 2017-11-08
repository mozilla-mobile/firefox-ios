/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

extension String {

    subscript (i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }

    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }

    subscript (r: Range<Int>) -> String {
        let start = characters.index(startIndex, offsetBy: r.lowerBound)
        let end = self.index(start, offsetBy: r.upperBound - r.lowerBound)
        return self[Range(start ..< end)]
    }
}

class AuthenticationTest: BaseTestCase {
    fileprivate func typePasscode(_ passCode: String) {
        app.keys[passCode[0]].tap()
        app.keys[passCode[1]].tap()
        app.keys[passCode[2]].tap()
        app.keys[passCode[3]].tap()
        app.keys[passCode[4]].tap()
        app.keys[passCode[5]].tap()
    }

    fileprivate func closeAuthenticationManager() {
        navigator.goto(BrowserTab)
    }

    fileprivate func disablePasscode(_ passCode: String) {
        navigator.goto(PasscodeSettings)

        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode(passCode)
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
    }

    fileprivate func enablePasscode(_ passCode: String, interval: String = "Immediately") {
        let authenticationmanagerSettingstableviewTable = app.tables["AuthenticationManager.settingsTableView"]

        navigator.goto(PasscodeSettings)
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"].tap()
        waitforExistence(app.staticTexts["Enter a passcode"])
        typePasscode(passCode)
        waitforExistence(app.staticTexts["Re-enter passcode"])
        typePasscode(passCode)
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"])
        navigator.goto(PasscodeIntervalSettings)
        typePasscode(passCode)
        app.staticTexts[interval].tap()
        navigator.goto(PasscodeSettings)
        waitforExistence(authenticationmanagerSettingstableviewTable.staticTexts[interval])
    }

    // Sets the passcode and interval (set to immediately)
    func testTurnOnOff() {
        enablePasscode("133777")
        XCTAssertTrue(app.staticTexts["Immediately"].exists)
        disablePasscode("133777")
    }

    func testChangePassCode() {
        enablePasscode("133777")
        app.staticTexts["Change Passcode"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("133777")
        waitforExistence(app.staticTexts["Enter a new passcode"])
        typePasscode("233777")
        waitforExistence(app.staticTexts["Re-enter passcode"])
        typePasscode("233777")
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"])
        disablePasscode("233777")
    }

    func testPromptPassCodeUponReentry() {
        enablePasscode("133777")
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("133777")
        waitforExistence(app.tables["Login List"])

        //send app to background, and re-enter
        XCUIDevice.shared().press(.home)
        app.activate()
        let contentView = app.navigationBars["Client.FxAContentView"]
        if contentView.exists {
            app.navigationBars["Client.FxAContentView"].buttons["Settings"].tap()
        }
        navigator.nowAt("SettingsScreen")
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
    }

    func testPromptPassCodeUponReentryWithDelay() {
        enablePasscode("133777", interval: "After 5 minutes")
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("133777")
        waitforExistence(app.tables["Login List"])

        //send app to background, and re-enter
        XCUIDevice.shared().press(.home)
        app.activate()
        let contentView = app.navigationBars["Client.FxAContentView"]
        if contentView.exists {
            app.navigationBars["Client.FxAContentView"].buttons["Settings"].tap()
        }

        navigator.nowAt("SettingsScreen")
        navigator.goto(LoginsSettings)
        waitforExistence(app.tables["Login List"])
    }

    func testChangePasscodeShowsErrorStates() {
        enablePasscode("133777")
        app.staticTexts["Change Passcode"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("233777")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        typePasscode("333777")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        typePasscode("133777")
        waitforExistence(app.staticTexts["Enter a new passcode"])

        // Enter same passcode as new one
        typePasscode("133777")
        waitforExistence(app.staticTexts["New passcode must be different than existing code."])

        // Enter mismatched passcode
        typePasscode("233777")
        waitforExistence(app.staticTexts["Re-enter passcode"])
        typePasscode("333777")
        waitforExistence(app.staticTexts["Passcodes didn’t match. Try again."])

        // Put proper password
        XCTAssertTrue(app.staticTexts["Enter a new passcode"].exists)
        typePasscode("233777")
        waitforExistence(app.staticTexts["Re-enter passcode"])
        typePasscode("233777")
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"])

        disablePasscode("233777")
    }

    func testChangeRequirePasscodeInterval() {
        enablePasscode("133777")

        let authenticationmanagerSettingstableviewTable = app.tables["AuthenticationManager.settingsTableView"]
        navigator.goto(PasscodeIntervalSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("133777")
        waitforExistence(app.staticTexts["Immediately"])
        XCTAssertTrue(app.staticTexts["After 1 minute"].exists)
        XCTAssertTrue(app.staticTexts["After 5 minutes"].exists)
        XCTAssertTrue(app.staticTexts["After 10 minutes"].exists)
        XCTAssertTrue(app.staticTexts["After 15 minutes"].exists)
        XCTAssertTrue(app.staticTexts["After 1 hour"].exists)

        app.staticTexts["After 15 minutes"].tap()
        navigator.goto(PasscodeSettings)
        waitforExistence(authenticationmanagerSettingstableviewTable.staticTexts["After 15 minutes"])

        // Since we set to 15 min, it shouldn't ask for password again, but it skips verification
        // only when timing isn't changed. (could be due to timer reset?)
        // For clarification, raised Bug 1325439
        navigator.goto(PasscodeIntervalSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("133777")
        navigator.goto(PasscodeSettings)
        waitforExistence(authenticationmanagerSettingstableviewTable.staticTexts["After 15 minutes"])
        disablePasscode("133777")
    }

    func testEnteringLoginsUsingPasscode() {
        enablePasscode("133777")

        // Enter login
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("133777")
        waitforExistence(app.tables["Login List"])
        navigator.goto(SettingsScreen)

        // Trying again should display passcode screen since we've set the interval to be immediately.
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("133777")
        waitforExistence(app.tables["Login List"])
        disablePasscode("133777")
    }

    func testEnteringLoginsUsingPasscodeWithFiveMinutesInterval() {
        enablePasscode("133777", interval: "After 5 minutes")

        // now we've changed the timeout, we should prompt next time for passcode.
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("133777")
        waitforExistence(app.tables["Login List"])

        // Trying again should not display the passcode screen since the interval is 5 minutes
        navigator.goto(SettingsScreen)
        navigator.goto(LoginsSettings)
        waitforExistence(app.tables["Login List"])

        navigator.goto(PasscodeIntervalSettings)
        waitforExistence(app.staticTexts["After 5 minutes"])

        disablePasscode("133777")
    }

    func testEnteringLoginsWithNoPasscode() {
        // it is disabled
        navigator.goto(PasscodeSettings)
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])

        navigator.goto(LoginsSettings)
        waitforExistence(app.tables["Login List"])
    }

    func testWrongPasscodeDisplaysAttemptsAndMaxError() {
        enablePasscode("133777")
        navigator.goto(PasscodeIntervalSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("133777")
        waitforExistence(app.staticTexts["After 5 minutes"])
        app.staticTexts["After 5 minutes"].tap()
        navigator.goto(PasscodeSettings)
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["After 5 minutes"])

        // Enter wrong passcode
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("233777")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        typePasscode("333777")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        typePasscode("333777")
        waitforExistence(app.staticTexts["Maximum attempts reached. Please try again later."])
    }

    func testWrongPasscodeAttemptsPersistAcrossEntryAndConfirmation() {
        enablePasscode("133777")

        // Enter wrong passcode on Logins
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("233777")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])

        // Go back to Passcode, and enter a wrong passcode, notice the error count
        navigator.goto(PasscodeSettings)
        app.staticTexts["Change Passcode"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("233777")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        app.buttons["Cancel"].tap()

        disablePasscode("133777")
    }

    func testChangedPasswordMustBeNew() {
        enablePasscode("133777")
        app.staticTexts["Change Passcode"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("133777")
        waitforExistence(app.staticTexts["Enter a new passcode"])
        typePasscode("133777")
        waitforExistence(app.staticTexts["New passcode must be different than existing code."])
        app.navigationBars["Change Passcode"].buttons["Cancel"].tap()

        disablePasscode("133777")
    }

    func testPasscodesMustMatchWhenCreating() {
        navigator.goto(PasscodeSettings)
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"].tap()
        waitforExistence(app.staticTexts["Enter a passcode"])
        typePasscode("133777")
        waitforExistence(app.staticTexts["Re-enter passcode"])
        typePasscode("233777")
        waitforExistence(app.staticTexts["Passcodes didn’t match. Try again."])
        waitforExistence(app.staticTexts["Enter a passcode"])
        app.buttons["Cancel"].tap()
    }

    func testPasscodeMustBeCorrectWhenRemoving() {
        enablePasscode("133777")
        XCTAssertTrue(app.staticTexts["Immediately"].exists)
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("233777")

        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        typePasscode("133777")
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
    }

    func testChangingIntervalResetsValidationTimer() {
        enablePasscode("133777")

        // Enter login, since the default is 'set immediately,' it will ask for passcode
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("133777")
        waitforExistence(app.tables["Login List"])

        navigator.goto(PasscodeIntervalSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("133777")
        waitforExistence(app.staticTexts["Immediately"])
        app.staticTexts["After 15 minutes"].tap()

        navigator.goto(PasscodeSettings)
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["After 15 minutes"])

        // Enter login, since the interval is reset, it will ask for password again
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        disablePasscode("133777")
    }
}
