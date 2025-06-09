// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// swiftlint:disable all

import Common
import Foundation
import MappaMundi
import XCTest


func createScreenGraph(for test: XCTestCase, with app: XCUIApplication) -> MMScreenGraph<FxUserState> {
    let map = MMScreenGraph(for: test, with: FxUserState.self)

    NavigationRegistry.registerAll(in: map, app: app)

    [WebImageContextMenu, WebLinkContextMenu].forEach { item in
        map.addScreenState(item) { screenState in
            screenState.dismissOnUse = true
            screenState.backAction = {
                let window = XCUIApplication().windows.element(boundBy: 0)
                window.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
            }
        }
    }
    
    return map
}


// MARK: - State Constants

let FirstRun = "OptionalFirstRun"
let TabTray = "TabTray"
let PrivateTabTray = "PrivateTabTray"
let NewTabScreen = "NewTabScreen"
let URLBarOpen = "URLBarOpen"
let URLBarLongPressMenu = "URLBarLongPressMenu"
let ReloadLongPressMenu = "ReloadLongPressMenu"
let PrivateURLBarOpen = "PrivateURLBarOpen"
let BrowserTab = "BrowserTab"
let PrivateBrowserTab = "PrivateBrowserTab"
let BrowserTabMenu = "BrowserTabMenu"
let ToolsMenu = "ToolsMenu"
let FindInPage = "FindInPage"
let SettingsScreen = "SettingsScreen"
let SyncSettings = "SyncSettings"
let FxASigninScreen = "FxASigninScreen"
let FxCreateAccount = "FxCreateAccount"
let FxAccountManagementPage = "FxAccountManagementPage"
let Intro_FxASigninEmail = "Intro_FxASigninEmail"
let HomeSettings = "HomeSettings"
let ToolbarSettings = "ToolbarSettings"
let SiriSettings = "SiriSettings"
let SearchSettings = "SearchSettings"
let NewTabSettings = "NewTabSettings"
let TabsSettings = "TabsSettings"
let ClearPrivateDataSettings = "ClearPrivateDataSettings"
let WebsiteDataSettings = "WebsiteDataSettings"
let WebsiteSearchDataSettings = "WebsiteSearchDataSettings"
let LoginsSettings = "LoginsSettings"
let MailAppSettings = "MailAppSettings"
let ShowTourInSettings = "ShowTourInSettings"
let TrackingProtectionSettings = "TrackingProtectionSettings"
let Intro_FxASignin = "Intro_FxASignin"
let WebImageContextMenu = "WebImageContextMenu"
let WebLinkContextMenu = "WebLinkContextMenu"
let CloseTabMenu = "CloseTabMenu"
let AddCustomSearchSettings = "AddCustomSearchSettings"
let TabTrayLongPressMenu = "TabTrayLongPressMenu"
let HistoryRecentlyClosed = "HistoryRecentlyClosed"
let TrackingProtectionContextMenuDetails = "TrackingProtectionContextMenuDetails"
let DisplaySettings = "DisplaySettings"
let HomePanel_Library = "HomePanel_Library"
let MobileBookmarks = "MobileBookmarks"
let MobileBookmarksEdit = "MobileBookmarksEdit"
let MobileBookmarksAdd = "MobileBookmarksAdd"
let EnterNewBookmarkTitleAndUrl = "EnterNewBookmarkTitleAndUrl"
let RequestDesktopSite = "RequestDesktopSite"
let RequestMobileSite = "RequestMobileSite"
let CreditCardsSettings = "AutofillCreditCard"
let PageZoom = "PageZoom"
let NotificationsSettings = "NotificationsSetting"
let AddressesSettings = "AutofillAddress"
let ToolsBrowserTabMenu = "ToolsBrowserTabMenu"
let SaveBrowserTabMenu = "SaveBrowserTabMenu"
let BrowsingSettings = "BrowsingSettings"
let AutofillPasswordSettings = "AutofillPasswordSettings"
let Shortcuts = "Shortcuts"
let AutoplaySettings = "AutoplaySettings"

