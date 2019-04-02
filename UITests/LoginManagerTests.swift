/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
import EarlGrey
@testable import Client

class LoginManagerTests: KIFTestCase {

    fileprivate var webRoot: String!

    override func setUp() {
        super.setUp()
        PasscodeUtils.resetPasscode()
        webRoot = SimplePageServer.start()
        generateLogins()
        BrowserUtils.dismissFirstRunUI()
        BrowserUtils.configEarlGrey()
    }

    override func tearDown() {
        super.tearDown()
        clearLogins()
        PasscodeUtils.resetPasscode()
        BrowserUtils.resetToAboutHome()
    }

    fileprivate func openLoginManager() {
        // Wait until the dialog shows up
        let menuAppeared = GREYCondition(name: "Wait the Settings dialog to appear", block: { () -> Bool in
            var errorOrNil: NSError?
            EarlGrey.selectElement(with: grey_accessibilityLabel("Search")).assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil == nil
            return success
        })

        let menu_button = grey_allOf([grey_accessibilityLabel("Menu"),
                                          grey_accessibilityID("TabToolbar.menuButton")])
        EarlGrey.selectElement(with: menu_button).perform(grey_tap())
        EarlGrey.selectElement(with: grey_text("Settings")).perform(grey_tap())

        let success = menuAppeared.wait(withTimeout: 20)
        GREYAssertTrue(success, reason: "Failed to display settings dialog")
        if BrowserUtils.iPad() {
            EarlGrey.selectElement(with: grey_accessibilityID("Logins"))
                .using(searchAction: grey_scrollInDirection(.down, 200),
                       onElementWithMatcher: grey_accessibilityID("AppSettingsTableViewController.tableView"))
                .assert(grey_notNil())
        }

        EarlGrey.selectElement(with:grey_accessibilityLabel("Tracking Protection"))
            .using(searchAction: grey_scrollInDirection(GREYDirection.down, 400),
                   onElementWithMatcher: grey_kindOfClass(UITableView.self))
            .assert(grey_notNil())

        EarlGrey.selectElement(with: grey_accessibilityID("Logins")).perform(grey_tap())
    }

    fileprivate func closeLoginManager() {
        EarlGrey.selectElement(with:grey_allOf([grey_accessibilityLabel("Settings"), grey_kindOfClass(NSClassFromString("UIButtonLabel")!)])).perform(grey_tap())

        let DoneAppeared = GREYCondition(name: "Wait for the Done button", block: { () -> Bool in
            var errorOrNil: NSError?
            EarlGrey.selectElement(with: grey_accessibilityID("AppSettingsTableViewController.navigationItem.leftBarButtonItem"))
                .assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil == nil
            return success
        })
        let success = DoneAppeared.wait(withTimeout: 10)
        GREYAssertTrue(success, reason: "Failed to see Done button")
        EarlGrey.selectElement(with: grey_accessibilityID("AppSettingsTableViewController.navigationItem.leftBarButtonItem")).perform(grey_tap())
   }

    fileprivate func generateLogins() {
        let profile = (UIApplication.shared.delegate as! AppDelegate).profile!

        let prefixes = "abcdefghijk"
        let numRange = (0..<20)

        let passwords = generateStringListWithFormat("password%@%d", numRange: numRange, prefixes: prefixes)
        let hostnames = generateStringListWithFormat("http://%@%d.com", numRange: numRange, prefixes: prefixes)
        let usernames = generateStringListWithFormat("%@%d@email.com", numRange: numRange, prefixes: prefixes)

        (0..<(numRange.count * prefixes.count)).forEach { index in
            let login = LoginRecord(fromJSONDict: [
                "id": "\(index)",
                "hostname": hostnames[index],
                "username": usernames[index],
                "password": passwords[index]
            ])
            login.formSubmitURL = hostnames[index]
            _ = profile.logins.add(login: login).value
        }
    }

