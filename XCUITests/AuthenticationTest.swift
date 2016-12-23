/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

extension String {
    
    subscript (i: Int) -> Character {
        return self[self.startIndex.advancedBy(i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = startIndex.advancedBy(r.startIndex)
        let end = start.advancedBy(r.endIndex - r.startIndex)
        return self[Range(start ..< end)]
    }
}

class AuthenticationTest: BaseTestCase {
        
    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
        continueAfterFailure = false
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    private func typePasscode(passCode: String) {
        let app = XCUIApplication()
        
        app.keys[passCode[0]].tap()
        app.keys[passCode[1]].tap()
        app.keys[passCode[2]].tap()
        app.keys[passCode[3]].tap()
    }

    private func selectPasscodeMenu() {
        let app = XCUIApplication()
        
        let appsettingstableviewcontrollerTableviewTable = app.tables["AppSettingsTableViewController.tableView"]
        waitforExistence(appsettingstableviewcontrollerTableviewTable.cells["TouchIDPasscode"])
        appsettingstableviewcontrollerTableviewTable.cells["TouchIDPasscode"].tap()
        waitforExistence(app.staticTexts["Passcode"])
    }
    
    private func selectLoginMenu() {
        let app = XCUIApplication()
        
        let appsettingstableviewcontrollerTableviewTable = app.tables["AppSettingsTableViewController.tableView"]
        waitforExistence(appsettingstableviewcontrollerTableviewTable.cells["Logins"])
        appsettingstableviewcontrollerTableviewTable.cells["Logins"].tap()
    }
    
    private func openAuthenticationManager() {
        let app = XCUIApplication()
        app.buttons["TabToolbar.menuButton"].tap()
        app.collectionViews.cells["SettingsMenuItem"].tap()
        
        selectPasscodeMenu()
    }

    private func closeAuthenticationManager() {
        let app = XCUIApplication()

        app.navigationBars["Passcode"].buttons["Settings"].tap()
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
    }
    
    private func disablePasscode(passCode: String) {
        let app = XCUIApplication()
        
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode(passCode)
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
    }
    
    private func enablePasscode(passCode: String) {
        let app = XCUIApplication()
        
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"].tap()
        waitforExistence(app.staticTexts["Enter a passcode"])
        typePasscode(passCode)
        waitforExistence(app.staticTexts["Re-enter passcode"])
        typePasscode(passCode)
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"])
     }

    // Sets the passcode and interval (set to immediately)
    func testTurnOnOff() {
        let app = XCUIApplication()

        openAuthenticationManager()
        enablePasscode("1337")
        XCTAssertTrue(app.staticTexts["Immediately"].exists)
        
        disablePasscode("1337")
        closeAuthenticationManager()
    }
    
    func testChangePassCode() {
        let app = XCUIApplication()
        
        openAuthenticationManager()
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
        closeAuthenticationManager()
    }
    
    func testChangePasscodeShowsErrorStates() {
        let app = XCUIApplication()
        
        openAuthenticationManager()
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
        closeAuthenticationManager()
    }
    
    func testChangeRequirePasscodeInterval() {
        let app = XCUIApplication()
        
        openAuthenticationManager()
        enablePasscode("1337")
        
        let authenticationmanagerSettingstableviewTable = app.tables["AuthenticationManager.settingsTableView"]
        authenticationmanagerSettingstableviewTable.staticTexts["Require Passcode"].tap()
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["Immediately"])
        XCTAssertTrue(app.staticTexts["After 1 minute"].exists)
        XCTAssertTrue(app.staticTexts["After 5 minutes"].exists)
        XCTAssertTrue(app.staticTexts["After 10 minutes"].exists)
        XCTAssertTrue(app.staticTexts["After 15 minutes"].exists)
        XCTAssertTrue(app.staticTexts["After 1 hour"].exists)
        
        app.staticTexts["After 15 minutes"].tap()
        app.navigationBars["Require Passcode"].buttons["Passcode"].tap()
        waitforExistence(authenticationmanagerSettingstableviewTable.staticTexts["After 15 minutes"])
        
        // Since we set to 15 min, it shouldn't ask for password again, but it skips verification
        // only when timing isn't changed. (could be due to timer reset?)  
        // For clarification, raised Bug 1325439
        authenticationmanagerSettingstableviewTable.staticTexts["Require Passcode"].tap()
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
        app.navigationBars["Require Passcode"].buttons["Passcode"].tap()
        waitforExistence(authenticationmanagerSettingstableviewTable.staticTexts["After 15 minutes"])
        
        disablePasscode("1337")
        closeAuthenticationManager()
    }
    
    func testEnteringLoginsUsingPasscode() {
        let app = XCUIApplication()
        
        openAuthenticationManager()
        enablePasscode("1337")
        app.navigationBars["Passcode"].buttons["Settings"].tap()

        // Enter login
        selectLoginMenu()
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.tables["Login List"])
        app.navigationBars["Logins"].buttons["Settings"].tap()
        
        // Trying again should display passcode screen since we've set the interval to be immediately.
        selectLoginMenu()
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.tables["Login List"])
        
