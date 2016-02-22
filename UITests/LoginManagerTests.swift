/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Storage
@testable import Client

class LoginManagerTests: KIFTestCase {

    private var webRoot: String!

    override func setUp() {
        webRoot = SimplePageServer.start()
        generateLogins()
    }

    override func tearDown() {
        super.tearDown()
        clearLogins()
    }

    private func openLoginManager() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")
    }

    private func closeLoginManager() {
        tester().tapViewWithAccessibilityLabel("Back")
        tester().tapViewWithAccessibilityLabel("Done")
        tester().tapViewWithAccessibilityLabel("home")
    }

    private func generateLogins() {
        let profile = (UIApplication.sharedApplication().delegate as! AppDelegate).profile!

        let prefixes = "abcdefghijk"
        let numRange = (0..<20)

        let passwords = generateStringListWithFormat("password%@%d", numRange: numRange, prefixes: prefixes)
        let hostnames = generateStringListWithFormat("http://%@%d.com", numRange: numRange, prefixes: prefixes)
        let usernames = generateStringListWithFormat("%@%d@email.com", numRange: numRange, prefixes: prefixes)

        (0..<(numRange.count * prefixes.characters.count)).forEach { index in
            let login = Login(guid: "\(index)", hostname: hostnames[index], username: usernames[index], password: passwords[index])
            login.formSubmitURL = hostnames[index]
            profile.logins.addLogin(login).value
        }
    }

    private func generateStringListWithFormat(format: String, numRange: Range<Int>, prefixes: String) -> [String] {
        return prefixes.characters.map { char in
            return numRange.map { num in
                return String(format: format, "\(char)", num)
            }
        } .flatMap { $0 }
    }

    private func clearLogins() {
        let profile = (UIApplication.sharedApplication().delegate as! AppDelegate).profile!
        profile.logins.removeAll().value
    }

    func testListFiltering() {
        openLoginManager()

        // Filter by username
        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("Enter Search Mode")
        tester().enterTextIntoCurrentFirstResponder("k10@email.com")
        tester().waitForViewWithAccessibilityLabel("k10@email.com")

        var list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        XCTAssertEqual(list.numberOfRowsInSection(0), 1)

        tester().tapViewWithAccessibilityLabel("Clear Search")

        // Filter by hostname
        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("Enter Search Mode")
        tester().enterTextIntoCurrentFirstResponder("http://k10.com")
        tester().waitForViewWithAccessibilityLabel("k10@email.com")

        list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        XCTAssertEqual(list.numberOfRowsInSection(0), 1)

        tester().tapViewWithAccessibilityLabel("Clear Search")

        // Filter by password
        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("Enter Search Mode")
        tester().enterTextIntoCurrentFirstResponder("passwordd9")
        tester().waitForViewWithAccessibilityLabel("d9@email.com")

        list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        XCTAssertEqual(list.numberOfRowsInSection(0), 1)

        tester().tapViewWithAccessibilityLabel("Clear Search")

        // Filter by something that doesn't match anything
        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("Enter Search Mode")
        tester().enterTextIntoCurrentFirstResponder("thisdoesntmatch")

        // TODO: Check for empty view

        closeLoginManager()
    }

    func testListIndexView() {
        openLoginManager()

        // Swipe the index view to navigate to bottom section
        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().swipeViewWithAccessibilityLabel("table index", inDirection: KIFSwipeDirection.Down)
        tester().waitForViewWithAccessibilityLabel("k0@email.com, http://k0.com")
        closeLoginManager()
    }

    func testDetailPasswordMenuOptions() {
        openLoginManager()

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        tester().waitForViewWithAccessibilityLabel("password")

        let list = tester().waitForViewWithAccessibilityIdentifier("Login Detail List") as! UITableView
        var passwordCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! LoginTableViewCell

        // longPressViewWithAcessibilityLabel fails when called directly because the cell is not a descendant in the
        // responder chain since it's a cell so instead use the underlying longPressAtPoint method.
        let centerOfCell = CGPoint(x: passwordCell.frame.width / 2, y: passwordCell.frame.height / 2)
        XCTAssertTrue(passwordCell.descriptionLabel.secureTextEntry)

        // Tap the 'Reveal' menu option
        passwordCell.longPressAtPoint(centerOfCell, duration: 2)
        tester().waitForViewWithAccessibilityLabel("Reveal")
        tester().tapViewWithAccessibilityLabel("Reveal")

        passwordCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! LoginTableViewCell
        XCTAssertFalse(passwordCell.descriptionLabel.secureTextEntry)

        // Tap the 'Hide' menu option
        passwordCell.longPressAtPoint(centerOfCell, duration: 2)
        tester().waitForViewWithAccessibilityLabel("Hide")
        tester().tapViewWithAccessibilityLabel("Hide")

        passwordCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! LoginTableViewCell
        XCTAssertTrue(passwordCell.descriptionLabel.secureTextEntry)

        // Tap the 'Copy' menu option
        passwordCell.longPressAtPoint(centerOfCell, duration: 2)
        tester().waitForViewWithAccessibilityLabel("Copy")
        tester().tapViewWithAccessibilityLabel("Copy")

        XCTAssertEqual(UIPasteboard.generalPasteboard().string, "passworda0")

        tester().tapViewWithAccessibilityLabel("Back")
        closeLoginManager()
    }

    func testDetailWebsiteMenuCopy() {
        openLoginManager()

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        tester().waitForViewWithAccessibilityLabel("password")

        let list = tester().waitForViewWithAccessibilityIdentifier("Login Detail List") as! UITableView
        let websiteCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as! LoginTableViewCell

        // longPressViewWithAcessibilityLabel fails when called directly because the cell is not a descendant in the
        // responder chain since it's a cell so instead use the underlying longPressAtPoint method.
        let centerOfCell = CGPoint(x: websiteCell.frame.width / 2, y: websiteCell.frame.height / 2)

        // Tap the 'Copy' menu option
        websiteCell.longPressAtPoint(centerOfCell, duration: 2)
        tester().waitForViewWithAccessibilityLabel("Copy")
        tester().tapViewWithAccessibilityLabel("Copy")

        XCTAssertEqual(UIPasteboard.generalPasteboard().string, "http://a0.com")

        // Tap the 'Open & Fill' menu option - just checks to make sure we navigate to the web page
        websiteCell.longPressAtPoint(centerOfCell, duration: 2)
        tester().waitForViewWithAccessibilityLabel("Open & Fill")
        tester().tapViewWithAccessibilityLabel("Open & Fill")

        tester().waitForTimeInterval(2)
        tester().waitForViewWithAccessibilityLabel("a0.com")

        BrowserUtils.resetToAboutHome(tester())
    }

    func testOpenAndFillFromNormalContext() {
        openLoginManager()

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        tester().waitForViewWithAccessibilityLabel("password")

        let list = tester().waitForViewWithAccessibilityIdentifier("Login Detail List") as! UITableView
        let websiteCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as! LoginTableViewCell

        // longPressViewWithAcessibilityLabel fails when called directly because the cell is not a descendant in the
        // responder chain since it's a cell so instead use the underlying longPressAtPoint method.
        let centerOfCell = CGPoint(x: websiteCell.frame.width / 2, y: websiteCell.frame.height / 2)

        // Tap the 'Open & Fill' menu option - just checks to make sure we navigate to the web page
        websiteCell.longPressAtPoint(centerOfCell, duration: 2)
        tester().waitForViewWithAccessibilityLabel("Open & Fill")
        tester().tapViewWithAccessibilityLabel("Open & Fill")

        tester().waitForTimeInterval(2)
        tester().waitForViewWithAccessibilityLabel("a0.com")

        BrowserUtils.resetToAboutHome(tester())
    }

    func testOpenAndFillFromPrivateContext() {
        tester().tapViewWithAccessibilityLabel("Show Tabs")
        tester().tapViewWithAccessibilityLabel("Private Mode")

        tester().tapViewWithAccessibilityLabel("Settings")
        tester().tapViewWithAccessibilityLabel("Logins")

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        tester().waitForViewWithAccessibilityLabel("password")

        let list = tester().waitForViewWithAccessibilityIdentifier("Login Detail List") as! UITableView
        let websiteCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 3, inSection: 0)) as! LoginTableViewCell

        // longPressViewWithAcessibilityLabel fails when called directly because the cell is not a descendant in the
        // responder chain since it's a cell so instead use the underlying longPressAtPoint method.
        let centerOfCell = CGPoint(x: websiteCell.frame.width / 2, y: websiteCell.frame.height / 2)

        // Tap the 'Open & Fill' menu option - just checks to make sure we navigate to the web page
        websiteCell.longPressAtPoint(centerOfCell, duration: 2)
        tester().waitForViewWithAccessibilityLabel("Open & Fill")
        tester().tapViewWithAccessibilityLabel("Open & Fill")

        tester().waitForTimeInterval(2)
        tester().waitForViewWithAccessibilityLabel("a0.com")

        BrowserUtils.resetToAboutHome(tester())
    }

    func testDetailUsernameMenuOptions() {
        openLoginManager()

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        tester().waitForViewWithAccessibilityLabel("password")

        let list = tester().waitForViewWithAccessibilityIdentifier("Login Detail List") as! UITableView
        let usernameCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! LoginTableViewCell

        // longPressViewWithAcessibilityLabel fails when called directly because the cell is not a descendant in the
        // responder chain since it's a cell so instead use the underlying longPressAtPoint method.
        let centerOfCell = CGPoint(x: usernameCell.frame.width / 2, y: usernameCell.frame.height / 2)

        // Tap the 'Copy' menu option
        usernameCell.longPressAtPoint(centerOfCell, duration: 2)
        tester().waitForViewWithAccessibilityLabel("Copy")
        tester().tapViewWithAccessibilityLabel("Copy")

        XCTAssertEqual(UIPasteboard.generalPasteboard().string, "a0@email.com")

        tester().tapViewWithAccessibilityLabel("Back")
        closeLoginManager()
    }

    func testListSelection() {
        openLoginManager()

        tester().tapViewWithAccessibilityLabel("Edit")
        tester().waitForAnimationsToFinish()

        // Select one entry
        let firstIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        tester().tapRowAtIndexPath(firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        tester().waitForViewWithAccessibilityLabel("Delete")

        let list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        let firstCell = list.cellForRowAtIndexPath(firstIndexPath)!
        XCTAssertTrue(firstCell.selected)

        // Deselect first row
        tester().tapRowAtIndexPath(firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        XCTAssertFalse(firstCell.selected)

        // Cancel
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Edit")

        // Select multiple logins
        tester().tapViewWithAccessibilityLabel("Edit")
        tester().waitForAnimationsToFinish()

        let pathsToSelect = (0..<3).map { NSIndexPath(forRow: $0, inSection: 0) }
        pathsToSelect.forEach { path in
            tester().tapRowAtIndexPath(path, inTableViewWithAccessibilityIdentifier: "Login List")
        }
        tester().waitForViewWithAccessibilityLabel("Delete")

        pathsToSelect.forEach { path in
            XCTAssertTrue(list.cellForRowAtIndexPath(path)!.selected)
        }

        // Deselect only first row
        tester().tapRowAtIndexPath(firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        XCTAssertFalse(firstCell.selected)

        // Make sure delete is still showing
        tester().waitForViewWithAccessibilityLabel("Delete")

        // Deselect the rest
        let pathsWithoutFirst = pathsToSelect[1..<pathsToSelect.count]
        pathsWithoutFirst.forEach { path in
            tester().tapRowAtIndexPath(path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        // Cancel
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Edit")

        tester().tapViewWithAccessibilityLabel("Edit")

        // Select all using select all button
        tester().tapViewWithAccessibilityLabel("Select All")
        list.visibleCells.forEach { cell in
            XCTAssertTrue(cell.selected)
        }
        tester().waitForViewWithAccessibilityLabel("Delete")

        // Deselect all using button
        tester().tapViewWithAccessibilityLabel("Deselect All")
        list.visibleCells.forEach { cell in
            XCTAssertFalse(cell.selected)
        }
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Edit")

        // Finally, test selections get persisted after cells recycle
        tester().tapViewWithAccessibilityLabel("Edit")
        let firstInEachSection = (0..<3).map { NSIndexPath(forRow: 0, inSection: $0) }
        firstInEachSection.forEach { path in
            tester().tapRowAtIndexPath(path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        // Go up, down and back up to for some recyling
        tester().scrollViewWithAccessibilityIdentifier("Login List", byFractionOfSizeHorizontal: 0, vertical: 1)
        tester().scrollViewWithAccessibilityIdentifier("Login List", byFractionOfSizeHorizontal: 0, vertical: -1)
        tester().scrollViewWithAccessibilityIdentifier("Login List", byFractionOfSizeHorizontal: 0, vertical: 1)

        XCTAssertTrue(list.cellForRowAtIndexPath(firstInEachSection[0])!.selected)

        firstInEachSection.forEach { path in
            tester().tapRowAtIndexPath(path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().waitForViewWithAccessibilityLabel("Edit")

        closeLoginManager()
    }

    func testListSelectAndDelete() {
        openLoginManager()

        let list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        let oldLoginCount = countOfRowsInTableView(list)

        tester().tapViewWithAccessibilityLabel("Edit")
        tester().waitForAnimationsToFinish()

        // Select and delete one entry
        let firstIndexPath = NSIndexPath(forRow: 0, inSection: 0)
        tester().tapRowAtIndexPath(firstIndexPath, inTableViewWithAccessibilityIdentifier: "Login List")
        tester().waitForViewWithAccessibilityLabel("Delete")

        let firstCell = list.cellForRowAtIndexPath(firstIndexPath)!
        XCTAssertTrue(firstCell.selected)

        tester().tapViewWithAccessibilityLabel("Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForViewWithAccessibilityLabel("Are you sure?")
        tester().tapViewWithAccessibilityLabel("Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForViewWithAccessibilityLabel("Edit")

        var newLoginCount = countOfRowsInTableView(list)
        XCTAssertEqual(oldLoginCount - 1, newLoginCount)

        // Select and delete multiple entries
        tester().tapViewWithAccessibilityLabel("Edit")
        tester().waitForAnimationsToFinish()

        let multiplePaths = (0..<3).map { NSIndexPath(forRow: $0, inSection: 0) }

        multiplePaths.forEach { path in
            tester().tapRowAtIndexPath(path, inTableViewWithAccessibilityIdentifier: "Login List")
        }

        tester().tapViewWithAccessibilityLabel("Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForViewWithAccessibilityLabel("Are you sure?")
        tester().tapViewWithAccessibilityLabel("Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForViewWithAccessibilityLabel("Edit")

        newLoginCount = countOfRowsInTableView(list)
        XCTAssertEqual(oldLoginCount - 4, newLoginCount)
        closeLoginManager()
    }

    func testSelectAllCancelAndEdit() {
        openLoginManager()

        tester().waitForViewWithAccessibilityLabel("Edit")
        tester().tapViewWithAccessibilityLabel("Edit")

        // Select all using select all button
        let list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        tester().tapViewWithAccessibilityLabel("Select All")
        list.visibleCells.forEach { cell in
            XCTAssertTrue(cell.selected)
        }

        tester().waitForViewWithAccessibilityLabel("Deselect All")
        tester().tapViewWithAccessibilityLabel("Cancel")
        tester().tapViewWithAccessibilityLabel("Edit")

        // Make sure the state of the button is 'Select All' since we cancelled mid-way previously.
        tester().waitForViewWithAccessibilityLabel("Select All")

        tester().tapViewWithAccessibilityLabel("Cancel")

        closeLoginManager()
    }

    func testLoginListShowsNoResults() {
        openLoginManager()

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        // Find something that doesn't exist
        tester().tapViewWithAccessibilityLabel("Enter Search Mode")
        tester().enterTextIntoCurrentFirstResponder("asdfasdf")
        tester().waitForViewWithAccessibilityLabel("No logins found")

        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("")

        // Erase search and make sure we see results instead
        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        closeLoginManager()
    }

    private func countOfRowsInTableView(tableView: UITableView) -> Int {
        var count = 0
        (0..<tableView.numberOfSections).forEach { section in
            count += tableView.numberOfRowsInSection(section)
        }
        return count
    }

    /**
     This requires the software keyboard to display. Make sure 'Connect Hardware Keyboard' is off during testing.
     */
    func testEditingDetailUsingReturnForNavigation() {
        openLoginManager()

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        tester().waitForViewWithAccessibilityLabel("password")

        let list = tester().waitForViewWithAccessibilityIdentifier("Login Detail List") as! UITableView

        tester().tapViewWithAccessibilityLabel("Edit")

        // Check that we've selected the username field
        var firstResponder = UIApplication.sharedApplication().keyWindow?.firstResponder()
        let usernameCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! LoginTableViewCell
        let usernameField = usernameCell.descriptionLabel

        XCTAssertEqual(usernameField, firstResponder)
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("changedusername")
        tester().tapViewWithAccessibilityLabel("Next")

        firstResponder = UIApplication.sharedApplication().keyWindow?.firstResponder()
        let passwordCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! LoginTableViewCell
        let passwordField = passwordCell.descriptionLabel

        // Check that we've navigated to the password field upon return and that the password is no longer displaying as dots
        XCTAssertEqual(passwordField, firstResponder)
        XCTAssertFalse(passwordField.secureTextEntry)

        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("changedpassword")
        tester().tapViewWithAccessibilityLabel("Done")

        // Go back and find the changed login
        tester().tapViewWithAccessibilityLabel("Back")
        tester().tapViewWithAccessibilityLabel("Enter Search Mode")
        tester().enterTextIntoCurrentFirstResponder("changedusername")

        let loginsList = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        XCTAssertEqual(loginsList.numberOfRowsInSection(0), 1)

        closeLoginManager()
    }

    func testEditingDetailUpdatesPassword() {
        openLoginManager()

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        tester().waitForViewWithAccessibilityLabel("password")

        let list = tester().waitForViewWithAccessibilityIdentifier("Login Detail List") as! UITableView

        tester().tapViewWithAccessibilityLabel("Edit")

        // Check that we've selected the username field
        var firstResponder = UIApplication.sharedApplication().keyWindow?.firstResponder()
        let usernameCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 0)) as! LoginTableViewCell
        let usernameField = usernameCell.descriptionLabel

        XCTAssertEqual(usernameField, firstResponder)
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("changedusername")
        tester().tapViewWithAccessibilityLabel("Next")

        firstResponder = UIApplication.sharedApplication().keyWindow?.firstResponder()
        var passwordCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! LoginTableViewCell
        let passwordField = passwordCell.descriptionLabel

        // Check that we've navigated to the password field upon return and that the password is no longer displaying as dots
        XCTAssertEqual(passwordField, firstResponder)
        XCTAssertFalse(passwordField.secureTextEntry)

        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("changedpassword")
        tester().tapViewWithAccessibilityLabel("Done")

        // longPressViewWithAcessibilityLabel fails when called directly because the cell is not a descendant in the
        // responder chain since it's a cell so instead use the underlying longPressAtPoint method.
        let centerOfCell = CGPoint(x: passwordCell.frame.width / 2, y: passwordCell.frame.height / 2)
        XCTAssertTrue(passwordCell.descriptionLabel.secureTextEntry)

        // Tap the 'Reveal' menu option
        passwordCell.longPressAtPoint(centerOfCell, duration: 2)
        tester().waitForViewWithAccessibilityLabel("Reveal")
        tester().tapViewWithAccessibilityLabel("Reveal")

        passwordCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! LoginTableViewCell
        XCTAssertEqual(passwordCell.descriptionLabel.text, "changedpassword")

        tester().tapViewWithAccessibilityLabel("Back")
        closeLoginManager()
    }

    func testDeleteLoginFromDetailScreen() {

        openLoginManager()

        var list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        var firstRow = list.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! LoginTableViewCell
        XCTAssertEqual(firstRow.descriptionLabel.text, "http://a0.com")

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("Delete")

        // Verify that we are looking at the non-synced alert dialog
        tester().waitForViewWithAccessibilityLabel("Are you sure?")
        tester().waitForViewWithAccessibilityLabel("Logins will be permanently removed.")

        tester().tapViewWithAccessibilityLabel("Delete")
        tester().waitForAnimationsToFinish()

        list = tester().waitForViewWithAccessibilityIdentifier("Login List") as! UITableView
        firstRow = list.cellForRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0)) as! LoginTableViewCell
        XCTAssertEqual(firstRow.descriptionLabel.text, "http://a1.com")

        closeLoginManager()
    }

    func testLoginDetailDisplaysLastModified() {
        openLoginManager()

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        tester().waitForViewWithAccessibilityLabel("password")

        XCTAssertTrue(tester().viewExistsWithLabelPrefixedBy("Last modified"))
        tester().tapViewWithAccessibilityLabel("Back")
        closeLoginManager()
    }

    func testPreventBlankPasswordInDetail() {
        openLoginManager()

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        tester().waitForViewWithAccessibilityLabel("password")

        let list = tester().waitForViewWithAccessibilityIdentifier("Login Detail List") as! UITableView

        tester().tapViewWithAccessibilityLabel("Edit")

        // Check that we've selected the username field
        var passwordCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! LoginTableViewCell
        var passwordField = passwordCell.descriptionLabel

        tester().tapViewWithAccessibilityLabel("Next")
        tester().clearTextFromAndThenEnterTextIntoCurrentFirstResponder("")
        tester().tapViewWithAccessibilityLabel("Done")

        passwordCell = list.cellForRowAtIndexPath(NSIndexPath(forRow: 2, inSection: 0)) as! LoginTableViewCell
        passwordField = passwordCell.descriptionLabel

        // Confirm that when entering a blank password we revert back to the original
        XCTAssertEqual(passwordField.text, "passworda0")

        tester().tapViewWithAccessibilityLabel("Back")
        closeLoginManager()
    }

    func testListEditButton() {
        openLoginManager()

        // Check that edit button is enabled when entries are present
        tester().waitForViewWithAccessibilityLabel("Edit")
        tester().tapViewWithAccessibilityLabel("Edit")

        // Select all using select all button
        tester().tapViewWithAccessibilityLabel("Select All")

        // Delete all entries
        tester().waitForViewWithAccessibilityLabel("Delete")
        tester().tapViewWithAccessibilityLabel("Delete")
        tester().waitForAnimationsToFinish()

        tester().waitForViewWithAccessibilityLabel("Are you sure?")
        tester().tapViewWithAccessibilityLabel("Delete")
        tester().waitForAnimationsToFinish()

        // Check that edit button has been disabled
        tester().waitForViewWithAccessibilityLabel("Edit", traits: UIAccessibilityTraitNotEnabled)

        closeLoginManager()
    }
}