    func waitForMatcher(name: String) {
        let matcher = grey_allOf([grey_accessibilityLabel(name),
                                  grey_kindOfClass(NSClassFromString("UICalloutBarButton")!),
                                  grey_sufficientlyVisible()])

        let menuShown = GREYCondition(name: "Wait for " + name) {
            var errorOrNil: NSError?

            EarlGrey.selectElement(with: matcher).assert(grey_notNil(), error: &errorOrNil)
            let success = errorOrNil == nil
            return success
        }
        let success = menuShown.wait(withTimeout: 10)
        GREYAssertTrue(success, reason: name + " Menu not shown")
        EarlGrey.selectElement(with: matcher).perform(grey_tap())
    }

    fileprivate func generateStringListWithFormat(_ format: String, numRange: CountableRange<Int>, prefixes: String) -> [String] {
        return prefixes.map { char in

            return numRange.map { num in
                return String(format: format, "\(char)", num)
            }
            } .flatMap { $0 }
    }

    fileprivate func clearLogins() {
        let profile = (UIApplication.shared.delegate as! AppDelegate).profile!
        _ = profile.logins.wipeLocal().value
    }

    func testListFiltering() {
        openLoginManager()

        var list = tester().waitForView(withAccessibilityIdentifier: "Login List") as! UITableView

        // Filter by username
        tester().waitForView(withAccessibilityLabel: "http://a0.com")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Filter")
        tester().waitForAnimationsToFinish()

        // In simulator, the typing is too fast for the screen to be updated properly
        // pausing after 'password' (which all login password contains) to update the screen seems to make the test reliable
        tester().enterText(intoCurrentFirstResponder: "k10")
        tester().wait(forTimeInterval: 3)                     // Wait until the table is updated
        tester().waitForAnimationsToFinish()
        tester().enterText(intoCurrentFirstResponder: "@email.com")
        tester().wait(forTimeInterval: 3)                     // Wait until the table is updated
        tester().waitForAnimationsToFinish()
        list = tester().waitForView(withAccessibilityIdentifier: "Login List") as! UITableView
        tester().waitForView(withAccessibilityLabel: "k10@email.com")
        tester().waitForAnimationsToFinish()

        // Need to remove two cells for saveLogins identifier and showLoginsInAppMenu
        let loginCount2 = countOfRowsInTableView(list) - 2
        XCTAssertEqual(loginCount2, 1)
        tester().tapView(withAccessibilityLabel: "Clear text")

        // Filter by hostname
        tester().waitForView(withAccessibilityLabel: "http://a0.com")
        tester().tapView(withAccessibilityLabel: "Filter")
        tester().waitForAnimationsToFinish()
        tester().enterText(intoCurrentFirstResponder: "http://k10")
        tester().waitForAnimationsToFinish()
        tester().wait(forTimeInterval: 3)                     // Wait until the table is updated
        tester().enterText(intoCurrentFirstResponder: ".com")
        tester().wait(forTimeInterval: 3)                     // Wait until the table is updated
        list = tester().waitForView(withAccessibilityIdentifier: "Login List") as! UITableView
        tester().waitForView(withAccessibilityLabel: "k10@email.com")

        // Need to remove two cells for saveLogins identifier and showLoginsInAppMenu
        let loginCount1 = countOfRowsInTableView(list) - 2
        XCTAssertEqual(loginCount1, 1)
        tester().tapView(withAccessibilityLabel: "Clear text")

        // Filter by something that doesn't match anything
        tester().waitForView(withAccessibilityLabel: "http://a0.com")
        tester().tapView(withAccessibilityLabel: "Filter")
        tester().enterText(intoCurrentFirstResponder: "thisdoesntmatch")
        tester().waitForView(withAccessibilityIdentifier: "Login List")

        // KIFTest has a bug where waitForViewWithAccessibilityLabel causes the lists to appear again on device,
        // so checking the number of rows instead
        tester().waitForView(withAccessibilityLabel: "No logins found")
        let loginCount = countOfRowsInTableView(list)

        // Adding two to the count due to the new cells added
        XCTAssertEqual(loginCount, 2)
        tester().tapView(withAccessibilityLabel: "Cancel")
        closeLoginManager()
    }

