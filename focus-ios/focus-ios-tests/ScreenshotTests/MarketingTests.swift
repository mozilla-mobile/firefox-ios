/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

class MarketingTests: BaseTestCaseL10n {
    @MainActor
    func testDummy() {
        // This test without taking any screenshot is a workaround so that the
        // simulator is warmed up before testPinTopSites(). Without warming up
        // the simulator, testPinTopSites() fails intermittently.
        waitForExistence(app.buttons["URLBar.cancelButton"], timeout: 60)
    }

    @MainActor
    func testSettingsView() {
        if iPad() {
            app.windows.element(boundBy: 0).tap()
        } else {
            waitForExistence(app.buttons["URLBar.cancelButton"], timeout: 15)
            app.buttons["URLBar.cancelButton"].tap()
        }

        snapshot("Home")
        // Go to ETP Menu
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        app.images["icon_settings"].tap()
        waitForExistence(app.tables.cells["settingsViewController.defaultBrowserCell"])
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

    @MainActor
    func testVisitSite() {
        if iPad() {
            app.windows.element(boundBy: 0).tap()
        } else {
            waitForExistence(app.buttons["URLBar.cancelButton"], timeout: 15)
        }
        waitForExistence(app.textFields.firstMatch)
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText("https://www.mozilla.org/de/firefox/browsers/mobile/focus\n")
        waitForNoExistence(app.progressIndicators.firstMatch, timeoutValue: 45)
        snapshot("Website-Focus")
    }

    @MainActor
    func testPinTopSites() {
        if iPad() {
            app.windows.element(boundBy: 0).tap()
        } else {
            waitForExistence(app.buttons["URLBar.cancelButton"], timeout: 15)
        }
        saveTopSite(TopSite: "mozilla.org")
        saveTopSite(TopSite: "pocket.com")
        saveTopSite(TopSite: "relay.firefox.com")
        saveTopSite(TopSite: "monitor.mozilla.org")

        app.buttons["URLBar.deleteButton"].tap()
        waitForExistence(app.buttons["URLBar.cancelButton"], timeout: 15)
        app.buttons["URLBar.cancelButton"].tap()
        snapshot("PinnedSites")
    }

    private func saveTopSite(TopSite: String) {
        app.textFields.firstMatch.tap()
        app.textFields.firstMatch.typeText(TopSite)
        app.textFields.firstMatch.typeText("\n")
        waitForNoExistence(app.progressIndicators.firstMatch, timeoutValue: 60)
        waitForExistence(app.buttons["HomeView.settingsButton"])
        app.buttons["HomeView.settingsButton"].tap()
        waitForExistence(app.collectionViews.images["icon_settings"])
        waitForExistence(app.collectionViews.images["icon_shortcuts_add"])
        app.collectionViews.images["icon_shortcuts_add"].tap()
    }
}
