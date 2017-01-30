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
let SearchSettings = "SearchSettings"
let NewTabSettings = "NewTabSettings"
let ClearPrivateDataSettings = "ClearPrivateDataSettings"
let LoginsSettings = "LoginsSettings"
let OpenWithSettings = "OpenWithSettings"
let NewTabScreen = "NewTabScreen"
let NewTabMenu = "NewTabMenu"

let allSettingsScreens = [
    SettingsScreen,
    HomePageSettings,
    PasscodeSettings,
    SearchSettings,
    NewTabSettings,
    ClearPrivateDataSettings,
    LoginsSettings,
    OpenWithSettings,
]

func createScreenGraph(_ app: XCUIApplication, url: String = "https://www.mozilla.org/en-US/book/") -> ScreenGraph {
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
        // This is used for opening BrowserTab with default mozilla URL
        // For custom URL, should use Navigator.openNewURL
        scene.gesture(to: BrowserTab) {
            app.textFields["url"].tap()
            app.textFields["address"].typeText(url + "\r")
        }

        scene.tap(app.buttons["TabToolbar.menuButton"], to: NewTabMenu)
        scene.gesture(to: TabTray) {
            app.buttons["URLBarView.tabsButton"].tap()
        }
    }

    map.createScene(NewTabMenu) { scene in
        scene.gesture(to: SettingsScreen) {
            app.collectionViews.cells["SettingsMenuItem"].tap()
        }
        scene.tap(app.buttons["Close Menu"], to: NewTabScreen)
        scene.dismissOnUse = true
    }

    let navigationControllerBackAction = {
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
    }

    map.createScene(SettingsScreen) { scene in
        let table = app.tables["AppSettingsTableViewController.tableView"]

        scene.tap(table.cells["Search"], to: SearchSettings)
        scene.tap(table.cells["NewTab"], to: NewTabSettings)
        scene.tap(table.cells["Homepage"], to: HomePageSettings)
        scene.tap(table.cells["TouchIDPasscode"], to: PasscodeSettings)
        scene.tap(table.cells["Logins"], to: LoginsSettings)
        scene.tap(table.cells["ClearPrivateData"], to: ClearPrivateDataSettings)
        scene.tap(table.cells["OpenWith.Setting"], to: OpenWithSettings)

        scene.backAction = navigationControllerBackAction
    }

    map.createScene(SearchSettings) { scene in
        scene.backAction = navigationControllerBackAction
    }

    map.createScene(NewTabSettings) { scene in
        scene.backAction = navigationControllerBackAction
    }

    map.createScene(HomePageSettings) { scene in
        scene.backAction = navigationControllerBackAction
    }

    map.createScene(PasscodeSettings) { scene in
        scene.backAction = navigationControllerBackAction
        
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

    map.createScene(ClearPrivateDataSettings) { scene in
        scene.backAction = navigationControllerBackAction
    }

    map.createScene(OpenWithSettings) { scene in
        scene.backAction = navigationControllerBackAction
    }

    map.createScene(TabTray) { scene in
        scene.gesture(to: TabTrayMenu) {
            app.buttons["TabTrayController.menuButton"].tap()
        }
        scene.gesture(to: NewTabScreen) {
            app.buttons["TabTrayController.addTabButton"].tap()
        }
    }

    map.createScene(TabTrayMenu) { scene in
        scene.gesture(to: SettingsScreen) {
            let collectionViewsQuery = app.collectionViews
            collectionViewsQuery.cells["SettingsMenuItem"].tap()
        }
        scene.tap(app.buttons["Close Menu"], to: TabTray)
        scene.dismissOnUse = true
    }

    map.createScene(BrowserTab) { scene in
        scene.tap(app.buttons["TabToolbar.menuButton"], to: BrowserTabMenu)
        scene.gesture(to: TabTray) {
            app.buttons["URLBarView.tabsButton"].tap()
        }
    }

    map.createScene(BrowserTabMenu) { scene in
        scene.tap(app.buttons["Close Menu"], to: BrowserTab)
        scene.gesture(to: BrowserTabMenu2) {
            app.otherElements["MenuViewController.menuView"].swipeLeft()
        }
        scene.dismissOnUse = true
    }

    map.createScene(BrowserTabMenu2) { scene in
        scene.gesture(to: SettingsScreen) {
            let collectionViewsQuery = app.collectionViews
            collectionViewsQuery.cells["SettingsMenuItem"].tap()
        }
        scene.gesture(to: BrowserTabMenu) {
            app.otherElements["MenuViewController.menuView"].swipeRight()
        }
        scene.tap(app.buttons["Close Menu"], to: BrowserTab)
        scene.dismissOnUse = true
    }

    map.initialSceneName = FirstRun

    return map
}

// For visiting BrowserTab with specific URL.
// Invoking this method in BrowserTab will create another tab,
// as that is the shortest path to itself
extension Navigator {
    func openNewURL(urlString: String) {
        self.goto(NewTabScreen)
        let app = XCUIApplication()
        app.textFields["url"].tap()
        app.textFields["address"].typeText(urlString + "\r")
        self.nowAt(BrowserTab)
    }
}
