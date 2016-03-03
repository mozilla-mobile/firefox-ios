/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

/**
 * IMPORTANT THING TO NOTE WHEN WRITING TESTS IN THIS CLASS:
 * Does your test run in more than 1 language?
 * If your test will only run successfully in 1 language then this test WILL NOT WORK
 * for the l10n snapshots as they will be run in EVERY LANGUAGE we localise for.
 * When writing your test, run against at least 2 different languages before submitting for Code Review.
 * Thank You.
 */
class L10nSnapshotTests: XCTestCase {

    override func setUp() {
        super.setUp()

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launchEnvironment["MOZ_SKIP_WHATSNEW"] = "YES"
        app.launch()
    }

    func test01Intro() {
        let app = XCUIApplication()
        snapshot("Intro-1")
        app.swipeLeft()
        sleep(2)
        snapshot("Intro-2")
        app.swipeLeft()
        sleep(2)
        snapshot("Intro-3")
        app.swipeLeft()
        sleep(2)
        snapshot("Intro-4")
        app.swipeLeft()
        sleep(2)
        snapshot("Intro-5")
    }

    func test02DefaultTopSites() {
        snapshot("DefaultTopSites-01")
    }

    func test03Settings() {
        let app = XCUIApplication()
        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.settingsButton"].tap()

        var index = 1

        // Screenshot the settings by scrolling through it
        snapshot("Settings-\(index)")
        let element = app.images["SettingsTableFooterView.logo"]
        while !element.visible() {
            app.swipeUp()
            sleep(2)
            index += 1
            snapshot("Settings-\(index)")
        }

        // Screenshot all the settings that have a
        for cellName in ["Search", "Logins", "TouchIDPasscode", "ClearPrivateData"] {
            app.tables.cells[cellName].tap()
            index++
            snapshot("Settings-\(index)")
            app.navigationBars.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()
        }
    }

    func test04PrivateBrowsingTabsEmptyState() {
        let app = XCUIApplication()
        app.buttons["URLBarView.tabsButton"].tap() // Open tabs tray
        app.buttons["TabTrayController.togglePrivateMode"].tap() // Switch to private mode
        snapshot("PrivateBrowsingTabsEmptyState-01")
    }

    func test05PanelsEmptyState() {
        let app = XCUIApplication()
        app.textFields["url"].tap()
        app.buttons["HomePanels.Bookmarks"].tap()
        snapshot("PanelsEmptyState-01")
        app.buttons["HomePanels.History"].tap()
        snapshot("PanelsEmptyState-02")
        app.buttons["HomePanels.SyncedTabs"].tap()
        snapshot("PanelsEmptyState-03")
        app.buttons["HomePanels.ReadingList"].tap()
        snapshot("PanelsEmptyState-04")
    }

    func test06URLBar() {
        let app = XCUIApplication()
        app.textFields["url"].tap()
        snapshot("URLBar-01")
        app.textFields["address"].typeText("moz")
        snapshot("URLBar-02")
    }

    func test07URLBarContextMenu() {
        let app = XCUIApplication()
        // Long press with nothing on the clipboard
        app.textFields["url"].pressForDuration(2.0)
        snapshot("LocationBarContextMenu-01")
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()
        sleep(2)

        // Long press with a URL on the clipboard
        UIPasteboard.generalPasteboard().string = "https://www.mozilla.com"
        app.textFields["url"].pressForDuration(2.0)
        snapshot("LocationBarContextMenu-02")
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()
        sleep(2)
    }

    func test99ClearPrivateData() {

        let loginUsername = "testtesto@mockmyid.com"
        let loginPassword = "testtesto@mockmyid.com"


        let app = XCUIApplication()
        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.settingsButton"].tap()

        snapshot("990SettingsTopNoAccount")

        var logOutCell = app.tables.cells["LogOut"]
        if logOutCell.exists {
            logOutCell.tap()
            app.alerts.elementBoundByIndex(0).collectionViews.buttons.elementBoundByIndex(1).tap()
        }

        clearPrivateData(prefix: "99", position: 1, postfix: "NoAccount")

        app.tables.cells["SignInToFirefox"].tap()

        let passwordField = app.webViews.secureTextFields.elementBoundByIndex(0)
        let exists = NSPredicate(format: "exists == 1")
        expectationForPredicate(exists, evaluatedWithObject: passwordField, handler: nil)

        waitForExpectationsWithTimeout(10, handler: nil)

        let usernameField = app.webViews.textFields.elementBoundByIndex(0)
        if !usernameField.exists {
            app.webViews.links.elementBoundByIndex(1).tap()
            expectationForPredicate(exists, evaluatedWithObject: usernameField, handler: nil)
            waitForExpectationsWithTimeout(10, handler: nil)
        }
        usernameField.tap()
        usernameField.typeText(loginUsername)

        passwordField.tap()
        sleep(2)
        passwordField.typeText(loginPassword)
        app.webViews.buttons.elementBoundByIndex(0).tap()

        snapshot("993SettingsTopWithAccount")

        clearPrivateData(prefix: "99", position: 4, postfix: "WithAccount")

        logOutCell = app.tables.cells["LogOut"]
        app.tables.elementBoundByIndex(0).scrollToElement(logOutCell)
        snapshot("996SettingsBottomWithAccount")
        logOutCell.tap()
        snapshot("997LogOutConfirm")
        app.alerts.elementBoundByIndex(0).collectionViews.buttons.elementBoundByIndex(1).tap()
        snapshot("998SettingsBottomNoAccount")
    }

    private func clearPrivateData(prefix prefix: String, var position: Int, postfix: String = "") {

        let app = XCUIApplication()

        let clearPrivateDataCell = app.tables.cells["ClearPrivateData"]
        clearPrivateDataCell.tap()
        snapshot("\(prefix)\(position++)ClearPrivateData\(postfix)")

        let clearPrivateDataButton = app.tables.cells["ClearPrivateData"]
        clearPrivateDataButton.tap()
        snapshot("\(prefix)\(position++)ClearPrivateDataConfirm\(postfix)")

        let button = app.alerts.elementBoundByIndex(0).collectionViews.buttons.elementBoundByIndex(0)
        button.tap()

        let navBar = app.navigationBars.elementBoundByIndex(0)
        navBar.buttons.elementBoundByIndex(0).tap()
    }
}

extension XCUIElement {

    func scrollToElement(element: XCUIElement) {
        while !element.visible() {
            swipeUp()
        }
    }

    func visible() -> Bool {
        guard self.exists && !CGRectIsEmpty(self.frame) else { return false }
        return CGRectContainsRect(XCUIApplication().windows.elementBoundByIndex(0).frame, self.frame)
    }

}