let HistoryPanelContextMenu = "HistoryPanelContextMenu"
let TopSitesPanelContextMenu = "TopSitesPanelContextMenu"

let BasicAuthDialog = "BasicAuthDialog"
let BookmarksPanelContextMenu = "BookmarksPanelContextMenu"

let Intro_Welcome = "Intro.Welcome"
let Intro_Sync = "Intro.Sync"

let allIntroPages = [Intro_Welcome, Intro_Sync]

let HomePanelsScreen = "HomePanels"
let PrivateHomePanelsScreen = "PrivateHomePanels"
let HomePanel_TopSites = "HomePanel.TopSites.0"
let LibraryPanel_Bookmarks = "LibraryPanel.Bookmarks.1"
let LibraryPanel_History = "LibraryPanel.History.2"
let LibraryPanel_ReadingList = "LibraryPanel.ReadingList.3"
let LibraryPanel_Downloads = "LibraryPanel.Downloads.4"

let allSettingsScreens = [
    SearchSettings,
    AddCustomSearchSettings,
    NewTabSettings,
    MailAppSettings,
    DisplaySettings,
    ClearPrivateDataSettings,
    TrackingProtectionSettings,
    NotificationsSettings
]

let allHomePanels = [
    LibraryPanel_Bookmarks,
    LibraryPanel_History,
    LibraryPanel_ReadingList,
    LibraryPanel_Downloads
]

let iOS_Settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

func navigationControllerBackAction(for app: XCUIApplication) ->  () -> Void {
    return {
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).waitAndTap()
    }
}

func cancelBackAction(for app: XCUIApplication) ->  () -> Void {
    return {
        app.otherElements["PopoverDismissRegion"].waitAndTap()
    }
}

func dismissContextMenuAction(app: XCUIApplication) ->  () -> Void {
    return {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
    }
}

func select(rows: Int, in app: XCUIApplication) {
    app.staticTexts[String(rows)].firstMatch.waitAndTap()
}

func type(text: String, in app: XCUIApplication) {
     text.forEach { char in
         app.keys[String(char)].waitAndTap()
      }
}

class Action {
    static let LoadURL = "LoadURL"
    static let LoadURLByTyping = "LoadURLByTyping"
    static let LoadURLByPasting = "LoadURLByPasting"

    static let SetURL = "SetURL"
    static let SetURLByTyping = "SetURLByTyping"
    static let SetURLByPasting = "SetURLByPasting"

    static let TrackingProtectionContextMenu = "TrackingProtectionContextMenu"
    static let TrackingProtectionperSiteToggle = "TrackingProtectionperSiteToggle"

    static let ReloadURL = "ReloadURL"

    static let OpenNewTabFromTabTray = "OpenNewTabFromTabTray"
    static let AcceptRemovingAllTabs = "AcceptRemovingAllTabs"

    static let ToggleRegularMode = "ToggleRegularMode"
    static let TogglePrivateMode = "TogglePrivateBrowing"
    static let ToggleSyncMode = "ToggleSyncMode"
    static let TogglePrivateModeFromTabBarHomePanel = "TogglePrivateModeFromTabBarHomePanel"
    static let TogglePrivateModeFromTabBarBrowserTab = "TogglePrivateModeFromTabBarBrowserTab"
    static let TogglePrivateModeFromTabBarNewTab = "TogglePrivateModeFromTabBarNewTab"
    static let ToggleExperimentRegularMode = "ToggleExperimentRegularMode"
    static let ToggleExperimentPrivateMode = "ToggleExperimentPrivateBrowing"
    static let ToggleExperimentSyncMode = "ToggleExperimentSyncMode"

    static let ToggleRequestDesktopSite = "ToggleRequestDesktopSite"
    static let ToggleNightMode = "ToggleNightMode"
    static let ToggleTrackingProtection = "ToggleTrackingProtection"
    static let ToggleNoImageMode = "ToggleNoImageMode"

    static let ToggleInactiveTabs = "ToggleInactiveTabs"
    static let ToggleTabGroups = "ToggleTabGroups"

    static let Bookmark = "Bookmark"
    static let BookmarkThreeDots = "BookmarkThreeDots"