    func testListIndexView() {
        openLoginManager()

        // Swipe the index view to navigate to bottom section
        tester().waitForAnimationsToFinish()
        tester().waitForView(withAccessibilityLabel: "a0@email.com")
        tester().swipeView(withAccessibilityIdentifier: "SAVED LOGINS", in: KIFSwipeDirection.down)
        tester().waitForView(withAccessibilityLabel: "k0@email.com")
        closeLoginManager()
    }


    func testDetailPasswordMenuOptions() {
        openLoginManager()

        tester().waitForView(withAccessibilityLabel: "http://a0.com")
        EarlGrey.selectElement(with: grey_accessibilityLabel("http://a0.com")).perform(grey_tap())
        tester().waitForView(withAccessibilityLabel: "Password")

        var passwordField = tester().waitForView(withAccessibilityIdentifier: "passwordField") as! UITextField
        XCTAssertTrue(passwordField.isSecureTextEntry)

        // Tap the ‘Reveal’ menu option
        EarlGrey.selectElement(with: grey_accessibilityID("passwordField")).perform(grey_tap())
        waitForMatcher(name: "Reveal")
        passwordField = tester().waitForView(withAccessibilityIdentifier: "passwordField") as! UITextField
        XCTAssertFalse(passwordField.isSecureTextEntry)

        // Tap the ‘Hide’ menu option
        EarlGrey.selectElement(with: grey_accessibilityID("passwordField")).perform(grey_tap())
        waitForMatcher(name: "Hide")
        passwordField = tester().waitForView(withAccessibilityIdentifier: "passwordField") as! UITextField
        XCTAssertTrue(passwordField.isSecureTextEntry)

        // Tap the ‘Copy’ menu option
        EarlGrey.selectElement(with: grey_accessibilityID("passwordField")).perform(grey_tap())
        waitForMatcher(name: "Copy")

        tester().tapView(withAccessibilityLabel: "Logins & Passwords")
        closeLoginManager()
        XCTAssertEqual(UIPasteboard.general.string, "passworda0")
    }

    func testDetailWebsiteMenuCopy() {
        openLoginManager()

        tester().waitForView(withAccessibilityLabel: "http://a0.com")
        EarlGrey.selectElement(with: grey_accessibilityLabel("http://a0.com")).perform(grey_tap())
        tester().waitForView(withAccessibilityLabel: "Password")

        EarlGrey.selectElement(with: grey_accessibilityLabel("Website")).perform(grey_tap())
        waitForMatcher(name: "Copy")

        // Tap the 'Open & Fill' menu option  just checks to make sure we navigate to the web page
        EarlGrey.selectElement(with: grey_accessibilityLabel("Website")).perform(grey_tap())
        waitForMatcher(name: "Open & Fill")

        tester().wait(forTimeInterval: 2)
        tester().waitForViewWithAccessibilityValue("a0.com/")
        XCTAssertEqual(UIPasteboard.general.string, "http://a0.com")
    }

