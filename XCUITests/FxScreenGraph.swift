/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import XCTest

let SettingsScreen = "SettingsScreen"
let TabTray = "TabTray"
let TabTrayMenu = "TabTrayMenu"
let BrowserTab = "BrowserTab"
let BrowserTabMenu = "BrowserTabMenu"
let BrowserTabMenu2 = "BrowserTabMenu2"
let FirstRun = "OptionalFirstRun"
let HomePageSettings = "HomePageSettings"
let PasscodeSettings = "PasscodeSettings"
let PasscodeIntervalSettings = "PasscodeIntervalSettings"
let LoginsSettings = "LoginsSettings"
let NewTabScreen = "NewTabScreen"
let NewTabMenu = "NewTabMenu"

func createScreenGraph(app: XCUIApplication, url: String = "https://www.mozilla.org/en-US/book/") -> ScreenGraph {
    let map = ScreenGraph(app)

    map.createScene(FirstRun) { scene in
        scene.gesture(to: NewTabScreen) {
            let firstRunUI = app.buttons["Start Browsing"]
            if (firstRunUI.exists) {
                firstRunUI.tap()
            }
        }
    }

    map.createScene(NewTabScreen) { scene in
        scene.gesture(to: BrowserTab) {
            app.textFields["url"].tap()
            app.textFields["address"].typeText(url + "\r")
        }

        scene.tap(app.buttons["TabToolbar.menuButton"], to: NewTabMenu)
    }

    map.createScene(NewTabMenu) { scene in
        scene.gesture(to: SettingsScreen) {
            let collectionViewsQuery = app.collectionViews
            collectionViewsQuery.cells["SettingsMenuItem"].tap()
        }
        scene.tap(app.buttons["Close Menu"], to: NewTabScreen)
        scene.dismissOnUse = true
    }

    map.createScene(SettingsScreen) { scene in
        let table = app.tables["AppSettingsTableViewController.tableView"]

        scene.tap(table.staticTexts["Homepage"], to: HomePageSettings)
        scene.tap(table.cells["TouchIDPasscode"], to: PasscodeSettings)
        scene.tap(table.cells["Logins"], to: LoginsSettings)

        scene.backAction = {
            app.navigationBars["Settings"].buttons["AppSettingsTableViewController.navigationItem.leftBarButtonItem"].tap()
        }
    }

    map.createScene(HomePageSettings) { scene in
        scene.backAction = {
            app.navigationBars["Homepage Settings"].buttons["Settings"].tap()
        }
    }

    map.createScene(PasscodeSettings) { scene in
        scene.tap(app.navigationBars["Passcode"].buttons["Settings"], to: SettingsScreen)

        scene.tap(app.tables["AuthenticationManager.settingsTableView"].staticTexts["Require Passcode"], to: PasscodeIntervalSettings)
    }

    map.createScene(PasscodeIntervalSettings) { scene in
        // The test is likely to know what it needs to do here.
        // This screen is protected by a passcode and is essentially modal.
        scene.gesture(to: PasscodeSettings) {
            if app.navigationBars["Require Passcode"].exists {
                // Go back, accepting modifications
                app.navigationBars["Require Passcode"].buttons["Passcode"].tap()
            } else {
                // Cancel
                app.navigationBars["Enter Passcode"].buttons["Cancel"].tap()
            }
        }
    }

    map.createScene(LoginsSettings) { scene in
        scene.gesture(to: SettingsScreen) {
            let loginList = app.tables["Login List"]
            if loginList.exists {
                app.navigationBars["Logins"].buttons["Settings"].tap()
            } else {
                app.navigationBars["Enter Passcode"].buttons["Cancel"].tap()
            }
        }
    }

    map.createScene(TabTray) { scene in
    }

    map.createScene(TabTrayMenu) { scene in
        scene.tap(app.buttons["Close Menu"], to: TabTray)
    }

    map.createScene(BrowserTab) { scene in
        scene.tap(app.buttons["TabToolbar.menuButton"], to: BrowserTabMenu)

        scene.tap(app.buttons["Show Tabs"], to: TabTray)
    }

    map.createScene(BrowserTabMenu) { scene in
        scene.tap(app.buttons["Close Menu"], to: BrowserTab)
        scene.tap(app.pageIndicators["page 1 of 2"], to: BrowserTabMenu2)
        scene.dismissOnUse = true
    }

    map.createScene(BrowserTabMenu2) { scene in
        scene.gesture(to: SettingsScreen) {
            let collectionViewsQuery = app.collectionViews
            collectionViewsQuery.cells["SettingsMenuItem"].tap()
        }
        scene.dismissOnUse = true
    }

    map.initialSceneName = FirstRun

    return map
}
