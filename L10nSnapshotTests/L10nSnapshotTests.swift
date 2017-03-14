/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class L10nSnapshotTests: L10nBaseSnapshotTests {
    func test02DefaultTopSites() {
        snapshot("02DefaultTopSites-01")
    }

    func test03MenuOnTopSites() {
        let app = XCUIApplication()
        app.buttons["TabToolbar.menuButton"].tap()
        snapshot("03MenuOnTopSites-01")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()

        loadWebPage(url: "about:blank", waitForLoadToFinish: false)
        sleep(2)
        app.buttons["TabToolbar.menuButton"].tap()
        snapshot("10MenuOnWebPage-01")
        app.otherElements["MenuViewController.menuView"].swipeLeft()
        snapshot("10MenuOnWebPage-02")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()

        app.buttons["URLBarView.tabsButton"].tap()
        app.buttons["TabTrayController.menuButton"].tap()
        snapshot("10MenuOnTabsTray-02")
    }

    func test04Foo() {
        let app = XCUIApplication()
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/index.html", waitForOtherElementWithAriaLabel: "body")
        app.buttons["TabToolbar.menuButton"].tap()
        snapshot("10MenuOnWebPage-01")
        app.otherElements["MenuViewController.menuView"].swipeLeft()
        snapshot("10MenuOnWebPage-02")
    }

    func test04Settings() {
        let app = XCUIApplication()
        app.buttons["TabToolbar.menuButton"].tap()
        app.otherElements["MenuViewController.menuView"].swipeLeft()
        app.cells["SettingsMenuItem"].tap()

        // TODO Scroll through the settings and make a screenshot of every page

        // Screenshot all the settings that have a separate page
        for cellName in ["Search", "NewTab", "Homepage", "Logins", "TouchIDPasscode", "ClearPrivateData"] {
            app.tables["AppSettingsTableViewController.tableView"].cells[cellName].tap()
            snapshot("04Settings-\(cellName)")
            app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        }
    }

    func test05PrivateBrowsingTabsEmptyState() {
        let app = XCUIApplication()
        app.buttons["URLBarView.tabsButton"].tap() // Open tabs tray
        app.buttons["TabTrayController.maskButton"].tap() // Switch to private mode
        snapshot("05PrivateBrowsingTabsEmptyState-01")
    }

    func test06PanelsEmptyState() {
        let app = XCUIApplication()
        app.textFields["url"].tap()
        app.buttons["HomePanels.Bookmarks"].tap()
        snapshot("06PanelsEmptyState-01")
        app.buttons["HomePanels.History"].tap()
        snapshot("06PanelsEmptyState-02")
        app.buttons["HistoryPanel.syncedTabsButton"].tap()
        snapshot("06PanelsEmptyState-03")
        app.buttons["HomePanels.ReadingList"].tap()
        snapshot("06PanelsEmptyState-04")
    }

    // From here on it is fine to load pages

    func test07AddSearchProvider() {
        let app = XCUIApplication()
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/addSearchProvider.html", waitForOtherElementWithAriaLabel: "body")
        app.webViews.element(boundBy: 0).buttons["focus"].tap()
        snapshot("07AddSearchProvider-01", waitForLoadingIndicator: false)
        app.buttons["BrowserViewController.customSearchEngineButton"].tap()
        snapshot("07AddSearchProvider-02", waitForLoadingIndicator: false)

        let alert = XCUIApplication().alerts.element(boundBy: 0)
        expectation(for: NSPredicate(format: "exists == 1"), evaluatedWith: alert, handler: nil)
        waitForExpectations(timeout: 3, handler: nil)
        alert.buttons.element(boundBy: 0).tap()
    }

    func test08URLBar() {
        let app = XCUIApplication()
        app.textFields["url"].tap()
        snapshot("08URLBar-01")
        app.textFields["address"].typeText("moz")
        snapshot("08URLBar-02")
    }

    func test09URLBarContextMenu() {
        let app = XCUIApplication()
        // Long press with nothing on the clipboard
        app.textFields["url"].press(forDuration: 2.0)
        snapshot("09LocationBarContextMenu-01")
        app.sheets.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        sleep(2)

        // Long press with a URL on the clipboard
        UIPasteboard.general.string = "https://www.mozilla.com"
        app.textFields["url"].press(forDuration: 2.0)
        snapshot("09LocationBarContextMenu-02")
        app.sheets.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        sleep(2)
    }

    func test10MenuOnWebPage() {
        let app = XCUIApplication()
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/index.html", waitForOtherElementWithAriaLabel: "body")
        app.buttons["TabToolbar.menuButton"].tap()
        snapshot("10MenuOnWebPage-01")
        app.otherElements["MenuViewController.menuView"].swipeLeft()
        snapshot("10MenuOnWebPage-02")
    }

    func test11WebViewContextMenu() {
        let app = XCUIApplication()

        // Link
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/link.html", waitForOtherElementWithAriaLabel: "body")
        app.webViews.element(boundBy: 0).links["link"].press(forDuration: 2.0)
        snapshot("11WebViewContextMenu-01")
        app.sheets.element(boundBy: 0).buttons.element(boundBy: app.sheets.element(boundBy: 0).buttons.count-1).tap()

        // Image
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/image.html", waitForOtherElementWithAriaLabel: "body")
        app.webViews.element(boundBy: 0).images["image"].press(forDuration: 2.0)
        snapshot("11WebViewContextMenu-02")
        app.sheets.element(boundBy: 0).buttons.element(boundBy: app.sheets.element(boundBy: 0).buttons.count-1).tap()

        // Image inside Link
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/imageWithLink.html", waitForOtherElementWithAriaLabel: "body")
        app.webViews.element(boundBy: 0).links["link"].press(forDuration: 2.0)
        snapshot("11WebViewContextMenu-03")
        app.sheets.element(boundBy: 0).buttons.element(boundBy: app.sheets.element(boundBy: 0).buttons.count-1).tap()
    }

    func test12WebViewAuthenticationDialog() {
        loadWebPage(url: "https://people-mozilla.org/~sarentz/fxios/testpages/basicauth/index.html", waitForLoadToFinish: false)
        let predicate = NSPredicate(format: "exists == 1")
        let query = XCUIApplication().alerts.element(boundBy: 0)
        expectation(for: predicate, evaluatedWith: query, handler: nil)
        self.waitForExpectations(timeout: 3, handler: nil)
        snapshot("12WebViewAuthenticationDialog-01", waitForLoadingIndicator: false)
    }

    func test13ReloadButtonContextMenu() {
        let app = XCUIApplication()
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/index.html", waitForOtherElementWithAriaLabel: "body")
        app.buttons["TabToolbar.stopReloadButton"].press(forDuration: 2.0)
        snapshot("13ContextMenuReloadButton-01", waitForLoadingIndicator: false)
        app.sheets.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        app.buttons["TabToolbar.stopReloadButton"].press(forDuration: 2.0)
        snapshot("13ContextMenuReloadButton-02", waitForLoadingIndicator: false)
    }

    func test14SetHompage() {
        let app = XCUIApplication()
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/index.html", waitForOtherElementWithAriaLabel: "body")
        app.buttons["TabToolbar.menuButton"].tap()
        app.cells["SetHomePageMenuItem"].tap()
        snapshot("14SetHomepage-01", waitForLoadingIndicator: false)
    }

    func test17PasswordSnackbar() {
        let app = XCUIApplication()
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/password.html", waitForOtherElementWithAriaLabel: "body")
        app.webViews.element(boundBy: 0).buttons["submit"].tap()
        snapshot("17PasswordSnackbar-01")
        app.buttons["SaveLoginPrompt.saveLoginButton"].tap()
        // The password is pre-filled with a random value so second this this will cause the update prompt
        loadWebPage(url: "http://people.mozilla.org/~sarentz/fxios/testpages/password.html", waitForOtherElementWithAriaLabel: "body")
        app.webViews.element(boundBy: 0).buttons["submit"].tap()
        snapshot("17PasswordSnackbar-02")
    }
}
