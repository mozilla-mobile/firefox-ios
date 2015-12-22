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

        tester().waitForViewWithAccessibilityLabel("password, passworda0")

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

    func testDetailWebsiteMenuOptions() {
        openLoginManager()

        tester().waitForViewWithAccessibilityLabel("a0@email.com, http://a0.com")
        tester().tapViewWithAccessibilityLabel("a0@email.com, http://a0.com")

        tester().waitForViewWithAccessibilityLabel("password, passworda0")

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
}