    func testOpenAndFillFromNormalContext() {
        openLoginManager()

        tester().waitForView(withAccessibilityLabel: "http://a0.com")
        EarlGrey.selectElement(with: grey_accessibilityLabel("http://a0.com")).perform(grey_tap())
        tester().waitForView(withAccessibilityLabel: "Password")

        // Tap the 'Open & Fill' menu option  just checks to make sure we navigate to the web page
        EarlGrey.selectElement(with: grey_accessibilityLabel("Website")).perform(grey_tap())
        waitForMatcher(name: "Open & Fill")

        tester().wait(forTimeInterval: 10)
        tester().waitForViewWithAccessibilityValue("a0.com/")
    }
    // This test is disabled until bug 1486243 is fixed
    /*func testOpenAndFillFromPrivateContext() {
        if BrowserUtils.iPad() {
            EarlGrey.selectElement(with: grey_accessibilityID("TopTabsViewController.tabsButton"))
                .perform(grey_tap())
        } else {
            EarlGrey.selectElement(with: grey_accessibilityID("TabToolbar.tabsButton")).perform(grey_tap())
        }
        EarlGrey.selectElement(with: grey_accessibilityLabel("Private Mode")).perform(grey_tap())
        EarlGrey.selectElement(with: grey_accessibilityLabel("Add Tab")).perform(grey_tap())
        EarlGrey.selectElement(with: grey_accessibilityLabel("Menu")).perform(grey_tap())
        if BrowserUtils.iPad() {
            let settings_button = grey_allOf([grey_accessibilityLabel("Settings"),
                                              grey_accessibilityID("menu-Settings")])
            EarlGrey.selectElement(with: settings_button).perform(grey_tap())
        } else {
            EarlGrey.selectElement(with: grey_text("Settings")).perform(grey_tap())
        }

        if BrowserUtils.iPad() {
            EarlGrey.selectElement(with: grey_accessibilityLabel("Tracking Protection"))
                .using(searchAction: grey_scrollInDirection(.down, 200),
                       onElementWithMatcher: grey_accessibilityID("AppSettingsTableViewController.tableView"))
                .assert(grey_notNil())
        }
        EarlGrey.selectElement(with: grey_accessibilityID("Logins")).perform(grey_tap())

        tester().waitForView(withAccessibilityLabel: "a0@email.com, http://a0.com")
        tester().tapView(withAccessibilityLabel: "a0@email.com, http://a0.com")

        tester().waitForView(withAccessibilityLabel: "password")

        // Tap the 'Open & Fill' menu option  just checks to make sure we navigate to the web page
        EarlGrey.selectElement(with: grey_accessibilityID("websiteField")).perform(grey_tap())
        waitForMatcher(name: "Open & Fill")

        tester().wait(forTimeInterval: 10)
        tester().waitForViewWithAccessibilityValue("a0.com/")
    }*/

    func testDetailUsernameMenuOptions() {
        openLoginManager()

        tester().waitForView(withAccessibilityLabel: "http://a0.com")
        EarlGrey.selectElement(with: grey_accessibilityLabel("http://a0.com")).perform(grey_tap())
        tester().waitForView(withAccessibilityLabel: "Password")

        // Tap the 'Open & Fill' menu option  just checks to make sure we navigate to the web page
        EarlGrey.selectElement(with: grey_accessibilityLabel("Username")).perform(grey_tap())
        waitForMatcher(name: "Copy")

        tester().tapView(withAccessibilityLabel: "Logins & Passwords")
        closeLoginManager()
        XCTAssertEqual(UIPasteboard.general.string!, "a0@email.com")
    }

