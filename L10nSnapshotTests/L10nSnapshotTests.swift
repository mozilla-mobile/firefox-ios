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
        app.launch()
    }

    // TODO Refactor this into a common superlcass for snapshots
    func loadWebPage(url: String, waitForLoadToFinish: Bool = true) {
        let LoadingTimeout: NSTimeInterval = 60
        let exists = NSPredicate(format: "exists = true")
        let loaded = NSPredicate(format: "value BEGINSWITH '100'")

        let app = XCUIApplication()

        UIPasteboard.generalPasteboard().string = url
        app.textFields["url"].pressForDuration(2.0)
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()

        if waitForLoadToFinish {
            let progressIndicator = app.progressIndicators.elementBoundByIndex(0)
            expectationForPredicate(exists, evaluatedWithObject: progressIndicator, handler: nil)
            expectationForPredicate(loaded, evaluatedWithObject: progressIndicator, handler: nil)
            waitForExpectationsWithTimeout(LoadingTimeout, handler: nil)
        }
    }

    func test01Intro() {
        let app = XCUIApplication()
        snapshot("01Intro-1")
        app.swipeLeft()
        sleep(2)
        snapshot("01Intro-2")
        app.swipeLeft()
        sleep(2)
        snapshot("01Intro-3")
        app.swipeLeft()
        sleep(2)
        snapshot("01Intro-4")
        app.swipeLeft()
        sleep(2)
        snapshot("01Intro-5")
    }

    func test02DefaultTopSites() {
        snapshot("02DefaultTopSites-01")
    }

    func test03Settings() {
        let app = XCUIApplication()
        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.settingsButton"].tap()

        var index = 1

        // Screenshot the settings by scrolling through it
        snapshot("03Settings-\(index)")
        let element = app.images["SettingsTableFooterView.logo"]
        while !element.visible() {
            app.swipeUp()
            sleep(2)
            index += 1
            snapshot("03Settings-\(index)")
        }

        // Screenshot all the settings that have a separate page
        for cellName in ["Search", "Logins", "TouchIDPasscode", "ClearPrivateData"] {
            app.tables["AppSettingsTableViewController.tableView"].cells[cellName].tap()
            index++
            snapshot("03Settings-\(index)")
            app.navigationBars.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()
        }
    }

    func test04PrivateBrowsingTabsEmptyState() {
        let app = XCUIApplication()
        app.buttons["URLBarView.tabsButton"].tap() // Open tabs tray
        app.buttons["TabTrayController.togglePrivateMode"].tap() // Switch to private mode
        snapshot("04PrivateBrowsingTabsEmptyState-01")
    }

    func test05PanelsEmptyState() {
        let app = XCUIApplication()
        app.textFields["url"].tap()
        app.buttons["HomePanels.Bookmarks"].tap()
        snapshot("05PanelsEmptyState-01")
        app.buttons["HomePanels.History"].tap()
        snapshot("05PanelsEmptyState-02")
        app.buttons["HomePanels.SyncedTabs"].tap()
        snapshot("05PanelsEmptyState-03")
        app.buttons["HomePanels.ReadingList"].tap()
        snapshot("05PanelsEmptyState-04")
    }

    func test06URLBar() {
        let app = XCUIApplication()
        app.textFields["url"].tap()
        snapshot("06URLBar-01")
        app.textFields["address"].typeText("moz")
        snapshot("06URLBar-02")
    }

    func test07URLBarContextMenu() {
        let app = XCUIApplication()
        // Long press with nothing on the clipboard
        app.textFields["url"].pressForDuration(2.0)
        snapshot("07LocationBarContextMenu-01")
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()
        sleep(2)

        // Long press with a URL on the clipboard
        UIPasteboard.generalPasteboard().string = "https://www.mozilla.com"
        app.textFields["url"].pressForDuration(2.0)
        snapshot("07LocationBarContextMenu-02")
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()
        sleep(2)
    }

    func test08WebViewContextMenu() {
        let app = XCUIApplication()

        // TODO Do we have more types of content that trigger a different kind of context menu?
        let urls = [
            "http://people.mozilla.org/~sarentz/fxios/testpages/link.html",
            "http://people.mozilla.org/~sarentz/fxios/testpages/image.html",
            "http://people.mozilla.org/~sarentz/fxios/testpages/imageWithLink.html"
        ]

        for (index, url) in urls.enumerate() {
            loadWebPage(url)
            let webView = app.webViews.elementBoundByIndex(0)
            let coordinate = webView.coordinateWithNormalizedOffset(CGVector(dx: 0.01, dy: 0.01))
            coordinate.pressForDuration(2.0)
            snapshot("08WebViewContextMenu-\(index + 1)")
            // TODO Is there a nicer way to tap the bottom button in a sheet?
            app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(app.sheets.elementBoundByIndex(0).buttons.count-1).tap()
        }
    }

    func test09WebViewAuthenticationDialog() {
        loadWebPage("https://phonebook.mozilla.org", waitForLoadToFinish: false)
        let predicate = NSPredicate(format: "exists == 1")
        let query = XCUIApplication().alerts.elementBoundByIndex(0)
        expectationForPredicate(predicate, evaluatedWithObject: query, handler: nil)
        self.waitForExpectationsWithTimeout(3, handler: nil)
        snapshot("09WebViewAuthenticationDialog-01", waitForLoadingIndicator: false)
    }

    func test10ReloadButtonContextMenu() {
        let app = XCUIApplication()
        loadWebPage("http://people.mozilla.org")
        app.buttons["BrowserToolbar.stopReloadButton"].pressForDuration(2.0)
        snapshot("10ContextMenuReloadButton-01", waitForLoadingIndicator: false)
        app.sheets.elementBoundByIndex(0).buttons.elementBoundByIndex(0).tap()
        app.buttons["BrowserToolbar.stopReloadButton"].pressForDuration(2.0)
        snapshot("10ContextMenuReloadButton-02", waitForLoadingIndicator: false)
    }

    func test11LocationDialog() {
        loadWebPage("http://people.mozilla.org/~sarentz/fxios/testpages/geolocation.html")
        snapshot("11LocationDialog-01")
        // TODO The load seems to dismiss the dialog and prevent it from showing for next test.
        loadWebPage("http://people.mozilla.org")
    }

    func test50ClearPrivateData() {
        let app = XCUIApplication()
        var index = 1

        func mySnapshot(name: String) {
            snapshot(name)
            index += 1
        }

        func clearPrivateData() {
            let clearPrivateDataCell = app.tables.cells["ClearPrivateData"]
            clearPrivateDataCell.tap()
            mySnapshot("50ClearPrivateData-\(index)")
            let clearPrivateDataButton = app.tables.cells["ClearPrivateData"]
            clearPrivateDataButton.tap()
            mySnapshot("50ClearPrivateData-\(index)")
            let button = app.alerts.elementBoundByIndex(0).collectionViews.buttons.elementBoundByIndex(0)
            button.tap()
            let navBar = app.navigationBars.elementBoundByIndex(0)
            navBar.buttons.elementBoundByIndex(0).tap()
        }

        let loginUsername = "testtesto@mockmyid.com"
        let loginPassword = "testtesto@mockmyid.com"

        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.settingsButton"].tap()

        mySnapshot("50ClearPrivateData-\(index)")

        var logOutCell = app.tables.cells["LogOut"]
        if logOutCell.exists {
            logOutCell.tap()
            app.alerts.elementBoundByIndex(0).collectionViews.buttons.elementBoundByIndex(1).tap()
        }

        clearPrivateData()

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

        addUIInterruptionMonitorWithDescription("Location Dialog") { (alert) -> Bool in
            mySnapshot("50ClearPrivateData-\(index)")
            alert.buttons.elementBoundByIndex(1).tap()
            return true
        }

        app.webViews.buttons.elementBoundByIndex(0).tap()

        mySnapshot("50ClearPrivateData-\(index)")

        clearPrivateData()

        logOutCell = app.tables.cells["LogOut"]
        app.tables.elementBoundByIndex(0).scrollToElement(logOutCell)
        mySnapshot("50ClearPrivateData-\(index)")
        logOutCell.tap()
        mySnapshot("50ClearPrivateData-\(index)")
        app.alerts.elementBoundByIndex(0).collectionViews.buttons.elementBoundByIndex(1).tap()
        mySnapshot("50ClearPrivateData-\(index)")
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
