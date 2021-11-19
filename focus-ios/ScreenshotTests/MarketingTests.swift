/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest


class MarketingTests: BaseTestCaseL10n {

    func testSettingsView() {
        if iPad () {
            app.windows.element(boundBy: 0).tap()
        } else {
            waitForExistence(app.buttons["URLBar.cancelButton"], timeout: 15)
            app.buttons["URLBar.cancelButton"].tap()
        }

        snapshot("Home")
        // Go to ETP Menu
        app.buttons["HomeView.settingsButton"].tap()
        waitForExistence(app.tables.cells["Settings"])
        app.tables.cells["Settings"].tap()
        waitForExistence(app.cells["settingsViewController.trackingCell"])
        app.cells["settingsViewController.trackingCell"].tap()
        snapshot("Settings-TP")

        // Go to Search Engine Menu
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        waitForExistence(app.cells["SettingsViewController.searchCell"])
        app.cells["SettingsViewController.searchCell"].tap()
        waitForExistence(app.cells["DuckDuckGo"])
        app.cells["DuckDuckGo"].tap()
        waitForExistence(app.cells["SettingsViewController.searchCell"])
        app.cells["SettingsViewController.searchCell"].tap()
        snapshot("Settings-SearchEngine")
        waitForExistence(app.cells["DuckDuckGo"])
    }

    func testVisitSite() {
        if iPad () {
            app.windows.element(boundBy: 0).tap()
        } else {
            waitForExistence(app.buttons["URLBar.cancelButton"], timeout: 15)
        }
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText("https://www.mozilla.org/de/firefox/browsers/mobile/focus\n")
        waitForExistence(app.webViews.buttons["Close"])
        app.webViews.buttons["Close"].tap()
        snapshot("Website-Focus")
    }

    func testPinTopSites(){
        if iPad () {
            app.windows.element(boundBy: 0).tap()
        } else {
            waitForExistence(app.buttons["URLBar.cancelButton"], timeout: 15)
        }
        saveTopSite(TopSite: "mozilla.org")
        saveTopSite(TopSite: "pocket.com")
        saveTopSite(TopSite: "relay.com")
        saveTopSite(TopSite: "monitor.com")

        app.buttons["URLBar.deleteButton"].tap()
        waitForExistence(app.buttons["URLBar.cancelButton"], timeout: 15)
        app.buttons["URLBar.cancelButton"].tap()
        snapshot("PinnedSites")
    }

    private func saveTopSite(TopSite: String) {
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText(TopSite)
        app.textFields.firstMatch.typeText("\n")
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        waitForExistence(app.cells["icon_shortcuts_add"])
        app.tables.cells["icon_shortcuts_add"].tap()
    }
}
