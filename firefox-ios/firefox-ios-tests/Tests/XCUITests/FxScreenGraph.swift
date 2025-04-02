// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// swiftlint:disable all

import Common
import Foundation
import MappaMundi
import XCTest

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
let AutofillPasswordSettings = "AutofillsPasswordsSettings"
let Shortcuts = "Shortcuts"
let AutoplaySettings = "AutoplaySettings"

// These are in the exact order they appear in the settings
// screen. XCUIApplication loses them on small screens.
// This list should only be for settings screens that can be navigated to
// without changing userState. i.e. don't need conditional edges to be available
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

let HistoryPanelContextMenu = "HistoryPanelContextMenu"
let TopSitesPanelContextMenu = "TopSitesPanelContextMenu"

let BasicAuthDialog = "BasicAuthDialog"
let BookmarksPanelContextMenu = "BookmarksPanelContextMenu"

let Intro_Welcome = "Intro.Welcome"
let Intro_Sync = "Intro.Sync"

let allIntroPages = [
    Intro_Welcome,
    Intro_Sync
]

let HomePanelsScreen = "HomePanels"
let PrivateHomePanelsScreen = "PrivateHomePanels"
let HomePanel_TopSites = "HomePanel.TopSites.0"
let LibraryPanel_Bookmarks = "LibraryPanel.Bookmarks.1"
let LibraryPanel_History = "LibraryPanel.History.2"
let LibraryPanel_ReadingList = "LibraryPanel.ReadingList.3"
let LibraryPanel_Downloads = "LibraryPanel.Downloads.4"

let allHomePanels = [
    LibraryPanel_Bookmarks,
    LibraryPanel_History,
    LibraryPanel_ReadingList,
    LibraryPanel_Downloads
]

let iOS_Settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

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
    static let ToggleRecentlyVisited = "ToggleRecentlyVisited"
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

@objcMembers
class FxUserState: MMUserState {
    required init() {
        super.init()
        initialScreenState = FirstRun
    }

    var isPrivate = false
    var showIntro = false
    var showWhatsNew = false
    var waitForLoading = true
    var url: String?
    var requestDesktopSite = false

    var noImageMode = false
    var nightMode = false

    var pocketInNewTab = false
    var bookmarksInNewTab = true
    var historyInNewTab = true

    var fxaUsername: String?
    var fxaPassword: String?

    var numTabs: Int = 0

    var numTopSitesRows: Int = 2

    var trackingProtectionPerTabEnabled = true // TP can be shut off on a per-tab basis
    var trackingProtectionSettingOnNormalMode = true
    var trackingProtectionSettingOnPrivateMode = true

    var localeIsExpectedDifferent = false
}

private let defaultURL = "https://www.mozilla.org/en-US/book/"

