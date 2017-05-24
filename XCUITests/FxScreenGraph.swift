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
let URLBarOpen = "URLBarOpen"
let NewPrivateTabScreen = "NewPrivateTabScreen"
let PrivateTabTray = "PrivateTabTray"
let PrivateBrowserTab = "PrivateBrowserTab"

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

let Intro_Organize = "Intro.Organize"
let Intro_Customize = "Intro.Customize"
let Intro_Share = "Intro.Share"
let Intro_Choose = "Intro.Choose"
let Intro_Sync = "Intro.Sync"

let allIntroPages = [
    Intro_Organize,
    Intro_Customize,
    Intro_Share,
    Intro_Choose,
    Intro_Sync,
]

let HomePanelsScreen = "HomePanels"
let HomePanel_TopSites = "HomePanel.TopSites.0"
let HomePanel_Bookmarks = "HomePanel.Bookmarks.1"
let HomePanel_History = "HomePanel.History.2"
let HomePanel_ReadingList = "HomePanel.ReadingList.3"

let allHomePanels = [
    HomePanel_Bookmarks,
    HomePanel_TopSites,
    HomePanel_History,
    HomePanel_ReadingList,
]

let ContextMenu_ReloadButton = "ContextMenu_ReloadButton"

func createScreenGraph(_ app: XCUIApplication, url: String = "https://www.mozilla.org/en-US/book/") -> ScreenGraph {
    let map = ScreenGraph()

    let startBrowsingButton = app.buttons["IntroViewController.startBrowsingButton"]
    map.createScene(FirstRun) { scene in
        scene.gesture(to: NewTabScreen) {
            if startBrowsingButton.exists {
                startBrowsingButton.tap()
            }
        }

        scene.noop(to: allIntroPages[0])
    }

    // Add the intro screens.
    var i = 0
    let introLast = allIntroPages.count - 1
    let introPager = app.scrollViews["IntroViewController.scrollView"]
    for intro in allIntroPages {
        let prev = i == 0 ? nil : allIntroPages[i - 1]
        let next = i == introLast ? nil : allIntroPages[i + 1]

        map.createScene(intro) { scene in
            if let prev = prev {
                scene.swipeRight(introPager, to: prev)
            }

            if let next = next {
                scene.swipeLeft(introPager, to: next)
            }

            scene.tap(startBrowsingButton, to: NewTabScreen)
        }

        i += 1
    }

    map.createScene(NewTabScreen) { scene in
        scene.tap(app.textFields["url"], to: URLBarOpen)
        scene.tap(app.buttons["TabToolbar.menuButton"], to: NewTabMenu)
        scene.tap(app.buttons["URLBarView.tabsButton"], to: TabTray)

        scene.noop(to: HomePanelsScreen)
    }

    map.createScene(NewPrivateTabScreen) { scene in
        scene.tap(app.textFields["url"], to: URLBarOpen)
        scene.tap(app.buttons["TabToolbar.menuButton"], to: NewTabMenu)
        scene.tap(app.buttons["URLBarView.tabsButton"], to: PrivateTabTray)

        scene.noop(to: HomePanelsScreen)
    }

    map.createScene(URLBarOpen) { scene in
        // This is used for opening BrowserTab with default mozilla URL
        // For custom URL, should use Navigator.openNewURL or Navigator.openURL.
        scene.typeText(url + "\r", into: app.textFields["address"], to: BrowserTab)
        scene.backAction = {
            app.buttons["Cancel"].tap()
        }
    }

    let noopAction = {}
    map.createScene(HomePanelsScreen) { scene in
        scene.tap(app.buttons["HomePanels.TopSites"], to: HomePanel_TopSites)
        scene.tap(app.buttons["HomePanels.Bookmarks"], to: HomePanel_Bookmarks)
        scene.tap(app.buttons["HomePanels.History"], to: HomePanel_History)
        scene.tap(app.buttons["HomePanels.ReadingList"], to: HomePanel_ReadingList)
    }

    allHomePanels.forEach { name in
        // Tab panel means that all the home panels are available all the time, so we can 
        // fake this out by a noop back to the HomePanelsScreen which can get to every other panel.
        map.createScene(name) { scene in
            scene.backAction = noopAction
        }
    }

    let closeMenuAction = {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
    }

    map.createScene(NewTabMenu) { scene in
        scene.gesture(to: SettingsScreen) {
            // XXX The element is fails the existence test, so we tap it through the gesture() escape hatch.
            app.collectionViews.cells["SettingsMenuItem"].tap()
        }
        scene.backAction = closeMenuAction
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
        scene.tap(table.cells["ShowTour"], to: Intro_Organize)

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

    map.createScene(PrivateTabTray) { scene in
        scene.tap(app.buttons["TabTrayController.menuButton"], to: TabTrayMenu)
        scene.tap(app.buttons["TabTrayController.addTabButton"], to: NewPrivateTabScreen)
        scene.tap(app.buttons["TabTrayController.maskButton"], to: TabTray)
    }

    map.createScene(TabTray) { scene in
        scene.tap(app.buttons["TabTrayController.menuButton"], to: TabTrayMenu)
        scene.tap(app.buttons["TabTrayController.addTabButton"], to: NewTabScreen)
        scene.tap(app.buttons["TabTrayController.maskButton"], to: PrivateTabTray)
    }

    map.createScene(TabTrayMenu) { scene in
        scene.gesture(to: SettingsScreen) {
            // XXX The element is fails the existence test, so we tap it through the gesture() escape hatch.
            app.collectionViews.cells["SettingsMenuItem"].tap()
        }

        scene.backAction = closeMenuAction
        scene.dismissOnUse = true
    }

    map.createScene(BrowserTab) { scene in
        scene.tap(app.textFields["url"], to: URLBarOpen)
        scene.tap(app.buttons["TabToolbar.menuButton"], to: BrowserTabMenu)
        scene.tap(app.buttons["URLBarView.tabsButton"], to: TabTray)
    }

    map.createScene(PrivateBrowserTab) { scene in
        scene.tap(app.textFields["url"], to: URLBarOpen)
        scene.tap(app.buttons["TabToolbar.menuButton"], to: BrowserTabMenu)
        scene.tap(app.buttons["URLBarView.tabsButton"], to: PrivateTabTray)
    }

    map.createScene(BrowserTabMenu) { scene in
        scene.backAction = closeMenuAction
        // XXX Testing for the element causes an error, so we use the more
        // generic `gesture` method which does not test for the existence
        // before swiping.
        scene.gesture(to: BrowserTabMenu2) {
            app.otherElements["MenuViewController.menuView"].swipeLeft()
        }
        scene.dismissOnUse = true
    }

    map.createScene(BrowserTabMenu2) { scene in
        // XXX Testing for the element causes an error, so we use the more
        // generic `gesture` method which does not test for the existence
        // before swiping.
        scene.gesture(to: BrowserTabMenu) {
            app.otherElements["MenuViewController.menuView"].swipeRight()
        }
        scene.tap(app.collectionViews.cells["SettingsMenuItem"], to: SettingsScreen)
        scene.backAction = closeMenuAction
        scene.dismissOnUse = true
    }

    let cancelContextMenuAction = {
        let buttons = app.sheets.element(boundBy: 0).buttons
        buttons.element(boundBy: buttons.count-1).tap()
    }

    map.initialSceneName = FirstRun

    return map
}

extension Navigator {
    // Open a URL. Will use/re-use the first BrowserTab or NewTabScreen it comes to.
    func openURL(urlString: String) {
        self.goto(URLBarOpen)
        let app = XCUIApplication()
        app.textFields["address"].typeText(urlString + "\r")
        self.nowAt(BrowserTab)
    }

    // Opens a URL in a new tab.
    func openNewURL(urlString: String) {
        self.goto(NewTabScreen)
        self.openURL(urlString: urlString)
    }

    // Closes all Tabs from the option in TabTrayMenu
    func closeAllTabs() {
        self.goto(TabTrayMenu)
        let app = XCUIApplication()
        app.collectionViews.cells["CloseAllTabsMenuItem"].tap()
        self.nowAt(NewTabScreen)
    }

    // Add a new Tab from the New Tab option in Browser Tab Menu
    func createNewTab() {
        self.goto(NewTabMenu)
        let app = XCUIApplication()
        app.collectionViews.cells["NewTabMenuItem"].tap()
        self.nowAt(NewTabScreen)
    }

    // Add Tab(s) from the Tab Tray
    func createSeveralTabsFromTabTray(numberTabs: Int) {
        for _ in 1...numberTabs {
            self.goto(NewTabScreen)
            self.goto(TabTray)
        }
    }

    func browserPerformAction(_ view: BrowserPerformAction) {
        let page1Options = [.requestDesktop, .requestMobile, .findInPageOption, .requestSetHomePage, .addBookmarkOption, .removeBookmarkOption, .openNewTabOption, BrowserPerformAction.openNewPrivateTabOption]
        let page2Options = [.requestNightMode, .requestDayMode, .requestHideImages, .requestShowImages, BrowserPerformAction.openSettingsOption]

        let app = XCUIApplication()

        if page1Options.contains(view) {
            self.goto(BrowserTabMenu)
            app.collectionViews.cells[view.rawValue].tap()
        } else if page2Options.contains(view) {
            self.goto(BrowserTabMenu2)
            app.collectionViews.cells[view.rawValue].tap()
        }
    }
}
enum BrowserPerformAction: String {
    // BrowserTabMenu Page 1
    case requestDesktop = "RequestDesktopMenuItem"
    case requestMobile = "RequestMobileMenuItem"
    case findInPageOption = "FindInPageMenuItem"
    case requestSetHomePage = "SetHomePageMenuItem"
    case addBookmarkOption  = "AddBookmarkMenuItem"
    case removeBookmarkOption = "RemoveBookmarkMenuItem"
    // These two cases below added for completeness and to check a particular use case, like that the button works and takes to the correct place, but do NOT use them in a complex test case, use the other way (navigator.goto(....)) to open a new tab/new private tab
    case openNewTabOption = "NewTabMenuItem"
    case openNewPrivateTabOption = "NewPrivateTabMenuItem"

    // BrowserTabMenu Page 2
    case requestNightMode = "HideNightModeItem"
    case requestDayMode = "ShowNightModeItem"
    case requestHideImages = "HideImageModeMenuItem"
    case requestShowImages = "ShowImageModeMenuItem"
    // Same comment as above, this case added for completeness
    case openSettingsOption = "SettingsMenuItem"
}