    static let OpenPrivateTabLongPressTabsButton = "OpenPrivateTabLongPressTabsButton"
    static let OpenNewTabLongPressTabsButton = "OpenNewTabLongPressTabsButton"

    static let TogglePocketInNewTab = "TogglePocketInNewTab"
    static let ToggleHistoryInNewTab = "ToggleHistoryInNewTab"
    static let ToggleRecentlySaved = "ToggleRecentlySaved"

    static let SelectNewTabAsBlankPage = "SelectNewTabAsBlankPage"
    static let SelectNewTabAsFirefoxHomePage = "SelectNewTabAsFirefoxHomePage"
    static let SelectNewTabAsCustomURL = "SelectNewTabAsCustomURL"

    static let SelectHomeAsFirefoxHomePage = "SelectHomeAsFirefoxHomePage"
    static let SelectHomeAsCustomURL = "SelectHomeAsCustomURL"
    static let SelectTopSitesRows = "SelectTopSitesRows"

    static let GoToHomePage = "GoToHomePage"
    static let ClickSearchButton = "ClickSearchButton"

    static let OpenSiriFromSettings = "OpenSiriFromSettings"

    static let AcceptClearPrivateData = "AcceptClearPrivateData"
    static let AcceptClearAllWebsiteData = "AcceptClearAllWebsiteData"
    static let TapOnFilterWebsites = "TapOnFilterWebsites"
    static let ShowMoreWebsiteDataEntries = "ShowMoreWebsiteDataEntries"

    static let ClearRecentHistory = "ClearRecentHistory"

    static let ToggleTrackingProtectionPerTabEnabled = "ToggleTrackingProtectionPerTabEnabled"
    static let OpenSettingsFromTPMenu = "OpenSettingsFromTPMenu"
    static let SwitchETP = "SwitchETP"
    static let CloseTPContextMenu = "CloseTPContextMenu"
    static let EnableStrictMode = "EnableStrictMode"
    static let EnableStandardMode = "EnableStandardMode"

    static let CloseTab = "CloseTab"
    static let CloseTabFromTabTrayLongPressMenu = "CloseTabFromTabTrayLongPressMenu"

    static let OpenEmailToSignIn = "OpenEmailToSignIn"
    static let OpenEmailToQR = "OpenEmailToQR"

    static let FxATypeEmail = "FxATypeEmail"
    static let FxATypePasswordNewAccount = "FxATypePasswordNewAccount"
    static let FxATypePasswordExistingAccount = "FxATypePasswordExistingAccount"
    static let FxATapOnSignInButton = "FxATapOnSignInButton"
    static let FxATapOnContinueButton = "FxATapOnContinueButton"

    static let PinToTopSitesPAM = "PinToTopSitesPAM"
    static let CopyAddressPAM = "CopyAddressPAM"
    static let ShareBrowserTabMenuOption = "ShareBrowserTabMenuOption"
    static let SentToDevice = "SentToDevice"
    static let AddToReadingListBrowserTabMenu = "AddToReadingListBrowserTabMenu"

    static let SelectAutomatically = "SelectAutomatically"
    static let SelectManually = "SelectManually"
    static let SystemThemeSwitch = "SystemThemeSwitch"
    
    static let SelectAutomaticTheme = "SelectAutomaticTheme"
    static let SelectLightTheme = "SelectLightTheme"
    static let SelectDarkTheme = "SelectDarkTheme"
    static let SelectBrowserDarkTheme = "SelectBrowserDarkTheme"

    static let AddCustomSearchEngine = "AddCustomSearchEngine"
    static let RemoveCustomSearchEngine = "RemoveCustomSearchEngine"

    static let ExitMobileBookmarksFolder = "ExitMobileBookmarksFolder"
    static let CloseBookmarkPanel = "CloseBookmarkPanel"
    static let CloseReadingListPanel = "CloseReadingListPanel"
    static let CloseHistoryListPanel = "CloseHistoryListPanel"
    static let CloseDownloadsPanel = "CloseDownloadsPanel"
    static let CloseSyncedTabsPanel = "CloseSyncedTabsPanel"