func createScreenGraph(for test: XCTestCase, with app: XCUIApplication) -> MMScreenGraph<FxUserState> {
    let map = MMScreenGraph(for: test, with: FxUserState.self)

    let navigationControllerBackAction = {
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).waitAndTap()
    }

    let cancelBackAction = {
        app.otherElements["PopoverDismissRegion"].waitAndTap()
    }

    let dismissContextMenuAction = {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
    }

    map.addScreenState(FirstRun) { screenState in
        screenState.noop(to: BrowserTab, if: "showIntro == false && showWhatsNew == true")
        screenState.noop(to: NewTabScreen, if: "showIntro == false && showWhatsNew == false")
        screenState.noop(to: allIntroPages[0], if: "showIntro == true")
    }

    // Add the intro screens.
    var i = 0
    let introLast = allIntroPages.count - 1
    for intro in allIntroPages {
        _ = i == 0 ? nil : allIntroPages[i - 1]
        let next = i == introLast ? nil : allIntroPages[i + 1]

        map.addScreenState(intro) { screenState in
            if let next = next {
                screenState.tap(app.buttons["nextOnboardingButton"], to: next)
            } else {
                let startBrowsingButton = app.buttons["startBrowsingOnboardingButton"]
                screenState.tap(startBrowsingButton, to: BrowserTab)
            }
        }

        i += 1
    }

    // Some internally useful screen states.
    let WebPageLoading = "WebPageLoading"

    map.addScreenState(NewTabScreen) { screenState in
        screenState.noop(to: HomePanelsScreen)
        if isTablet {
            screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
            }
        }
        makeURLBarAvailable(screenState)
        screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], to: BrowserTabMenu)

        if isTablet {
            screenState.tap(
                app.buttons[AccessibilityIdentifiers.Browser.TopTabs.privateModeButton],
                forAction: Action.TogglePrivateModeFromTabBarNewTab
            ) { userState in
                userState.isPrivate = !userState.isPrivate
            }
        }
    }

    map.addScreenState(URLBarLongPressMenu) { screenState in
        let menu = app.tables["Context Menu"].firstMatch

        if #unavailable(iOS 16) {
            screenState.gesture(forAction: Action.LoadURLByPasting, Action.LoadURL) { userState in
                UIPasteboard.general.string = userState.url ?? defaultURL
                                menu.otherElements[AccessibilityIdentifiers.Photon.pasteAndGoAction].firstMatch.waitAndTap()
            }
        }

        screenState.gesture(forAction: Action.SetURLByPasting) { userState in
            UIPasteboard.general.string = userState.url ?? defaultURL
            menu.cells[AccessibilityIdentifiers.Photon.pasteAction].firstMatch.waitAndTap()
        }

        screenState.backAction = {
            if isTablet {
                // There is no Cancel option in iPad.
                app.otherElements["PopoverDismissRegion"].waitAndTap()
            } else {
                app.buttons["PhotonMenu.close"].waitAndTap()
            }
        }
        screenState.dismissOnUse = true
    }

    map.addScreenState(TrackingProtectionContextMenuDetails) { screenState in
        screenState.gesture(forAction: Action.TrackingProtectionperSiteToggle) { userState in
            app.tables.cells["tp.add-to-safelist"].waitAndTap()
            userState.trackingProtectionPerTabEnabled = !userState.trackingProtectionPerTabEnabled
        }

        screenState.gesture(
            forAction: Action.OpenSettingsFromTPMenu,
            transitionTo: TrackingProtectionSettings
        ) { userState in
            app.cells["settings"].waitAndTap()
        }

        screenState.gesture(forAction: Action.CloseTPContextMenu) { userState in
            if isTablet {
                // There is no Cancel option in iPad.
                app.otherElements["PopoverDismissRegion"].waitAndTap()
            } else {
                app.buttons[AccessibilityIdentifiers.EnhancedTrackingProtection.MainScreen.closeButton].waitAndTap()
            }
        }

        screenState.tap(app.buttons["Close privacy and security menu"], to: BrowserTab)
    }

    // URLBarOpen is dismissOnUse, which ScreenGraph interprets as "now we've done this action,
    // then go back to the one before it" but SetURL is an action than keeps us in URLBarOpen.
    // So let's put it here.
    map.addScreenAction(Action.SetURL, transitionTo: URLBarOpen)

    map.addScreenState(URLBarOpen) { screenState in
        // This is used for opening BrowserTab with default mozilla URL
        // For custom URL, should use Navigator.openNewURL or Navigator.openURL.
        screenState.gesture(forAction: Action.LoadURLByTyping) { userState in
            let url = userState.url ?? defaultURL
            // Workaround BB iOS13 be sure tap happens on url bar
            app.textFields.firstMatch.waitAndTap()
            app.textFields.firstMatch.waitAndTap()
            app.textFields.firstMatch.typeText(url)
            app.textFields.firstMatch.typeText("\r")
        }

        screenState.gesture(forAction: Action.SetURLByTyping, Action.SetURL) { userState in
            let url = userState.url ?? defaultURL
            // Workaround BB iOS13 be sure tap happens on url bar
            sleep(1)
            app.textFields.firstMatch.waitAndTap()
            app.textFields.firstMatch.waitAndTap()
            app.textFields.firstMatch.typeText("\(url)")
        }

        screenState.noop(to: HomePanelsScreen)
        screenState.noop(to: HomePanel_TopSites)

        screenState.backAction = {
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        }
        screenState.dismissOnUse = true
    }

    // LoadURL points to WebPageLoading, which allows us to add additional
    // onEntryWaitFor requirements, which we don't need when we're returning to BrowserTab without
    // loading a webpage.
    // We do end up at WebPageLoading however, so should lead quickly back to BrowserTab.
    map.addScreenAction(Action.LoadURL, transitionTo: WebPageLoading)
    map.addScreenState(WebPageLoading) { screenState in
        screenState.dismissOnUse = true

        // Would like to use app.otherElements.deviceStatusBars.networkLoadingIndicators.element
        // but this means exposing some of SnapshotHelper to another target.
        /*if !(app.progressIndicators.element(boundBy: 0).exists) {
            screenState.onEnterWaitFor(
                "exists != true",
                element: app.progressIndicators.element(boundBy: 0),
                if: "waitForLoading == true"
            )
        } else {
            screenState.onEnterWaitFor(
                element: app.progressIndicators.element(boundBy: 0),
                if: "waitForLoading == false"
            )
        }*/

        screenState.noop(to: BrowserTab, if: "waitForLoading == true")
        screenState.noop(to: BasicAuthDialog, if: "waitForLoading == false")
    }

    map.addScreenState(BasicAuthDialog) { screenState in
        screenState.onEnterWaitFor(element: app.alerts.element(boundBy: 0))
        screenState.backAction = {
            app.alerts.element(boundBy: 0).buttons.element(boundBy: 0).waitAndTap()
        }
        screenState.dismissOnUse = true
    }

    map.addScreenState(HomePanelsScreen) { screenState in
        if isTablet {
            screenState.tap(
                app.buttons[AccessibilityIdentifiers.Browser.TopTabs.privateModeButton],
                forAction: Action.TogglePrivateModeFromTabBarHomePanel
            ) { userState in
                userState.isPrivate = !userState.isPrivate
            }
        }

        // Workaround to bug Bug 1417522
        if isTablet {
            screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
            }
        }

        screenState.gesture(forAction: Action.CloseURLBarOpen, transitionTo: HomePanelsScreen) {_ in
            app.buttons[AccessibilityIdentifiers.Browser.UrlBar.cancelButton].waitAndTap()
        }
    }

    map.addScreenState(LibraryPanel_Bookmarks) { screenState in
        screenState.tap(app.cells.staticTexts["Mobile Bookmarks"], to: MobileBookmarks)
        screenState.gesture(forAction: Action.CloseBookmarkPanel, transitionTo: HomePanelsScreen) { userState in
                app.buttons["Done"].waitAndTap()
        }

        screenState.press(app.tables["Bookmarks List"].cells.element(boundBy: 4), to: BookmarksPanelContextMenu)
    }

    map.addScreenState(MobileBookmarks) { screenState in
        let bookmarksMenuNavigationBar = app.navigationBars["Mobile Bookmarks"]
        let bookmarksButton = bookmarksMenuNavigationBar.buttons["Bookmarks"]
        screenState.gesture(
            forAction: Action.ExitMobileBookmarksFolder,
            transitionTo: LibraryPanel_Bookmarks
        ) { userState in
                bookmarksButton.waitAndTap()
        }
        screenState.tap(app.buttons["Edit"], to: MobileBookmarksEdit)
    }

    map.addScreenState(MobileBookmarksEdit) { screenState in
        screenState.tap(app.buttons["libraryPanelBottomLeftButton"], to: MobileBookmarksAdd)
        screenState.gesture(forAction: Action.RemoveItemMobileBookmarks) { userState in
            app.tables["Bookmarks List"].buttons.element(boundBy: 0).waitAndTap()
        }
        screenState.gesture(forAction: Action.ConfirmRemoveItemMobileBookmarks) { userState in
            app.buttons["Delete"].waitAndTap()
        }

    }

    map.addScreenState(MobileBookmarksAdd) { screenState in
        screenState.gesture(forAction: Action.AddNewBookmark, transitionTo: EnterNewBookmarkTitleAndUrl) { userState in
            app.otherElements["New Bookmark"].waitAndTap()
        }
        screenState.gesture(forAction: Action.AddNewFolder) { userState in
            app.otherElements["New Folder"].waitAndTap()
        }
        screenState.gesture(forAction: Action.AddNewSeparator) { userState in
            app.otherElements["New Separator"].waitAndTap()
        }
    }

    map.addScreenState(EnterNewBookmarkTitleAndUrl) { screenState in
        screenState.gesture(forAction: Action.SaveCreatedBookmark) { userState in
            app.buttons["Save"].waitAndTap()
        }
    }

    map.addScreenState(HomePanel_TopSites) { screenState in
        let topSites = app.links[AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell]
        screenState.press(
            topSites.cells.matching(
                identifier: AccessibilityIdentifiers.FirefoxHomepage.TopSites.itemCell
            ).element(boundBy: 0),
            to: TopSitesPanelContextMenu
        )
    }

    map.addScreenState(LibraryPanel_History) { screenState in
        screenState.press(
            app.tables[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.tableView].cells.element(boundBy: 2),
            to: HistoryPanelContextMenu
        )
        screenState.tap(
            app.cells[AccessibilityIdentifiers.LibraryPanels.HistoryPanel.recentlyClosedCell],
            to: HistoryRecentlyClosed
        )
        screenState.gesture(forAction: Action.ClearRecentHistory) { userState in
            app.toolbars.matching(identifier: "Toolbar").buttons["historyBottomDeleteButton"].waitAndTap()
        }
        screenState.gesture(forAction: Action.CloseHistoryListPanel, transitionTo: HomePanelsScreen) { userState in
                app.buttons["Done"].waitAndTap()
        }
    }

    map.addScreenState(LibraryPanel_ReadingList) { screenState in
        screenState.dismissOnUse = true
        screenState.gesture(forAction: Action.CloseReadingListPanel, transitionTo: HomePanelsScreen) { userState in
                app.buttons["Done"].waitAndTap()
        }
    }

    map.addScreenState(LibraryPanel_Downloads) { screenState in
        screenState.dismissOnUse = true
        screenState.gesture(forAction: Action.CloseDownloadsPanel, transitionTo: HomePanelsScreen) { userState in
            app.buttons["Done"].waitAndTap()
        }
        screenState.tap(app.buttons["readingListLarge"], to: LibraryPanel_ReadingList)
    }

    map.addScreenState(HistoryRecentlyClosed) { screenState in
        screenState.dismissOnUse = true
        screenState.tap(app.buttons["libraryPanelTopLeftButton"].firstMatch, to: LibraryPanel_History)
    }

    map.addScreenState(HistoryPanelContextMenu) { screenState in
        screenState.dismissOnUse = true
    }

    map.addScreenState(BookmarksPanelContextMenu) { screenState in
        screenState.dismissOnUse = true
    }
    map.addScreenState(TopSitesPanelContextMenu) { screenState in
        screenState.dismissOnUse = true
        screenState.backAction = dismissContextMenuAction
    }

    map.addScreenState(SettingsScreen) { screenState in
        let table = app.tables.element(boundBy: 0)

        screenState.tap(table.cells["Sync"], to: SyncSettings, if: "fxaUsername != nil")
        screenState.tap(table.cells["SignInToSync"], to: Intro_FxASignin, if: "fxaUsername == nil")
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Search.searchNavigationBar], to: SearchSettings)
        screenState.tap(table.cells["NewTab"], to: NewTabSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Homepage.homeSettings], to: HomeSettings)
        screenState.tap(table.cells["Tabs"], to: TabsSettings)
        screenState.tap(table.cells["DisplayThemeOption"], to: DisplaySettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.SearchBar.searchBarSetting], to: ToolbarSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Browsing.title], to: BrowsingSettings)
        screenState.tap(table.cells["SiriSettings"], to: SiriSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.AutofillsPasswords.title], to: AutofillPasswordSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.ClearData.title], to: ClearPrivateDataSettings)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.ContentBlocker.title],
            to: TrackingProtectionSettings
        )
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.ShowIntroduction.title], to: ShowTourInSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Notifications.title], to: NotificationsSettings)
        screenState.gesture(forAction: Action.ToggleNoImageMode) { userState in
            app.otherElements.tables.cells.switches[AccessibilityIdentifiers.Settings.BlockImages.title].waitAndTap()
        }

        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(DisplaySettings) { screenState in
        screenState.gesture(forAction: Action.SelectAutomatically) { userState in
            app.cells.staticTexts["Automatically"].waitAndTap()
        }
        screenState.gesture(forAction: Action.SelectManually) { userState in
            app.cells.staticTexts["Manually"].waitAndTap()
        }
        screenState.gesture(forAction: Action.SystemThemeSwitch) { userState in
            app.switches["SystemThemeSwitchValue"].waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(SearchSettings) { screenState in
        let table = app.tables.element(boundBy: 0)
        screenState.tap(
            table.cells[AccessibilityIdentifiers.Settings.Search.customEngineViewButton],
            to: AddCustomSearchSettings
        )
        screenState.backAction = navigationControllerBackAction
        screenState.gesture(forAction: Action.RemoveCustomSearchEngine) {userSTate in
            // Screengraph will go back to main Settings screen. Manually tap on settings
            app.navigationBars[AccessibilityIdentifiers.Settings.Search.searchNavigationBar].buttons["Edit"].waitAndTap()
            if #unavailable(iOS 17) {
                app.tables.buttons["Delete Mozilla Engine"].waitAndTap()
            } else {
                app.tables.buttons[AccessibilityIdentifiers.Settings.Search.deleteMozillaEngine].waitAndTap()
            }
            app.tables.buttons[AccessibilityIdentifiers.Settings.Search.deleteButton].waitAndTap()
        }
    }

    map.addScreenState(SiriSettings) { screenState in
        screenState.gesture(forAction: Action.OpenSiriFromSettings) { userState in
            // Tap on Open New Tab to open Siri
            app.cells["SiriSettings"].staticTexts.element(boundBy: 0).waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(SyncSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(FxASigninScreen) { screenState in
        screenState.backAction = navigationControllerBackAction

        screenState.gesture(forAction: Action.FxATypeEmail) { userState in
            if isTablet {
                app.webViews.textFields.firstMatch.tapAndTypeText(userState.fxaUsername!)
            } else {
                app.textFields[AccessibilityIdentifiers.Settings.FirefoxAccount.emailTextField]
                    .tapAndTypeText(userState.fxaUsername!)
            }
        }
        screenState.gesture(forAction: Action.FxATypePasswordNewAccount) { userState in
            app.secureTextFields.element(boundBy: 1).tapAndTypeText(userState.fxaPassword!)
        }
        screenState.gesture(forAction: Action.FxATypePasswordExistingAccount) { userState in
            app.secureTextFields.element(boundBy: 0).tapAndTypeText(userState.fxaPassword!)
        }
        screenState.gesture(forAction: Action.FxATapOnContinueButton) { userState in
            app.webViews.buttons[AccessibilityIdentifiers.Settings.FirefoxAccount.continueButton].waitAndTap()
        }
        screenState.gesture(forAction: Action.FxATapOnSignInButton) { userState in
            app.webViews.buttons[AccessibilityIdentifiers.Settings.FirefoxAccount.signInButton].waitAndTap()
        }
        screenState.tap(app.webViews.links["Create an account"].firstMatch, to: FxCreateAccount)
    }

    map.addScreenState(FxCreateAccount) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(AddCustomSearchSettings) { screenState in
        screenState.gesture(forAction: Action.AddCustomSearchEngine) { userState in
            app.tables.textViews["customEngineTitle"].staticTexts["Search Engine"].waitAndTap()
            app.typeText("Mozilla Engine")
            app.tables.textViews["customEngineUrl"].waitAndTap()

            let searchEngineUrl = "https://developer.mozilla.org/search?q=%s"
            let tablesQuery = app.tables
            let customengineurlTextView = tablesQuery.textViews["customEngineUrl"]
            sleep(1)
            UIPasteboard.general.string = searchEngineUrl
            customengineurlTextView.press(forDuration: 1.0)
            app.staticTexts["Paste"].waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(WebsiteDataSettings) { screenState in
        screenState.gesture(forAction: Action.AcceptClearAllWebsiteData) { userState in
            app.tables.cells["ClearAllWebsiteData"].staticTexts["Clear All Website Data"].waitAndTap()
            app.alerts.buttons["OK"].waitAndTap()
        }
        // The swipeDown() is a workaround for an intermittent issue that the search filed is not always in view.
        screenState.gesture(forAction: Action.TapOnFilterWebsites) { userState in
            app.searchFields["Filter Sites"].waitAndTap()
        }
        screenState.gesture(forAction: Action.ShowMoreWebsiteDataEntries) { userState in
            app.tables.cells["ShowMoreWebsiteData"].waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(NewTabSettings) { screenState in
        let table = app.tables.element(boundBy: 0)

        screenState.gesture(forAction: Action.SelectNewTabAsBlankPage) { UserState in
            table.cells["NewTabAsBlankPage"].waitAndTap()
        }
        screenState.gesture(forAction: Action.SelectNewTabAsFirefoxHomePage) { UserState in
            table.cells["NewTabAsFirefoxHome"].waitAndTap()
        }
        screenState.gesture(forAction: Action.SelectNewTabAsCustomURL) { UserState in
            table.cells["NewTabAsCustomURL"].waitAndTap()
        }

        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(HomeSettings) { screenState in
        screenState.gesture(forAction: Action.SelectHomeAsFirefoxHomePage) { UserState in
            app.cells["HomeAsFirefoxHome"].waitAndTap()
        }

        screenState.gesture(forAction: Action.SelectHomeAsCustomURL) { UserState in
            app.cells["HomeAsCustomURL"].waitAndTap()
        }

        screenState.gesture(forAction: Action.TogglePocketInNewTab) { userState in
            userState.pocketInNewTab = !userState.pocketInNewTab
            app.tables.cells.switches["Thought-Provoking Stories, Articles powered by Pocket"].waitAndTap()
        }

        screenState.gesture(forAction: Action.SelectTopSitesRows) { userState in
            app.tables.cells["TopSitesRows"].waitAndTap()
            select(rows: userState.numTopSitesRows)
            app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).waitAndTap()
        }

        screenState.gesture(forAction: Action.ToggleRecentlyVisited) { userState in
            app.tables.cells.switches["Recently Visited"].waitAndTap()
        }

        screenState.gesture(forAction: Action.ToggleRecentlySaved) { userState in
            app.tables.cells.switches["Bookmarks"].waitAndTap()
        }

        screenState.gesture(forAction: Action.SelectShortcuts) { userState in
            let topSitesSetting = AccessibilityIdentifiers.Settings.Homepage.CustomizeFirefox.Shortcuts.settingsPage
            app.tables.cells[topSitesSetting].waitAndTap()
        }

        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(ToolbarSettings) { screenState in
        screenState.gesture(forAction: Action.SelectToolbarBottom) { UserState in
            app.cells[AccessibilityIdentifiers.Settings.SearchBar.bottomSetting].waitAndTap()
        }

        screenState.gesture(forAction: Action.SelectToolbarTop) { UserState in
            app.cells[AccessibilityIdentifiers.Settings.SearchBar.topSetting].waitAndTap()
        }

        screenState.backAction = navigationControllerBackAction
    }

    func select(rows: Int) {
        app.staticTexts[String(rows)].firstMatch.waitAndTap()
    }

    func type(text: String) {
        text.forEach { char in
            app.keys[String(char)].waitAndTap()
        }
    }

    map.addScreenState(ClearPrivateDataSettings) { screenState in
        screenState.tap(
            app.cells[AccessibilityIdentifiers.Settings.ClearData.websiteDataSection],
            to: WebsiteDataSettings
        )
        screenState.gesture(forAction: Action.AcceptClearPrivateData) { userState in
            app.tables.cells["ClearPrivateData"].waitAndTap()
            app.alerts.buttons["OK"].waitAndTap()
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(MailAppSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(ShowTourInSettings) { screenState in
        screenState.gesture(to: Intro_FxASignin) {
            let turnOnSyncButton = app.buttons["signInOnboardingButton"]
            turnOnSyncButton.waitAndTap()
        }
    }

    map.addScreenState(TrackingProtectionSettings) { screenState in
        screenState.backAction = navigationControllerBackAction

        screenState.tap(
            app.switches["prefkey.trackingprotection.normalbrowsing"],
            forAction: Action.SwitchETP
        ) { userState in
            userState.trackingProtectionSettingOnNormalMode = !userState.trackingProtectionSettingOnNormalMode
        }

        screenState.tap(
            app.cells["Settings.TrackingProtectionOption.BlockListStrict"],
            forAction: Action.EnableStrictMode
        ) { userState in
                userState.trackingProtectionPerTabEnabled = !userState.trackingProtectionPerTabEnabled
        }
    }

    map.addScreenState(Intro_FxASignin) { screenState in
        screenState.tap(
            app.buttons["EmailSignIn.button"],
            forAction: Action.OpenEmailToSignIn,
            transitionTo: FxASigninScreen
        )
        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Settings.FirefoxAccount.qrButton],
            forAction: Action.OpenEmailToQR,
            transitionTo: Intro_FxASignin
        )

        screenState.tap(app.navigationBars.buttons.element(boundBy: 0), to: SettingsScreen)
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(TabTray) { screenState in
        // Both iPad and iPhone use the same accessibility identifiers for buttons,
        // even thought they may be in separate locations design wise.
        screenState.tap(app.buttons[AccessibilityIdentifiers.TabTray.newTabButton],
                        forAction: Action.OpenNewTabFromTabTray,
                        transitionTo: NewTabScreen)
        if isTablet {
            screenState.tap(app.navigationBars.buttons["closeAllTabsButtonTabTray"], to: CloseTabMenu)
        } else {
            screenState.tap(app.toolbars.buttons["closeAllTabsButtonTabTray"], to: CloseTabMenu)
        }

        var regularModeSelector: XCUIElement
        var privateModeSelector: XCUIElement
        var syncModeSelector: XCUIElement

        if isTablet {
            regularModeSelector = app.navigationBars.segmentedControls.buttons.element(boundBy: 0)
            privateModeSelector = app.navigationBars.segmentedControls.buttons.element(boundBy: 1)
            syncModeSelector = app.navigationBars.segmentedControls.buttons.element(boundBy: 2)
        } else {
            regularModeSelector = app.toolbars["Toolbar"]
                .segmentedControls[AccessibilityIdentifiers.TabTray.navBarSegmentedControl].buttons.element(boundBy: 0)
            privateModeSelector = app.toolbars["Toolbar"]
                .segmentedControls[AccessibilityIdentifiers.TabTray.navBarSegmentedControl].buttons.element(boundBy: 1)
            syncModeSelector = app.toolbars["Toolbar"]
                .segmentedControls[AccessibilityIdentifiers.TabTray.navBarSegmentedControl].buttons.element(boundBy: 2)
        }
        screenState.tap(regularModeSelector, forAction: Action.ToggleRegularMode) { userState in
            userState.isPrivate = !userState.isPrivate
        }
        screenState.tap(privateModeSelector, forAction: Action.TogglePrivateMode) { userState in
            userState.isPrivate = !userState.isPrivate
        }
        screenState.tap(syncModeSelector, forAction: Action.ToggleSyncMode) { userState in
        }

        screenState.onEnter { userState in
            userState.numTabs = Int(app.otherElements["Tabs Tray"].cells.count)
        }
    }

    // This menu is only available for iPhone, NOT for iPad, no menu when long tapping on tabs button
    if !isTablet {
        map.addScreenState(TabTrayLongPressMenu) { screenState in
            screenState.dismissOnUse = true
            screenState.tap(
                app.otherElements[StandardImageIdentifiers.Large.plus],
                forAction: Action.OpenNewTabLongPressTabsButton,
                transitionTo: NewTabScreen
            )
            screenState.tap(
                app.otherElements[StandardImageIdentifiers.Large.cross],
                forAction: Action.CloseTabFromTabTrayLongPressMenu,
                Action.CloseTab,
                transitionTo: HomePanelsScreen
            )
            screenState.tap(
                app.tables.cells.otherElements[StandardImageIdentifiers.Large.tab],
                forAction: Action.OpenPrivateTabLongPressTabsButton,
                transitionTo: NewTabScreen
            ) { userState in
                userState.isPrivate = !userState.isPrivate
            }
        }
    }

    map.addScreenState(CloseTabMenu) { screenState in
        screenState.tap(
            app.scrollViews.buttons[AccessibilityIdentifiers.TabTray.deleteCloseAllButton],
            forAction: Action.AcceptRemovingAllTabs,
            transitionTo: HomePanelsScreen
        )
        screenState.backAction = cancelBackAction
    }

    func makeURLBarAvailable(_ screenState: MMScreenStateNode<FxUserState>) {
        screenState.tap(app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField], to: URLBarOpen)
        screenState.gesture(to: URLBarLongPressMenu) {
            app.textFields[AccessibilityIdentifiers.Browser.AddressToolbar.searchTextField].press(forDuration: 1.0)
        }
    }

    func makeToolBarAvailable(_ screenState: MMScreenStateNode<FxUserState>) {
        screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton], to: BrowserTabMenu)
        if isTablet {
            screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
            }
        }
    }

    map.addScreenState(BrowserTab) { screenState in
        makeURLBarAvailable(screenState)
        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Toolbar.settingsMenuButton],
            to: BrowserTabMenu
        )

        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Browser.AddressToolbar.lockIcon],
            to: TrackingProtectionContextMenuDetails
        )

        if isTablet {
        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Toolbar.addNewTabButton],
            forAction: Action.GoToHomePage)
            } else {
                screenState.tap(
                    app.buttons[AccessibilityIdentifiers.Toolbar.homeButton],
                forAction: Action.GoToHomePage)
            }

        screenState.tap(
            app.buttons[AccessibilityIdentifiers.Toolbar.searchButton],
            forAction: Action.ClickSearchButton
        ) { userState in
        }

        makeToolBarAvailable(screenState)
        let link = app.webViews.element(boundBy: 0).links.element(boundBy: 0)
        let image = app.webViews.element(boundBy: 0).images.element(boundBy: 0)

        screenState.press(link, to: WebLinkContextMenu)
        screenState.press(image, to: WebImageContextMenu)

        let reloadButton = app.buttons[AccessibilityIdentifiers.Toolbar.reloadButton]
        screenState.press(reloadButton, to: ReloadLongPressMenu)
        screenState.tap(reloadButton, forAction: Action.ReloadURL, transitionTo: WebPageLoading) { _ in }
        // For iPad there is no long press on tabs button
        if !isTablet {
            let tabsButton = app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton]
            screenState.press(tabsButton, to: TabTrayLongPressMenu)
        }

        if isTablet {
            screenState.tap(app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton], to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                app.buttons[AccessibilityIdentifiers.Toolbar.tabsButton].waitAndTap()
            }
        }

        screenState.tap(
            app.buttons["TopTabsViewController.privateModeButton"],
            forAction: Action.TogglePrivateModeFromTabBarBrowserTab
        ) { userState in
            userState.isPrivate = !userState.isPrivate
        }
    }

    map.addScreenState(ReloadLongPressMenu) { screenState in
        screenState.backAction = cancelBackAction
        screenState.dismissOnUse = true

        let rdsButton = app.tables["Context Menu"].cells.element(boundBy: 0)
        screenState.tap(rdsButton, forAction: Action.ToggleRequestDesktopSite) { userState in
            userState.requestDesktopSite = !userState.requestDesktopSite
        }

        let trackingProtectionButton = app.tables["Context Menu"].cells.element(boundBy: 1)

        screenState.tap(
            trackingProtectionButton,
            forAction: Action.ToggleTrackingProtectionPerTabEnabled
        ) { userState in
            userState.trackingProtectionPerTabEnabled = !userState.trackingProtectionPerTabEnabled
        }
    }

    [WebImageContextMenu, WebLinkContextMenu].forEach { item in
        map.addScreenState(item) { screenState in
            screenState.dismissOnUse = true
            screenState.backAction = {
                let window = XCUIApplication().windows.element(boundBy: 0)
                window.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)).tap()
            }
        }
    }

    map.addScreenState(FxAccountManagementPage) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(Shortcuts) { screenState in
        let homePage = AccessibilityIdentifiers.Settings.Homepage.homePageNavigationBar
        screenState.tap(app.navigationBars.buttons[homePage], to: HomeSettings)
    }

    map.addScreenState(FindInPage) { screenState in
        screenState.tap(app.buttons[AccessibilityIdentifiers.FindInPage.findInPageCloseButton], to: BrowserTab)
    }

    map.addScreenState(PageZoom) { screenState in
        screenState.tap(app.buttons[AccessibilityIdentifiers.ZoomPageBar.doneButton], to: BrowserTab)
    }

    map.addScreenState(RequestDesktopSite) { _ in }

    map.addScreenState(RequestMobileSite) { _ in }

    map.addScreenState(HomePanel_Library) { screenState in
        screenState.dismissOnUse = true
        screenState.backAction = navigationControllerBackAction

        screenState.tap(
            app.segmentedControls["librarySegmentControl"].buttons.element(boundBy: 0),
            to: LibraryPanel_Bookmarks
        )
        screenState.tap(
            app.segmentedControls["librarySegmentControl"].buttons.element(boundBy: 1),
            to: LibraryPanel_History
        )
        screenState.tap(
            app.segmentedControls["librarySegmentControl"].buttons.element(boundBy: 2),
            to: LibraryPanel_Downloads
        )
        screenState.tap(
            app.segmentedControls["librarySegmentControl"].buttons.element(boundBy: 3),
            to: LibraryPanel_ReadingList
        )
    }
    
    map.addScreenState(AutofillPasswordSettings) { screenState in
        let table = app.tables.element(boundBy: 0)
        
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Logins.title], to: LoginsSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.CreditCards.title], to: CreditCardsSettings)
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Address.title], to: AddressesSettings)
        
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(BrowsingSettings) { screenState in
        let table = app.tables.element(boundBy: 0)
        
        screenState.tap(table.cells[AccessibilityIdentifiers.Settings.Browsing.autoPlay], to: AutoplaySettings)
        screenState.tap(table.cells["OpenWith.Setting"], to: MailAppSettings)

        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(LoginsSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(CreditCardsSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(AddressesSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(AutoplaySettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(NotificationsSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(ToolsBrowserTabMenu) { screenState in
        // Zoom
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.zoom],
            to: PageZoom)
        // Turn on night mode
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.nightMode],
            forAction: Action.ToggleNightMode,
            transitionTo: BrowserTab
        ) { userState in
            userState.nightMode = !userState.nightMode
        }
        // Report broken site (TODO)
        // Share
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.share],
            forAction: Action.ShareBrowserTabMenuOption
        ) { userState in
        }

        screenState.dismissOnUse = true
        screenState.backAction = cancelBackAction
    }

    map.addScreenState(SaveBrowserTabMenu) { screenState in
        // Bookmark this page
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.bookmarkThisPage],
            forAction: Action.BookmarkThreeDots
        )
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.bookmarkThisPage],
            forAction: Action.Bookmark
        )
        // Add to shortcuts
        // No Copy link available (Action.CopyAddressPAM)
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.addToShortcuts],
            forAction: Action.PinToTopSitesPAM
        )
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.saveToReadingList],
            forAction: Action.AddToReadingListBrowserTabMenu
        )

        screenState.dismissOnUse = true
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(BrowserTabMenu) { screenState in
        sleep(1)

        // Sign In (if unauthenticated)
        screenState.tap(
            app.buttons[AccessibilityIdentifiers.MainMenu.HeaderView.mainButton],
            to: Intro_FxASignin,
            if: "fxaUsername == nil")
        // Signed in (TODO)
        // New tab
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.newTab], to: NewTabScreen)
        // New private tab (TODO: Action.OpenPrivateTabLongPressTabsButton
        // Switch to Desktop/Mobile Site
        // The cell's identifier is the same for desktop and mobile, so I use static
        // texts for the RequestMobileSite case
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.switchToDesktopSite], to: RequestDesktopSite)
        screenState.tap(app.tables.cells.staticTexts["Switch to Mobile Site"], to: RequestMobileSite)
        // Find in Page...
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.findInPage],
            to: FindInPage)
        // Tools (Zoom, NightMode, Report, Share)
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.tools], to: ToolsBrowserTabMenu)
        // Save (Add Bookmark, Shortcut)
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.save], to: SaveBrowserTabMenu)
        // Bookmarks
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.bookmarks], to: LibraryPanel_Bookmarks)
        // History
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.history],
            to: LibraryPanel_History)
        // Downloads
        screenState.tap(
            app.tables.cells[AccessibilityIdentifiers.MainMenu.downloads],
            to: LibraryPanel_Downloads
        )
        // Passwords (TODO)
        // Customize Homepage (TODO)
        // New in Firefox
        screenState.tap(
            app.otherElements.cells["MainMenu.WhatsNew"],
            forAction: Action.OpenWhatsNewPage
        )
        // Get Help (TODO: Actions to open support.mozilla.org)
        // SettingsScreen
        screenState.tap(app.tables.cells[AccessibilityIdentifiers.MainMenu.settings], to: SettingsScreen)

        // "x" for close the menu and go back
        screenState.dismissOnUse = true
        screenState.backAction = cancelBackAction
    }

    map.addScreenState(TabsSettings) { screenState in
        screenState.tap(app.switches.element(boundBy: 0), forAction: Action.ToggleInactiveTabs)
        screenState.tap(app.switches.element(boundBy: 1), forAction: Action.ToggleTabGroups)
        screenState.tap(app.navigationBars.buttons["Settings"], to: SettingsScreen)
    }

    return map
}

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
