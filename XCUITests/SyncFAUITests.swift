/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

let getEndPoint = "http://restmail.net/mail/test-256a5b5b18"
let postEndPoint = "https://api-accounts.stage.mozaws.net/v1/recovery_email/verify_code"
let deleteEndPoint = "http://restmail.net/mail/test-256a5b5b18@restmail.net"

let userMail = "test-256a5b5b18@restmail.net"
let password = "nPuPEcoj"

var uid: String!
var code: String!

class SyncUITests: BaseTestCase {
    func testUIFromSettings () {
        navigator.goto(FxASigninScreen)
        verifyFxASigninScreen()
    }

    func testSyncUIFromBrowserTabMenu() {
        // Check menu available from HomeScreenPanel
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables["Context Menu"].cells["menu-sync"])
        navigator.goto(FxASigninScreen)
        verifyFxASigninScreen()

        // Check menu available from a website
        navigator.openURL("mozilla.org")
        waitUntilPageLoad()
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables["Context Menu"].cells["menu-sync"])
        navigator.goto(FxASigninScreen)
        verifyFxASigninScreen()
    }

    private func verifyFxASigninScreen() {
        waitForExistence(app.webViews.staticTexts["Sign in"])
        XCTAssertTrue(app.navigationBars["Client.FxAContentView"].exists)
        XCTAssertTrue(app.webViews.textFields["Email"].exists)
        XCTAssertTrue(app.webViews.secureTextFields["Password"].exists)
        // Verify the placeholdervalues here for the textFields
        let mailPlaceholder = "Email"
        let passwordPlaceholder = "Password"

        let defaultMailPlaceholder = app.webViews.textFields["Email"].placeholderValue!
        let defaultPasswordPlaceholder = app.webViews.secureTextFields["Password"].placeholderValue!
        XCTAssertEqual(mailPlaceholder, defaultMailPlaceholder, "The mail placeholder does not show the correct value")
        XCTAssertEqual(passwordPlaceholder, defaultPasswordPlaceholder, "The password placeholder does not show the correct value")
        XCTAssertTrue(app.webViews.buttons["Sign in"].exists)
    }

    func testTypeOnGivenFields() {
        navigator.goto(FxASigninScreen)
        waitForExistence(app.webViews.staticTexts["Sign in"])

        // Tap Sign in without any value in email Password focus on Email
        navigator.performAction(Action.FxATapOnSignInButton)
        waitForExistence(app.webViews.staticTexts["Valid email required"])

        // Enter only email, wrong and correct and tap sign in
        userState.fxaUsername = "bademail"
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitForExistence(app.webViews.staticTexts["Valid email required"])

        userState.fxaUsername = "valid@email.com"
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitForExistence(app.webViews.staticTexts["Valid password required"])

        // Enter invalid (too short, it should be at least 8 chars) and incorrect password
        userState.fxaPassword = "foo"
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitForExistence(app.webViews.staticTexts["Must be at least 8 characters"])

        // Enter valid but incorrect, it does not exists, password
        userState.fxaPassword = "atleasteight"
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxATapOnSignInButton)
        waitForExistence(app.webViews.staticTexts["Unknown account."], timeout: 10)
        XCTAssertTrue(app.webViews.links["Sign up"].exists)
    }

    func testCreateAnAccountLink() {
        navigator.goto(FxASigninScreen)
        waitForExistence(app.webViews.links["Create an account"])
        navigator.goto(FxCreateAccount)
        waitForExistence(app.webViews.buttons["Create account"])
    }

    func testShowPassword() {
        // The aim of this test is to check if the option to show password is shown when user starts typing and dissapears when no password is typed
        navigator.goto(FxASigninScreen)
        waitForExistence(app.textFields["Email"])

        // Typing on Email should not show Show (password) option
        userState.fxaUsername = "email"
        navigator.performAction(Action.FxATypeEmail)

        // Typing on Password should show Show (password) option
        userState.fxaPassword = "foo"
        navigator.performAction(Action.FxATypePassword)
        waitForExistence(app.webViews.staticTexts["Show password"])
        // Long press delete key to remove the password typed, Show (password) option should not be shown
        app.keys["delete"].press(forDuration: 2)
    }

    // Smoketest
    func testAccountManagmentPage() {
        deleteInbox()
        // Log in
        navigator.goto(FxASigninScreen)
        waitForExistence(app.webViews.staticTexts["Sign in"], timeout: 10)
        userState.fxaUsername = userMail
        userState.fxaPassword = password
        navigator.performAction(Action.FxATypeEmail)
        navigator.performAction(Action.FxATypePassword)
        navigator.performAction(Action.FxATapOnSignInButton)
        allowNotifications()
        // If the account is not verified need to verify it to access the menu
        if (app.webViews.staticTexts["Confirm this sign-in"].exists) {
            let group = DispatchGroup()
            group.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                self.verifyAccount() {
                    sleep(5)
                    group.leave()
                }
            }
            group.wait()
        }
        // Once the sign in is successful check the account management page
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        waitForExistence(app.tables.cells["menu-TrackingProtection"])
        // Tap on the sync name option
        if iPad() {
            app.tables.cells.element(boundBy: 9).tap()
        } else {
            app.tables.cells.element(boundBy: 0).tap()
        }
        waitForExistence(app.navigationBars["Firefox Account"])
        XCTAssertTrue(app.tables.cells["Manage"].exists)
        XCTAssertTrue(app.cells.switches["sync.engine.bookmarks.enabled"].exists)
        XCTAssertTrue(app.cells.switches["sync.engine.history.enabled"].exists)
        XCTAssertTrue(app.cells.switches["sync.engine.tabs.enabled"].exists)
        XCTAssertTrue(app.cells.switches["sync.engine.passwords.enabled"].exists)
        XCTAssertTrue(app.cells.textFields["DeviceNameSettingTextField"].exists)
        XCTAssertTrue(app.cells["SignOut"].exists)
        disconnectAccount()
    }

    private func disconnectAccount() {
        app.cells["SignOut"].tap()
        app.buttons["Disconnect"].tap()
        // Remove the history so that starting to sign is does not keep the userEmail
        navigator.nowAt(BrowserTab)
        navigator.goto(BrowserTabMenu)
        navigator.performAction(Action.AcceptClearPrivateData)
    }

    func allowNotifications () {
        addUIInterruptionMonitor(withDescription: "notifications") { (alert) -> Bool in
            alert.buttons["Allow"].tap()
            return true
        }
        sleep(5)
        app.swipeDown()
    }

    private func deleteInbox() {
    // First Delete the inbox
    let restUrl = URL(string: deleteEndPoint)
    var request = URLRequest(url: restUrl!)
    request.httpMethod = "DELETE"

    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        print("Delete")
    }
    task.resume()
    }

    private func completeVerification(uid: String, code: String, done: @escaping () -> ()) {
        // POST to EndPoint api.accounts.firefox.com/v1/recovery_email/verify_code
        let restUrl = URL(string: postEndPoint)
        var request = URLRequest(url: restUrl!)
        request.setValue("application/json; charset=UTF-8", forHTTPHeaderField: "Content-Type")

        request.httpMethod = "POST"

        let jsonObject: [String: Any] = ["uid": uid, "code":code]
        let data = try! JSONSerialization.data(withJSONObject: jsonObject, options: JSONSerialization.WritingOptions.prettyPrinted)
        let json = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
        if let json = json {
            print("json \(json)")
        }
        let jsonData = json?.data(using: String.Encoding.utf8.rawValue)

        request.httpBody = jsonData
        print("json \(jsonData!)")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("error:", error)
                return
            }
            done()
        }
        task.resume()
    }

    private func verifyAccount(done: @escaping () -> ()) {
        // GET to EndPoint/mail/test-user
        let restUrl = URL(string: getEndPoint)
        var request = URLRequest(url: restUrl!)
        request.httpMethod = "GET"

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if(error != nil) {
                print("Error: \(error ?? "Get Error" as! Error)")
            }
            let responseString = String(data: data!, encoding: .utf8)
            print("responseString = \(String(describing: responseString))")

            let regexpUid = "(uid=[a-z0-9]{0,32}$?)"
            let regexCode = "(code=[a-z0-9]{0,32}$?)"
            if let rangeUid = responseString?.range(of:regexpUid, options: .regularExpression) {
                uid = String(responseString![rangeUid])
            }

            if let rangeCode = responseString?.range(of:regexCode, options: .regularExpression) {
                code = String(responseString![rangeCode])
            }

            let finalCodeIndex = code.index(code.endIndex, offsetBy: -32)
            let codeNumber = code[finalCodeIndex...]
            let finalUidIndex = uid.index(uid.endIndex, offsetBy: -32)
            let uidNumber = uid[finalUidIndex...]
            self.completeVerification(uid: String(uidNumber), code: String(codeNumber)) {
                done()
            }
        }
        task.resume()
    }
}
