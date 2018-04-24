/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class SyncUITests: BaseTestCase {
    func testUIFromSettings () {
        navigator.goto(FxASigninScreen)
        verifyFxASigninScreen()
    }

    func testSyncUIFromBrowserTabMenu() {
        // Check menu available from HomeScreenPanel
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.tables["Context Menu"].cells["menu-sync"])
        navigator.goto(FxASigninScreen)
        verifyFxASigninScreen()

        // Check menu available from a website
        navigator.openURL("mozilla.org")
        waitUntilPageLoad()
        navigator.goto(BrowserTabMenu)
        waitforExistence(app.tables["Context Menu"].cells["menu-sync"])
        navigator.goto(FxASigninScreen)
        verifyFxASigninScreen()
    }

    private func verifyFxASigninScreen() {
        waitforExistence(app.webViews.staticTexts["Sign in"])
        XCTAssertTrue(app.navigationBars["Client.FxAContentView"].exists)
        XCTAssertTrue(app.webViews.textFields["Email"].exists)
        XCTAssertTrue(app.webViews.secureTextFields["Password"].exists)
        XCTAssertTrue(app.webViews.buttons["Sign in"].exists)
    }

    func testPlaceholderValues () {
        navigator.goto(FxASigninScreen)
        waitforExistence(app.webViews.staticTexts["Sign in"])
        let mailPlaceholder = "Email"
        let passwordPlaceholder = "Password"

        let defaultMailPlaceholder = app.webViews.textFields["Email"].placeholderValue!
        let defaultPasswordPlaceholder = app.webViews.secureTextFields["Password"].placeholderValue!
        XCTAssertEqual(mailPlaceholder, defaultMailPlaceholder, "The mail placeholder does not show the correct value")
        XCTAssertEqual(passwordPlaceholder, defaultPasswordPlaceholder, "The password placeholder does not show the correct value")
    }

    func testTypeOnGivenFields() {
        navigator.goto(FxASigninScreen)
        waitforExistence(app.webViews.staticTexts["Sign in"])

        // Tap Sign in without any value in email Password focus on Email
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.webViews.staticTexts["Valid email required"])

        // Enter only email, wrong and correct and tap sign in
        userState.fxaUsername = "bademail"
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.webViews.staticTexts["Valid email required"])

        userState.fxaUsername = "valid@email.com"
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.webViews.staticTexts["Valid password required"])

        // Enter invalid (too short, it should be at least 8 chars) and incorrect password
        userState.fxaPassword = "foo"
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.webViews.staticTexts["Must be at least 8 characters"])

        // Enter valid but incorrect, it does not exists, password
        userState.fxaPassword = "atleasteight"
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitforExistence(app.webViews.staticTexts["Unknown account."])
        XCTAssertTrue(app.webViews.links["Sign up"].exists)
    }

    func testCreateAnAccountLink() {
        navigator.goto(FxASigninScreen)
        waitforExistence(app.webViews.links["Create an account"])
        navigator.goto(FxCreateAccount)
        waitforExistence(app.webViews.buttons["Create account"])
    }

    func testShowPassword() {
        // The aim of this test is to check if the option to show password is shown when user starts typing and dissapears when no password is typed
        navigator.goto(FxASigninScreen)
        waitforNoExistence(app.webViews.staticTexts["Show"])
        // Typing on Email should not show Show (password) option
        userState.fxaUsername = "email"
        navigator.performAction(Action.FxATypeEmail)
        waitforNoExistence(app.webViews.staticTexts["Show"])
        // Typing on Password should show Show (password) option
        userState.fxaPassword = "foo"
        navigator.performAction(Action.FxATypePassword)
        waitforExistence(app.webViews.staticTexts["Show"])
        // Long press delete key to remove the password typed, Show (password) option should not be shown
        app.keys["delete"].press(forDuration: 2)
        waitforNoExistence(app.webViews.staticTexts["Show"])
    }
}
