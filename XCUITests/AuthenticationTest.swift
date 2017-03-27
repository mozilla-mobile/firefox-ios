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
        
    var navigator: Navigator!
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        navigator = createScreenGraph(app).navigator(self)
        continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        closeAuthenticationManager()
        super.tearDown()
    }
    
    fileprivate func typePasscode(_ passCode: String) {
        app.keys[passCode[0]].tap()
        app.keys[passCode[1]].tap()
        app.keys[passCode[2]].tap()
        app.keys[passCode[3]].tap()
    }

    fileprivate func closeAuthenticationManager() {
        navigator.goto(NewTabScreen)
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
        enablePasscode("1337")
        XCTAssertTrue(app.staticTexts["Immediately"].exists)
        
        disablePasscode("1337")
    }
    
    func testChangePassCode() {
        enablePasscode("1337")
        app.staticTexts["Change Passcode"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["Enter a new passcode"])
        typePasscode("2337")
        waitforExistence(app.staticTexts["Re-enter passcode"])
        typePasscode("2337")
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"])

        disablePasscode("2337")
    }
    
    func testPromptPassCodeUponReentry() {
        let springboard = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.springboard")!
      
        enablePasscode("1337")
        navigator.goto(LoginsSettings)
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.tables["Login List"])
        
        //send app to background, and re-enter
        XCUIDevice.shared().press(.home)
        waitforExistence(springboard.scrollViews.otherElements.icons["Nightly"])
        springboard.scrollViews.otherElements.icons["Nightly"].doubleTap()
        
        navigator.nowAt("SettingsScreen")
        navigator.goto(LoginsSettings)
        waitforExistence(app.staticTexts["Enter Passcode"])
    }
    
    func testPromptPassCodeUponReentryWithDelay() {
        let springboard = XCUIApplication(privateWithPath: nil, bundleID: "com.apple.springboard")!
        
        enablePasscode("1337", interval: "After 5 minutes")
        navigator.goto(LoginsSettings)
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.tables["Login List"])
        
        //send app to background, and re-enter
        XCUIDevice.shared().press(.home)
        waitforExistence(springboard.scrollViews.otherElements.icons["Nightly"])
        springboard.scrollViews.otherElements.icons["Nightly"].doubleTap()
        
        navigator.nowAt("SettingsScreen")
        navigator.goto(LoginsSettings)
        waitforExistence(app.tables["Login List"])
    }
    
    func testChangePasscodeShowsErrorStates() {
        enablePasscode("1337")
        app.staticTexts["Change Passcode"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("2337")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        typePasscode("3337")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        typePasscode("1337")
        waitforExistence(app.staticTexts["Enter a new passcode"])
        
        // Enter same passcode as new one
        typePasscode("1337")
        waitforExistence(app.staticTexts["New passcode must be different than existing code."])
        
        // Enter mismatched passcode
        typePasscode("2337")
        waitforExistence(app.staticTexts["Re-enter passcode"])
        typePasscode("3337")
        waitforExistence(app.staticTexts["Passcodes didn't match. Try again."])
        
        // Put proper password
        XCTAssertTrue(app.staticTexts["Enter a new passcode"].exists)
        typePasscode("2337")
        waitforExistence(app.staticTexts["Re-enter passcode"])
        typePasscode("2337")
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"])
        
        disablePasscode("2337")
    }
    
    func testChangeRequirePasscodeInterval() {
        enablePasscode("1337")
        
        let authenticationmanagerSettingstableviewTable = app.tables["AuthenticationManager.settingsTableView"]
        navigator.goto(PasscodeIntervalSettings)
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
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
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")

        navigator.goto(PasscodeSettings)
        waitforExistence(authenticationmanagerSettingstableviewTable.staticTexts["After 15 minutes"])
        
        disablePasscode("1337")
    }
    
    func testEnteringLoginsUsingPasscode() {
        enablePasscode("1337")

        // Enter login
        navigator.goto(LoginsSettings)
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.tables["Login List"])
        navigator.goto(SettingsScreen)

        // Trying again should display passcode screen since we've set the interval to be immediately.
        navigator.goto(LoginsSettings)
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.tables["Login List"])

        disablePasscode("1337")
    }

    func testEnteringLoginsUsingPasscodeWithFiveMinutesInterval() {
        enablePasscode("1337", interval: "After 5 minutes")

        // now we've changed the timeout, we should prompt next time for passcode.
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.tables["Login List"])

        // Trying again should not display the passcode screen since the interval is 5 minutes
        navigator.goto(SettingsScreen)
        navigator.goto(LoginsSettings)
        waitforExistence(app.tables["Login List"])

        navigator.goto(PasscodeIntervalSettings)
        waitforExistence(app.staticTexts["After 5 minutes"])

        disablePasscode("1337")
    }

    func testEnteringLoginsWithNoPasscode() {
        // it is disabled
        navigator.goto(PasscodeSettings)
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])

        navigator.goto(LoginsSettings)
        waitforExistence(app.tables["Login List"])
    }

    func testWrongPasscodeDisplaysAttemptsAndMaxError() {
        enablePasscode("1337")
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Require Passcode"].tap()
        
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["After 5 minutes"])
        app.staticTexts["After 5 minutes"].tap()
        app.navigationBars["Require Passcode"].buttons["Passcode"].tap()
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["After 5 minutes"])
 
        // Enter wrong passcode
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("2337")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        typePasscode("3337")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        typePasscode("3337")
        waitforExistence(app.staticTexts["Maximum attempts reached. Please try again later."])
    }

    func testWrongPasscodeAttemptsPersistAcrossEntryAndConfirmation() {
        enablePasscode("1337")
        
        // Enter wrong passcode on Logins
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("2337")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])

        // Go back to Passcode, and enter a wrong passcode, notice the error count
        navigator.goto(PasscodeSettings)
        app.staticTexts["Change Passcode"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("2337")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        app.buttons["Cancel"].tap()
        
        disablePasscode("1337")
    }

    func testChangedPasswordMustBeNew() {
        enablePasscode("1337")
        app.staticTexts["Change Passcode"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["Enter a new passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["New passcode must be different than existing code."])
        app.navigationBars["Change Passcode"].buttons["Cancel"].tap()
        
        disablePasscode("1337")
    }

    func testPasscodesMustMatchWhenCreating() {
        navigator.goto(PasscodeSettings)
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"].tap()
        waitforExistence(app.staticTexts["Enter a passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["Re-enter passcode"])
        typePasscode("2337")
        waitforExistence(app.staticTexts["Passcodes didn't match. Try again."])
        waitforExistence(app.staticTexts["Enter a passcode"])
        app.buttons["Cancel"].tap()
    }

    func testPasscodeMustBeCorrectWhenRemoving() {
        enablePasscode("1337")
        XCTAssertTrue(app.staticTexts["Immediately"].exists)
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("2337")

        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        typePasscode("1337")
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
    }

    func testChangingIntervalResetsValidationTimer() {
        enablePasscode("1337")

        // Enter login, since the default is 'set immediately,' it will ask for passcode
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.tables["Login List"])
        
        navigator.goto(PasscodeIntervalSettings)
        waitforExistence(app.staticTexts["Enter Passcode"])

        typePasscode("1337")
        waitforExistence(app.staticTexts["Immediately"])
        app.staticTexts["After 15 minutes"].tap()

        navigator.goto(PasscodeSettings)
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["After 15 minutes"])

        // Enter login, since the interval is reset, it will ask for password again
        navigator.goto(LoginsSettings)
        waitforExistence(app.navigationBars["Enter Passcode"])

        disablePasscode("1337")
    }
}