        app.navigationBars["Logins"].buttons["Settings"].tap()
        selectPasscodeMenu()
        disablePasscode("1337")
        closeAuthenticationManager()
    }

    func testEnteringLoginsUsingPasscodeWithFiveMinutesInterval() {
        let app = XCUIApplication()
        
        openAuthenticationManager()
        enablePasscode("1337")
        
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Require Passcode"].tap()
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["After 5 minutes"])
        app.staticTexts["After 5 minutes"].tap()
        app.navigationBars["Require Passcode"].buttons["Passcode"].tap()
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["After 5 minutes"])
        app.navigationBars["Passcode"].buttons["Settings"].tap()
        
        selectLoginMenu()
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.tables["Login List"])
        app.navigationBars["Logins"].buttons["Settings"].tap()
        
        // Trying again should not display the passcode screen since the interval is 5 minutes
        selectLoginMenu()
        waitforExistence(app.tables["Login List"])
        
        app.navigationBars["Logins"].buttons["Settings"].tap()
        selectPasscodeMenu()
        disablePasscode("1337")
        closeAuthenticationManager()
    }

    func testEnteringLoginsWithNoPasscode() {
        let app = XCUIApplication()
        
        // it is disabled
        openAuthenticationManager()
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
        app.navigationBars["Passcode"].buttons["Settings"].tap()
        
        selectLoginMenu()
        waitforExistence(app.tables["Login List"])
        app.navigationBars["Logins"].buttons["Settings"].tap()
        waitforExistence(app.tables["AppSettingsTableViewController.tableView"].staticTexts["Logins"])
        app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
    }

    func testWrongPasscodeDisplaysAttemptsAndMaxError() {
        let app = XCUIApplication()
        
        openAuthenticationManager()
        enablePasscode("1337")
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Require Passcode"].tap()
        
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["After 5 minutes"])
        app.staticTexts["After 5 minutes"].tap()
        app.navigationBars["Require Passcode"].buttons["Passcode"].tap()
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["After 5 minutes"])
        app.navigationBars["Passcode"].buttons["Settings"].tap()
 
        // Enter wrong passcode
        selectLoginMenu()
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("2337")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        typePasscode("3337")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        typePasscode("3337")
        waitforExistence(app.staticTexts["Maximum attempts reached. Please try again later."])
        app.navigationBars["Enter Passcode"].buttons["Cancel"].tap()
    }

    func testWrongPasscodeAttemptsPersistAcrossEntryAndConfirmation() {
        let app = XCUIApplication()
        
        openAuthenticationManager()
        enablePasscode("1337")
        app.navigationBars["Passcode"].buttons["Settings"].tap()
        
        // Enter wrong passcode on Logins
        selectLoginMenu()
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("2337")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        app.navigationBars["Enter Passcode"].buttons["Cancel"].tap()
        
        // Go back to Passcode, and enter a wrong passcode, notice the error count
        selectPasscodeMenu()
        app.staticTexts["Change Passcode"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("2337")
        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 1)."])
        app.navigationBars["Change Passcode"].buttons["Cancel"].tap()

        disablePasscode("1337")
        closeAuthenticationManager()
    }

    func testChangedPasswordMustBeNew() {
        let app = XCUIApplication()
        
        openAuthenticationManager()
        enablePasscode("1337")
        app.staticTexts["Change Passcode"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["Enter a new passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["New passcode must be different than existing code."])
        app.navigationBars["Change Passcode"].buttons["Cancel"].tap()
        
        disablePasscode("1337")
        closeAuthenticationManager()
    }

    func testPasscodesMustMatchWhenCreating() {
        let app = XCUIApplication()
        
        openAuthenticationManager()
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"].tap()
        waitforExistence(app.staticTexts["Enter a passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["Re-enter passcode"])
        typePasscode("2337")
        waitforExistence(app.staticTexts["Passcodes didn't match. Try again."])
        waitforExistence(app.staticTexts["Enter a passcode"])
        app.navigationBars["Set Passcode"].buttons["Cancel"].tap()
        closeAuthenticationManager()
    }

    func testPasscodeMustBeCorrectWhenRemoving() {
        let app = XCUIApplication()
        
        openAuthenticationManager()
        enablePasscode("1337")
        XCTAssertTrue(app.staticTexts["Immediately"].exists)
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode Off"].tap()
        waitforExistence(app.staticTexts["Enter passcode"])
        typePasscode("2337")

        waitforExistence(app.staticTexts["Incorrect passcode. Try again (Attempts remaining: 2)."])
        typePasscode("1337")
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Turn Passcode On"])
        closeAuthenticationManager()
    }

    func testChangingIntervalResetsValidationTimer() {
        let app = XCUIApplication()
        
        openAuthenticationManager()
        enablePasscode("1337")
        app.navigationBars["Passcode"].buttons["Settings"].tap()
        
        // Enter login, since the default is 'set immediately,' it will ask for passcode
        selectLoginMenu()
        waitforExistence(app.navigationBars["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.tables["Login List"])
        app.navigationBars["Logins"].buttons["Settings"].tap()
        
        selectPasscodeMenu()
        app.tables["AuthenticationManager.settingsTableView"].staticTexts["Require Passcode"].tap()
        waitforExistence(app.staticTexts["Enter Passcode"])
        typePasscode("1337")
        waitforExistence(app.staticTexts["Immediately"])
        app.staticTexts["After 15 minutes"].tap()
        app.navigationBars["Require Passcode"].buttons["Passcode"].tap()
        waitforExistence(app.tables["AuthenticationManager.settingsTableView"].staticTexts["After 15 minutes"])
        app.navigationBars["Passcode"].buttons["Settings"].tap()
        
        // Enter login, since the interval is reset, it will ask for password again
        selectLoginMenu()
        waitforExistence(app.navigationBars["Enter Passcode"])
        app.navigationBars["Enter Passcode"].buttons["Cancel"].tap()
        
        selectPasscodeMenu()
        disablePasscode("1337")
        closeAuthenticationManager()
    }
}