    static let AddNewBookmark = "AddNewBookmark"
    static let AddNewFolder = "AddNewFolder"
    static let AddNewSeparator = "AddNewSeparator"
    static let RemoveItemMobileBookmarks = "RemoveItemMobileBookmarks"
    static let ConfirmRemoveItemMobileBookmarks = "ConfirmRemoveItemMobileBookmarks"
    static let SaveCreatedBookmark = "SaveCreatedBookmark"

    static let OpenWhatsNewPage = "OpenWhatsNewPage"
    static let OpenSearchBarFromSearchButton = "OpenSearchBarFromSearchButton"
    static let CloseURLBarOpen = "CloseURLBarOpen"

    static let SelectToolbarBottom = "SelectToolbarBottom"
    static let SelectToolbarTop = "SelectToolbarTop"
    static let SelectShortcuts = "TopSitesSettings"
}

private let defaultURL = "https://www.mozilla.org/en-US/book/"

extension MMNavigator where T == FxUserState {
    func openURL(_ urlString: String, waitForLoading: Bool = true) {
        UIPasteboard.general.string = urlString
        userState.url = urlString
        userState.waitForLoading = waitForLoading
        performAction(Action.LoadURLByTyping)
    }

    func mozWaitForElementToExist(_ element: XCUIElement, timeout: TimeInterval? = TIMEOUT) {
        let startTime = Date()

        while !element.exists {
            if let timeout = timeout, Date().timeIntervalSince(startTime) > timeout {
                XCTFail("Timed out waiting for element \(element) to exist")
                break
            }
            usleep(10000)
        }
    }

    // Opens a URL in a new tab.
    func openNewURL(urlString: String) {
        let app = XCUIApplication()
        mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 10)

        self.goto(TabTray)
        createNewTab()
        self.openURL(urlString)
    }

    // Add a new Tab from the New Tab option in Browser Tab Menu
    func createNewTab() {
        let app = XCUIApplication()
        self.goto(TabTray)
        app.buttons[AccessibilityIdentifiers.TabTray.newTabButton].waitAndTap()
        self.nowAt(NewTabScreen)
    }

    // Add Tab(s) from the Tab Tray
    func createSeveralTabsFromTabTray(numberTabs: Int) {
        let app = XCUIApplication()
        for _ in 1...numberTabs {
            mozWaitForElementToExist(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], timeout: 5)
            self.goto(TabTray)
            self.goto(HomePanelsScreen)
        }
    }
}

extension XCUIElement {
    /// For tables only: scroll the table downwards until
    /// the end is reached.
    /// Each time a whole screen has scrolled, the passed closure is
    /// executed with the index number of the screen.
    /// Care is taken to make sure that every cell is completely on screen
    /// at least once.
    func forEachScreen(_ eachScreen: (Int) -> Void) {
        guard self.elementType == .table else {
            return
        }

        func firstInvisibleCell(_ start: UInt) -> UInt {
            let cells = self.cells
            for i in start ..< UInt(cells.count) {
                let cell = cells.element(boundBy: Int(i))
                // if the cell's bottom is beyond the table's bottom
                // i.e. if the cell isn't completely visible.
                if self.frame.maxY <= cell.frame.maxY {
                    return i
                }
            }

            return UInt.min
        }

        var cellNum: UInt = 0
        var screenNum = 0

        while true {
            eachScreen(screenNum)

            let firstCell = self.cells.element(boundBy: Int(cellNum))
            cellNum = firstInvisibleCell(cellNum)
            if cellNum == UInt.min {
                return
            }

            let lastCell = self.cells.element(boundBy: Int(cellNum))
            let bottom: XCUICoordinate
            // If the cell is a little bit on the table.
            // We shouldn't drag from too close to the edge of the screen,
            // because Control Center gets summoned.
            if lastCell.frame.minY < self.frame.maxY * 0.95 {
                bottom = lastCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.0))
            } else {
                bottom = self.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95))
            }

            let top = firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.0))
            bottom.press(forDuration: 0.1, thenDragTo: top)
            screenNum += 1
        }
    }
}

// swiftlint:enable all