    func testListSelection() {
        openLoginManager()

        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Edit")
        tester().waitForAnimationsToFinish()

        // Select one entry
        let firstIndexPath = IndexPath(row: 0, section: 1)
        tester().tapRow(at: firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        tester().waitForView(withAccessibilityLabel: "Delete")

        let list = tester().waitForView(withAccessibilityIdentifier: "Login List") as! UITableView
        let firstCell = list.cellForRow(at: firstIndexPath)!
        XCTAssertTrue(firstCell.isSelected)

        // Deselect first row
        tester().tapRow(at: firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        XCTAssertFalse(firstCell.isSelected)

        // Cancel
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForView(withAccessibilityLabel: "Edit")

        // Select multiple logins
        tester().tapView(withAccessibilityLabel: "Edit")
        tester().waitForAnimationsToFinish()

        let pathsToSelect = (0..<3).map { IndexPath(row: $0, section: 1) }
        pathsToSelect.forEach { path in
            tester().tapRow(at: path, inTableViewWithAccessibilityIdentifier: "Login List")
        }
        tester().waitForView(withAccessibilityLabel: "Delete")

        pathsToSelect.forEach { path in
            XCTAssertTrue(list.cellForRow(at: path)!.isSelected)
        }

        // Deselect only first row
        tester().tapRow(at: firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        XCTAssertFalse(firstCell.isSelected)

        // Make sure delete is still showing
        tester().waitForView(withAccessibilityLabel: "Delete")

        // Deselect the rest
        let pathsWithoutFirst = pathsToSelect[1..<pathsToSelect.count]
        pathsWithoutFirst.forEach { path in
            tester().tapRow(at: path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        // Cancel
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForView(withAccessibilityLabel: "Edit")

        tester().tapView(withAccessibilityLabel: "Edit")

        // Select all using select all button
        tester().tapView(withAccessibilityLabel: "Select All")

        // Now it is needed to scroll so the list is updated and the next assert works
        tester().swipeView(withAccessibilityIdentifier: "SAVED LOGINS", in: KIFSwipeDirection.up)
        tester().waitForAnimationsToFinish()
        list.visibleCells.forEach { cell in
           XCTAssertTrue(cell.isSelected)
        }
        tester().waitForView(withAccessibilityLabel: "Delete")

        // Deselect all using button
        tester().tapView(withAccessibilityLabel: "Deselect All")
        list.visibleCells.forEach { cell in
            XCTAssertFalse(cell.isSelected)
        }
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForView(withAccessibilityLabel: "Edit")

        // Finally, test selections get persisted after cells recycle
        tester().tapView(withAccessibilityLabel: "Edit")
        let firstInEachSection = (0..<3).map { IndexPath(row: $0, section: 1) }
        firstInEachSection.forEach { path in
            tester().tapRow(at: path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        // Go up, down and back up to for some recyling
        tester().scrollView(withAccessibilityIdentifier: "Login List", byFractionOfSizeHorizontal: 0, vertical: 1)
        tester().scrollView(withAccessibilityIdentifier: "Login List", byFractionOfSizeHorizontal: 0, vertical: 1)
        tester().scrollView(withAccessibilityIdentifier: "Login List", byFractionOfSizeHorizontal: 0, vertical: 1)
        tester().wait(forTimeInterval: 1)
        tester().waitForAnimationsToFinish()
        XCTAssertTrue(list.cellForRow(at: firstInEachSection[0])!.isSelected)

        firstInEachSection.forEach { path in
            tester().tapRow(at: path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().waitForView(withAccessibilityLabel: "Edit")

        closeLoginManager()
    }

    func testListSelectAndDelete() {
        openLoginManager()

        var list = tester().waitForView(withAccessibilityIdentifier: "Login List") as! UITableView
        let oldLoginCount = countOfRowsInTableView(list)

        tester().tapView(withAccessibilityLabel: "Edit")
        tester().waitForAnimationsToFinish()

        // Select and delete one entry
        let firstIndexPath = IndexPath(row: 0, section: 2)
        tester().tapRow(at: firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        tester().waitForView(withAccessibilityLabel: "Delete")

        let firstCell = list.cellForRow(at: firstIndexPath)!
        XCTAssertTrue(firstCell.isSelected)

        tester().tapView(withAccessibilityLabel: "Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForView(withAccessibilityLabel: "Are you sure?")
        tester().tapView(withAccessibilityLabel: "Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForView(withAccessibilityLabel: "Settings")
        tester().wait(forTimeInterval: 2) // Wait for the list to be updated
        list = tester().waitForView(withAccessibilityIdentifier: "Login List") as! UITableView
        tester().wait(forTimeInterval: 1)
        var newLoginCount = countOfRowsInTableView(list)
        XCTAssertEqual(oldLoginCount - 1, newLoginCount)

        // Select and delete multiple entries
        tester().tapView(withAccessibilityLabel: "Edit")
        tester().waitForAnimationsToFinish()

        let multiplePaths = (0..<3).map { IndexPath(row: $0, section: 1) }

        multiplePaths.forEach { path in
            tester().tapRow(at: path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        tester().tapView(withAccessibilityLabel: "Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForView(withAccessibilityLabel: "Are you sure?")
        tester().tapView(withAccessibilityLabel: "Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForView(withAccessibilityLabel: "Edit")
        tester().wait(forTimeInterval: 1)
        newLoginCount = countOfRowsInTableView(list)
        XCTAssertEqual(oldLoginCount - 4, newLoginCount)
        closeLoginManager()
    }

    func testSelectAllCancelAndEdit() {
        openLoginManager()

        tester().waitForView(withAccessibilityLabel: "Edit")
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Edit")

        // Select all using select all button
        let list = tester().waitForView(withAccessibilityIdentifier: "Login List") as! UITableView
        tester().tapView(withAccessibilityLabel: "Select All")

        // Now it is needed to scroll so the list is updated and the next assert works
        tester().swipeView(withAccessibilityIdentifier: "SAVED LOGINS", in: KIFSwipeDirection.up)
        tester().waitForAnimationsToFinish()

        list.visibleCells.forEach { cell in
            XCTAssertTrue(cell.isSelected)
        }

        tester().waitForView(withAccessibilityLabel: "Deselect All")
        tester().tapView(withAccessibilityLabel: "Cancel")
        tester().tapView(withAccessibilityLabel: "Edit")

        // Make sure the state of the button is 'Select All' since we cancelled midway previously.
        tester().waitForView(withAccessibilityLabel: "Select All")
        tester().tapView(withAccessibilityLabel: "Cancel")

        closeLoginManager()
    }

    /*
     func testLoginListShowsNoResults() {
     openLoginManager()

     tester().waitForView(withAccessibilityLabel: "a0@email.com, http://a0.com")
     let list = tester().waitForView(withAccessibilityIdentifier: "Login List") as! UITableView
     let oldLoginCount = countOfRowsInTableView(list)

     // Find something that doesn't exist
     tester().tapView(withAccessibilityLabel: "Enter Search Mode")
     tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "")
     tester().enterText(intoCurrentFirstResponder: "asdfasdf")

     // KIFTest has a bug where waitForViewWithAccessibilityLabel causes the lists to appear again on device,
     // so checking the number of rows instead
     XCTAssertEqual(oldLoginCount, 220)
     tester().waitForView(withAccessibilityLabel:"No logins found")

     tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "")

     // Erase search and make sure we see results instead
     tester().waitForView(withAccessibilityLabel: "a0@email.com, http://a0.com")

     closeLoginManager()
     }
     */
    fileprivate func countOfRowsInTableView(_ tableView: UITableView) -> Int {
        var count = 0
        (0..<tableView.numberOfSections).forEach { section in
            count += tableView.numberOfRows(inSection: section)
        }
        return count
    }

    /**
     This requires the software keyboard to display. Make sure 'Connect Hardware Keyboard' is off during testing.
     Disabling since db crash is encountered due to a separate db bug
     */
    /*
     func testEditingDetailUsingReturnForNavigation() {
     openLoginManager()

     tester().waitForView(withAccessibilityLabel: "a0@email.com, http://a0.com")
     tester().tapView(withAccessibilityLabel: "a0@email.com, http://a0.com")

     tester().waitForView(withAccessibilityLabel: "password")

     let list = tester().waitForView(withAccessibilityIdentifier: "Login Detail List") as! UITableView

     tester().tapView(withAccessibilityLabel: "Edit")

     // Check that we've selected the username field
     var firstResponder = UIApplication.shared.keyWindow?.firstResponder()
     let usernameCell = list.cellForRow(at: IndexPath(row: 1, section: 0)) as! LoginTableViewCell
     let usernameField = usernameCell.descriptionLabel

     XCTAssertEqual(usernameField, firstResponder)
     tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "changedusername")
     tester().tapView(withAccessibilityLabel: "Next")

     firstResponder = UIApplication.shared.keyWindow?.firstResponder()
     let passwordCell = list.cellForRow(at: IndexPath(row: 2, section: 0)) as! LoginTableViewCell
     let passwordField = passwordCell.descriptionLabel

     // Check that we've navigated to the password field upon return and that the password is no longer displaying as dots
     XCTAssertEqual(passwordField, firstResponder)
     XCTAssertFalse(passwordField.isSecureTextEntry)

     tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "changedpassword")
     tester().tapView(withAccessibilityLabel: "Done")

     // Go back and find the changed login
     tester().tapView(withAccessibilityLabel: "Back")
     tester().tapView(withAccessibilityLabel: "Enter Search Mode")
     tester().enterText(intoCurrentFirstResponder: "changedusername")

     let loginsList = tester().waitForView(withAccessibilityIdentifier: "Login List") as! UITableView
     XCTAssertEqual(loginsList.numberOfRows(inSection: 0), 1)

     closeLoginManager()
     }
     */
    func testEditingDetailUpdatesPassword() {
        openLoginManager()

        tester().waitForView(withAccessibilityLabel: "http://a0.com")
        EarlGrey.selectElement(with: grey_accessibilityLabel("http://a0.com")).perform(grey_tap())
        tester().waitForView(withAccessibilityLabel: "Password")

        let list = tester().waitForView(withAccessibilityIdentifier: "Login Detail List") as! UITableView
        tester().waitForAnimationsToFinish()
        tester().tapView(withAccessibilityLabel: "Edit")

        // Check that we've selected the username field
        var firstResponder = UIApplication.shared.keyWindow?.firstResponder()

        let usernameCell = list.cellForRow(at: IndexPath(row: 1, section: 0)) as! LoginTableViewCell
        let usernameField = usernameCell.descriptionLabel
        XCTAssertEqual(usernameField, firstResponder)
        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "changedusername")
        tester().tapView(withAccessibilityLabel: "Next")
        firstResponder = UIApplication.shared.keyWindow?.firstResponder()
        var passwordCell = list.cellForRow(at: IndexPath(row: 2, section: 0)) as! LoginTableViewCell
        let passwordField = passwordCell.descriptionLabel

        // Check that we've navigated to the password field upon return and that the password is no longer displaying as dots
        XCTAssertEqual(passwordField, firstResponder)
        XCTAssertFalse(passwordField.isSecureTextEntry)

        tester().clearTextFromAndThenEnterText(intoCurrentFirstResponder: "changedpassword")
        tester().tapView(withAccessibilityLabel: "Done")

        // Tap the 'Reveal' menu option
        EarlGrey.selectElement(with: grey_accessibilityID("passwordField")).perform(grey_tap())
        waitForMatcher(name: "Reveal")

        passwordCell = list.cellForRow(at: IndexPath(row: 2, section: 0)) as! LoginTableViewCell
        XCTAssertEqual(passwordCell.descriptionLabel.text, "changedpassword")

        tester().tapView(withAccessibilityLabel: "Logins & Passwords")
        closeLoginManager()
    }

    func testDeleteLoginFromDetailScreen() {
        openLoginManager()

        let list = tester().waitForView(withAccessibilityIdentifier: "Login List") as! UITableView
        let loginInitialCount = countOfRowsInTableView(list)

        // Both the count and the first element is checked before removing
        tester().waitForView(withAccessibilityLabel: "http://a0.com")
        let loginCountBeforeRemoving = countOfRowsInTableView(list)
        XCTAssertEqual(loginCountBeforeRemoving, loginInitialCount)

        let firstIndexPathBeforeRemoving = IndexPath(row: 0, section: 1)
        let firstCellBeforeRemoving = list.cellForRow(at: firstIndexPathBeforeRemoving)!
        let firstCellLabelBeforeRemoving  = firstCellBeforeRemoving.textLabel?.text as! String
        XCTAssertEqual(firstCellLabelBeforeRemoving, "http://a0.com")

        EarlGrey.selectElement(with: grey_accessibilityLabel("http://a0.com")).perform(grey_tap())
        tester().waitForAnimationsToFinish()
        EarlGrey.selectElement(with: grey_accessibilityLabel("Delete")).perform(grey_tap())
        tester().waitForAnimationsToFinish()
        // Verify that we are looking at the nonsynced alert dialog
        tester().waitForView(withAccessibilityLabel: "Are you sure?")
        tester().waitForView(withAccessibilityLabel: "Logins will be removed from all connected devices.")

        tester().tapView(withAccessibilityLabel: "Delete")
        tester().waitForAnimationsToFinish()

        // Check to verify that the element removed is not there
        EarlGrey.selectElement(with: grey_accessibilityLabel("http://a0.com")).assert(grey_notVisible())
        tester().waitForView(withAccessibilityLabel: "http://a1.com")

        // Both the count and the first element is checked before removing
        let firstIndexPathAfterRemoving = IndexPath(row: 0, section: 1)
        let firstCellAfterRemoving = list.cellForRow(at: firstIndexPathAfterRemoving)!
        let firstCellLabelAfterRemoving  = firstCellAfterRemoving.textLabel?.text as! String
        XCTAssertEqual(firstCellLabelAfterRemoving, "http://a1.com")

        let loginCountAfterRemoving = countOfRowsInTableView(list)
        XCTAssertEqual(loginCountAfterRemoving, loginInitialCount-1)

        closeLoginManager()
    }

    func testLoginDetailDisplaysLastModified() {
        openLoginManager()

        tester().waitForView(withAccessibilityLabel: "http://a0.com")
        EarlGrey.selectElement(with: grey_accessibilityLabel("http://a0.com")).perform(grey_tap())
        tester().waitForView(withAccessibilityLabel: "Password")

        XCTAssertTrue(tester().viewExistsWithLabelPrefixedBy("Created just now"))
        tester().wait(forTimeInterval: 1)
        tester().tapView(withAccessibilityLabel: "Logins & Passwords")
        closeLoginManager()
    }

    func testPreventBlankPasswordInDetail() {
        openLoginManager()

        tester().waitForView(withAccessibilityLabel: "http://a0.com")
        EarlGrey.selectElement(with: grey_accessibilityLabel("http://a0.com")).perform(grey_tap())
        tester().waitForView(withAccessibilityLabel: "Password")

        let list = tester().waitForView(withAccessibilityIdentifier: "Login Detail List") as! UITableView
        tester().wait(forTimeInterval: 1)
        tester().tapView(withAccessibilityLabel: "Edit")

        // Check that we've selected the username field
        tester().tapView(withAccessibilityIdentifier: "usernameField")

        var passwordCell = list.cellForRow(at: IndexPath(row: 2, section: 0)) as! LoginTableViewCell
        var passwordField = passwordCell.descriptionLabel

        tester().tapView(withAccessibilityLabel: "Next")
        tester().waitForAnimationsToFinish()
        tester().clearTextFromView(withAccessibilityIdentifier: "passwordField")
        tester().tapView(withAccessibilityLabel: "Done")

        passwordCell = list.cellForRow(at: IndexPath(row: 2, section: 0)) as! LoginTableViewCell
        passwordField = passwordCell.descriptionLabel

        // Confirm that when entering a blank password we revert back to the original
        XCTAssertEqual(passwordField.text, "passworda0")

        tester().tapView(withAccessibilityLabel: "Logins & Passwords")
        closeLoginManager()
    }

    func testListEditButton() {
        openLoginManager()

        // Check that edit button is enabled when entries are present
        tester().waitForView(withAccessibilityLabel: "Edit")
        tester().tapView(withAccessibilityLabel: "Edit")

        // Select all using select all button
        tester().tapView(withAccessibilityLabel: "Select All")

        // Delete all entries
        tester().waitForView(withAccessibilityLabel: "Delete")
        tester().tapView(withAccessibilityLabel: "Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForView(withAccessibilityLabel: "Are you sure?")
        tester().tapView(withAccessibilityLabel: "Delete")
        tester().waitForAnimationsToFinish()

        // Check that edit button has been disabled
        tester().wait(forTimeInterval: 1)
        tester().waitForView(withAccessibilityLabel: "Edit", traits: UIAccessibilityTraitNotEnabled)

        closeLoginManager()
    }
}
