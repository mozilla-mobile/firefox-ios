/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
let PageOptionsMenu = "PageOptionsMenu"
let ToolsMenu = "ToolsMenu"
let FindInPage = "FindInPage"
let SettingsScreen = "SettingsScreen"
let SyncSettings = "SyncSettings"
let FxASigninScreen = "FxASigninScreen"
let FxCreateAccount = "FxCreateAccount"
let FxAccountManagementPage = "FxAccountManagementPage"
let Intro_FxASigninEmail = "Intro_FxASigninEmail"
let HomeSettings = "HomeSettings"
let SiriSettings = "SiriSettings"
let PasscodeSettings = "PasscodeSettings"
let PasscodeIntervalSettings = "PasscodeIntervalSettings"
let SearchSettings = "SearchSettings"
let NewTabSettings = "NewTabSettings"
let ClearPrivateDataSettings = "ClearPrivateDataSettings"
let WebsiteDataSettings = "WebsiteDataSettings"
let WebsiteSearchDataSettings = "WebsiteSearchDataSettings"
let LoginsSettings = "LoginsSettings"
let OpenWithSettings = "OpenWithSettings"
let ShowTourInSettings = "ShowTourInSettings"
let TrackingProtectionSettings = "TrackingProtectionSettings"
let Intro_FxASignin = "Intro_FxASignin"
let WebImageContextMenu = "WebImageContextMenu"
let WebLinkContextMenu = "WebLinkContextMenu"
let CloseTabMenu = "CloseTabMenu"
let AddCustomSearchSettings = "AddCustomSearchSettings"
let DisablePasscodeSettings = "DisablePasscodeSettings"
let ChangePasscodeSettings = "ChangePasscodeSettings"
let LockedLoginsSettings = "LockedLoginsSettings"
let TabTrayLongPressMenu = "TabTrayLongPressMenu"
let HistoryRecentlyClosed = "HistoryRecentlyClosed"
let TrackingProtectionContextMenuDetails = "TrackingProtectionContextMenuDetails"
let DisplaySettings = "DisplaySettings"
let TranslationSettings = "TranslationSettings"
let HomePanel_Library = "HomePanel_Library"
let TranslatePageMenu = "TranslatePageMenu"
let DontTranslatePageMenu = "DontTranslatePageMenu"
let MobileBookmarks = "MobileBookmarks"
let MobileBookmarksEdit = "MobileBookmarksEdit"
let MobileBookmarksAdd = "MobileBookmarksAdd"
let EnterNewBookmarkTitleAndUrl = "EnterNewBookmarkTitleAndUrl"
let RequestDesktopSite = "RequestDesktopSite"
let RequestMobileSite = "RequestMobileSite"

// These are in the exact order they appear in the settings
// screen. XCUIApplication loses them on small screens.
// This list should only be for settings screens that can be navigated to
// without changing userState. i.e. don't need conditional edges to be available
let allSettingsScreens = [
    SearchSettings,
    AddCustomSearchSettings,
    NewTabSettings,
    OpenWithSettings,
    DisplaySettings,
    TranslationSettings,

    LoginsSettings,
    PasscodeSettings,
    ClearPrivateDataSettings,
    TrackingProtectionSettings,
]

let HistoryPanelContextMenu = "HistoryPanelContextMenu"
let TopSitesPanelContextMenu = "TopSitesPanelContextMenu"

let BasicAuthDialog = "BasicAuthDialog"
let BookmarksPanelContextMenu = "BookmarksPanelContextMenu"
let SetPasscodeScreen = "SetPasscodeScreen"

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
let LibraryPanel_SyncedTabs = "LibraryPanel.SyncedTabs.5"

let allHomePanels = [
    LibraryPanel_Bookmarks,
    LibraryPanel_History,
    LibraryPanel_ReadingList,
    LibraryPanel_Downloads,
    LibraryPanel_SyncedTabs
]

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

    static let TogglePrivateMode = "TogglePrivateBrowing"
    static let TogglePrivateModeFromTabBarHomePanel = "TogglePrivateModeFromTabBarHomePanel"
    static let TogglePrivateModeFromTabBarBrowserTab = "TogglePrivateModeFromTabBarBrowserTab"
    static let TogglePrivateModeFromTabBarNewTab = "TogglePrivateModeFromTabBarNewTab"

    static let ToggleRequestDesktopSite = "ToggleRequestDesktopSite"
    static let ToggleNightMode = "ToggleNightMode"
    static let ToggleTrackingProtection = "ToggleTrackingProtection"
    static let ToggleNoImageMode = "ToggleNoImageMode"

    static let Bookmark = "Bookmark"
    static let BookmarkThreeDots = "BookmarkThreeDots"

    static let OpenPrivateTabLongPressTabsButton = "OpenPrivateTabLongPressTabsButton"
    static let OpenNewTabLongPressTabsButton = "OpenNewTabLongPressTabsButton"

    static let SetPasscode = "SetPasscode"
    static let SetPasscodeTypeOnce = "SetPasscodeTypeOnce"
    static let DisablePasscode = "DisablePasscode"
    static let LoginPasscodeTypeIncorrectOne = "LoginPasscodeTypeIncorrectOne"
    static let ChangePasscode = "ChangePasscode"
    static let ChangePasscodeTypeOnce = "ChangePasscodeTypeOnce"
    static let ConfirmPasscodeToChangePasscode = "ConfirmPasscodeToChangePasscode"
    static let UnlockLoginsSettings = "UnlockLoginsSettings"
    static let DisablePasscodeTypeIncorrectPasscode = "DisablePasscodeTypeIncorrectPasscode"

    static let TogglePocketInNewTab = "TogglePocketInNewTab"
    static let ToggleHistoryInNewTab = "ToggleHistoryInNewTab"

    static let SelectNewTabAsBlankPage = "SelectNewTabAsBlankPage"
    static let SelectNewTabAsFirefoxHomePage = "SelectNewTabAsFirefoxHomePage"
    static let SelectNewTabAsCustomURL = "SelectNewTabAsCustomURL"

    static let SelectHomeAsFirefoxHomePage = "SelectHomeAsFirefoxHomePage"
    static let SelectHomeAsCustomURL = "SelectHomeAsCustomURL"
    static let SelectTopSitesRows = "SelectTopSitesRows"

    static let GoToHomePage = "GoToHomePage"

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

    static let CloseTab = "CloseTab"
    static let CloseTabFromTabTrayLongPressMenu = "CloseTabFromTabTrayLongPressMenu"

    static let OpenEmailToSignIn = "OpenEmailToSignIn"
    static let OpenEmailToQR = "OpenEmailToQR"

    static let FxATypeEmail = "FxATypeEmail"
    static let FxATypePassword = "FxATypePassword"
    static let FxATapOnSignInButton = "FxATapOnSignInButton"
    static let FxATapOnContinueButton = "FxATapOnContinueButton"

    static let PinToTopSitesPAM = "PinToTopSitesPAM"
    static let CopyAddressPAM = "CopyAddressPAM"

    static let SelectAutomatically = "SelectAutomatically"
    static let SelectManually = "SelectManually"
    static let SystemThemeSwitch = "SystemThemeSwitch"

    static let SelectTranslateThisPage = "SelectTranslateThisPage"
    static let SelectDontTranslateThisPage = "SelectDontTranslateThisPage"
    
    static let EnableTranslation = "EnableTranlation"
    static let DisableTranslation = "DisableTranlation"
    static let SelectGoogle = "SelectGoogle"
    static let SelectBing = "SelectBing"
    
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
    var url: String? = nil
    var requestDesktopSite = false

    var passcode: String? = nil
    var newPasscode: String = "111111"
    var wrongPasscode: String = "111112"

    var noImageMode = false
    var nightMode = false

    var pocketInNewTab = false
    var bookmarksInNewTab = true
    var historyInNewTab = true

    var fxaUsername: String? = nil
    var fxaPassword: String? = nil

    var numTabs: Int = 0

    var numTopSitesRows: Int = 2

    var trackingProtectionPerTabEnabled = true // TP can be shut off on a per-tab basis
    var trackingProtectionSettingOnNormalMode = true
    var trackingProtectionSettingOnPrivateMode = true

    var localeIsExpectedDifferent = false
}

fileprivate let defaultURL = "https://www.mozilla.org/en-US/book/"

func createScreenGraph(for test: XCTestCase, with app: XCUIApplication) -> MMScreenGraph<FxUserState> {
    let map = MMScreenGraph(for: test, with: FxUserState.self)

    let navigationControllerBackAction = {
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
    }

    let cancelBackAction = {
        if isTablet {
            // There is no Cancel option in iPad.
            app.otherElements["PopoverDismissRegion"].tap()
        } else {
            app.buttons["PhotonMenu.close"].tap()
        }
    }

    let cancelTypePasscode = {
        if isTablet {
            if (app.buttons["Cancel"].exists){
                app.buttons["Cancel"].tap()
            } else {
                app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
            }
        } else {
            app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        }
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
        let prev = i == 0 ? nil : allIntroPages[i - 1]
        let next = i == introLast ? nil : allIntroPages[i + 1]

        map.addScreenState(intro) { screenState in
            if let next = next {
                screenState.tap(app.buttons["nextOnboardingButton"], to: next)
            }  else {
                let startBrowsingButton = app.buttons["startBrowsingOnboardingButton"]
                screenState.tap(startBrowsingButton, to: BrowserTab)
            }
        }

        i += 1
    }

    let noopAction = {}

    // Some internally useful screen states.
    let WebPageLoading = "WebPageLoading"

    map.addScreenState(NewTabScreen) { screenState in
        screenState.noop(to: HomePanelsScreen)
        if isTablet {
            screenState.tap(app.buttons["TopTabsViewController.tabsButton"], to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                if (app.buttons["TabToolbar.tabsButton"].exists) {
                    app.buttons["TabToolbar.tabsButton"].tap()
                } else {
                    app.buttons["URLBarView.tabsButton"].tap()
                }
            }
        }
        makeURLBarAvailable(screenState)
        screenState.tap(app.buttons["TabToolbar.menuButton"], to: BrowserTabMenu)

        if isTablet {
            screenState.tap(app.buttons["Private Mode"], forAction: Action.TogglePrivateModeFromTabBarNewTab) { userState in
                userState.isPrivate = !userState.isPrivate
            }
        }
    }

    map.addScreenState(URLBarLongPressMenu) { screenState in
        let menu = app.tables["Context Menu"].firstMatch

        screenState.gesture(forAction: Action.LoadURLByPasting, Action.LoadURL) { userState in
            UIPasteboard.general.string = userState.url ?? defaultURL
            menu.cells["menu-PasteAndGo"].firstMatch.tap()
        }

        screenState.gesture(forAction: Action.SetURLByPasting) { userState in
            UIPasteboard.general.string = userState.url ?? defaultURL
            menu.cells["menu-Paste"].firstMatch.tap()
        }

        screenState.backAction = {
            if isTablet {
                // There is no Cancel option in iPad.
                app.otherElements["PopoverDismissRegion"].tap()
            } else {
                app.buttons["PhotonMenu.close"].tap()
            }
        }
        screenState.dismissOnUse = true
    }

    map.addScreenState(TrackingProtectionContextMenuDetails) { screenState in
        screenState.gesture(forAction: Action.TrackingProtectionperSiteToggle) { userState in
            app.tables.cells["tp.add-to-whitelist"].tap()
            userState.trackingProtectionPerTabEnabled = !userState.trackingProtectionPerTabEnabled
        }

        screenState.gesture(forAction: Action.OpenSettingsFromTPMenu) { userState in
            app.cells["settings"].tap()
        }

        screenState.gesture(forAction: Action.CloseTPContextMenu) { userState in
            if isTablet {
                // There is no Cancel option in iPad.
                app.otherElements["PopoverDismissRegion"].tap()
            } else {
                app.buttons["PhotonMenu.close"].tap()
            }
        }

        screenState.backAction = {
            if isTablet {
                // There is no Cancel option in iPad.
                app.otherElements["PopoverDismissRegion"].tap()
            } else {
                app.buttons["PhotonMenu.close"].tap()
            }
        }
    }

    // URLBarOpen is dismissOnUse, which ScreenGraph interprets as "now we've done this action, then go back to the one before it"
    // but SetURL is an action than keeps us in URLBarOpen. So let's put it here.
    map.addScreenAction(Action.SetURL, transitionTo: URLBarOpen)

    map.addScreenState(URLBarOpen) { screenState in
        // This is used for opening BrowserTab with default mozilla URL
        // For custom URL, should use Navigator.openNewURL or Navigator.openURL.
        screenState.gesture(forAction: Action.LoadURLByTyping) { userState in
            let url = userState.url ?? defaultURL
            // Workaround BB iOS13 be sure tap happens on url bar
            app.textFields.firstMatch.tap()
            app.textFields.firstMatch.tap()
            app.textFields.firstMatch.typeText(url)
            app.textFields.firstMatch.typeText("\r")
        }

        screenState.gesture(forAction: Action.SetURLByTyping, Action.SetURL) { userState in
            let url = userState.url ?? defaultURL
            // Workaround BB iOS13 be sure tap happens on url bar
            sleep(1)
            app.textFields.firstMatch.tap()
            app.textFields.firstMatch.tap()
            app.textFields.firstMatch.typeText("\(url)")
        }

        screenState.noop(to: HomePanelsScreen)
        screenState.noop(to: HomePanel_TopSites)

        screenState.backAction = {
            app.buttons["urlBar-cancel"].tap()
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
            screenState.onEnterWaitFor("exists != true", element: app.progressIndicators.element(boundBy: 0), if: "waitForLoading == true")
        } else {
            screenState.onEnterWaitFor(element: app.progressIndicators.element(boundBy: 0), if: "waitForLoading == false")
        }*/

        screenState.noop(to: BrowserTab, if: "waitForLoading == true")
        screenState.noop(to: BasicAuthDialog, if: "waitForLoading == false")
    }

    map.addScreenState(BasicAuthDialog) { screenState in
        screenState.onEnterWaitFor(element: app.alerts.element(boundBy: 0))
        screenState.backAction = {
            app.alerts.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        }
        screenState.dismissOnUse = true
    }

    map.addScreenState(HomePanelsScreen) { screenState in
        if isTablet {
            screenState.tap(app.buttons["Private Mode"], forAction: Action.TogglePrivateModeFromTabBarHomePanel) { userState in
                userState.isPrivate = !userState.isPrivate
            }
        }

        // Workaround to bug Bug 1417522
        if isTablet {
            screenState.tap(app.buttons["TopTabsViewController.tabsButton"], to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                // iPhone sim tabs button is called differently when in portrait or landscape
                if (XCUIDevice.shared.orientation == UIDeviceOrientation.landscapeLeft) {
                    app.buttons["URLBarView.tabsButton"].tap()
                } else {
                    app.buttons["TabToolbar.tabsButton"].tap()
                }
            }
        }
    }

    map.addScreenState(LibraryPanel_Bookmarks) { screenState in
        let bookmarkCell = app.tables["Bookmarks List"].cells.element(boundBy: 0)
        let bookmarksElement = app.navigationBars["Bookmarks"].staticTexts["Bookmarks"]
        screenState.tap(app.cells.staticTexts["Mobile Bookmarks"], to: MobileBookmarks)
        screenState.gesture(forAction: Action.CloseBookmarkPanel, transitionTo: HomePanelsScreen) { userState in
            if isTablet {
                app.buttons["TabToolbar.libraryButton"].tap()
            } else {
                bookmarksElement.press(forDuration: 2, thenDragTo: app.buttons["LibraryPanels.Bookmarks"])
            }
        }

        screenState.press(app.tables["Bookmarks List"].cells.element(boundBy: 4), to: BookmarksPanelContextMenu)
    }

    map.addScreenState(MobileBookmarks) { screenState in
        let bookmarksMenuNavigationBar = app.navigationBars["Mobile Bookmarks"]
        let bookmarksButton = bookmarksMenuNavigationBar.buttons["Bookmarks"]
        screenState.gesture(forAction: Action.ExitMobileBookmarksFolder, transitionTo: LibraryPanel_Bookmarks) { userState in
                bookmarksButton.tap()
        }
        screenState.tap(app.buttons["Edit"], to: MobileBookmarksEdit)
    }

    map.addScreenState(MobileBookmarksEdit) { screenState in
        screenState.tap(app.buttons["Add"], to: MobileBookmarksAdd)
        screenState.gesture(forAction: Action.RemoveItemMobileBookmarks) { userState in
            app.tables["Bookmarks List"].buttons.element(boundBy: 0).tap()
        }
        screenState.gesture(forAction: Action.ConfirmRemoveItemMobileBookmarks) { userState in
            app.buttons["Delete"].tap()
        }
    }

    map.addScreenState(MobileBookmarksAdd) { screenState in
        screenState.gesture(forAction: Action.AddNewBookmark, transitionTo: EnterNewBookmarkTitleAndUrl) { userState in
            app.tables.cells["action_bookmark"].tap()
        }
        screenState.gesture(forAction: Action.AddNewFolder) { userState in
            app.tables.cells["bookmarkFolder"].tap()
        }
        screenState.gesture(forAction: Action.AddNewSeparator) { userState in
            app.tables.cells["nav-menu"].tap()
        }
    }

    map.addScreenState(EnterNewBookmarkTitleAndUrl) { screenState in
        screenState.gesture(forAction: Action.SaveCreatedBookmark) { userState in
            app.buttons["Save"].tap()
        }
    }

    map.addScreenState(HomePanel_TopSites) { screenState in
        let topSites = app.cells["TopSitesCell"]
        screenState.press(topSites.cells.matching(identifier: "TopSite").element(boundBy: 0), to: TopSitesPanelContextMenu)

    }

    map.addScreenState(LibraryPanel_History) { screenState in
        screenState.press(app.tables["History List"].cells.element(boundBy: 2), to: HistoryPanelContextMenu)
        screenState.tap(app.cells["HistoryPanel.recentlyClosedCell"], to: HistoryRecentlyClosed)
        screenState.gesture(forAction: Action.ClearRecentHistory) { userState in
            app.tables["History List"].cells.matching(identifier: "HistoryPanel.clearHistory").element(boundBy: 0).tap()
        }
        let historyListElement = app.navigationBars["History"]
        screenState.gesture(forAction: Action.CloseHistoryListPanel, transitionTo: HomePanelsScreen) { userState in
            if isTablet {
                app.buttons["TabToolbar.libraryButton"].tap()
            } else {
                historyListElement.press(forDuration: 2, thenDragTo: app.buttons["LibraryPanels.History"])
            }
        }
    }

    map.addScreenState(LibraryPanel_SyncedTabs) { screenState in
        screenState.dismissOnUse = true
        let syncedTabsElement = app.navigationBars["Synced Tabs"]
        screenState.gesture(forAction: Action.CloseSyncedTabsPanel, transitionTo: HomePanelsScreen) { userState in
            if isTablet {
                app.buttons["TabToolbar.libraryButton"].tap()
            } else {
                syncedTabsElement.press(forDuration: 2, thenDragTo: app.buttons["LibraryPanels.SyncedTabs"])
            }
        }
    }

    map.addScreenState(LibraryPanel_ReadingList) { screenState in
        screenState.dismissOnUse = true
        let readingListElement = app.navigationBars["Reading list"]
        screenState.gesture(forAction: Action.CloseReadingListPanel, transitionTo: HomePanelsScreen) { userState in
            if isTablet {
                app.buttons["TabToolbar.libraryButton"].tap()
            } else {
                readingListElement.press(forDuration: 2, thenDragTo: app.buttons["LibraryPanels.ReadingList"])
            }
        }
    }

    map.addScreenState(LibraryPanel_Downloads) { screenState in
        screenState.dismissOnUse = true
        let downloadsElement = app.navigationBars["Downloads"]
        screenState.gesture(forAction: Action.CloseDownloadsPanel, transitionTo: HomePanelsScreen) { userState in
            if isTablet {
                app.buttons["TabToolbar.libraryButton"].tap()
            } else {
                downloadsElement.press(forDuration: 2, thenDragTo: app.buttons["LibraryPanels.Downloads"])
            }
        }
    }

    map.addScreenState(HistoryRecentlyClosed) { screenState in
        screenState.dismissOnUse = true
        screenState.tap(app.buttons["History"].firstMatch, to: LibraryPanel_History)
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
        screenState.tap(table.cells["Search"], to: SearchSettings)
        screenState.tap(table.cells["NewTab"], to: NewTabSettings)
        screenState.tap(table.cells["Home"], to: HomeSettings)
        screenState.tap(table.cells["OpenWith.Setting"], to: OpenWithSettings)
        screenState.tap(table.cells["DisplayThemeOption"], to: DisplaySettings)
        screenState.tap(table.cells["TranslationOption"], to: TranslationSettings)
        screenState.tap(table.cells["SiriSettings"], to: SiriSettings)
        screenState.tap(table.cells["TouchIDPasscode"], to: PasscodeSettings)
        screenState.tap(table.cells["Logins"], to: LoginsSettings, if: "passcode == nil")
        screenState.tap(table.cells["Logins"], to: LockedLoginsSettings, if: "passcode != nil")
        screenState.tap(table.cells["ClearPrivateData"], to: ClearPrivateDataSettings)
        screenState.tap(table.cells["TrackingProtection"], to: TrackingProtectionSettings)
        screenState.tap(table.cells["ShowTour"], to: ShowTourInSettings)

        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(DisplaySettings) { screenState in
        screenState.gesture(forAction: Action.SelectAutomatically) { userState in
            app.cells.staticTexts["Automatically"].tap()
        }
        screenState.gesture(forAction: Action.SelectManually) { userState in
            app.cells.staticTexts["Manually"].tap()
        }
        screenState.gesture(forAction: Action.SystemThemeSwitch) { userState in
            app.switches["SystemThemeSwitchValue"].tap()
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(TranslationSettings) { screenState in
        screenState.gesture(forAction: Action.DisableTranslation) { userState in
                app.switches["TranslateSwitchValue"].tap()
        }
        screenState.gesture(forAction: Action.EnableTranslation) { userState in
            app.switches["TranslateSwitchValue"].tap()
        }
        screenState.gesture(forAction: Action.SelectGoogle) { userstate in
            app.tables.cells.element(boundBy:1).tap()
        }
        screenState.gesture(forAction: Action.SelectBing) { userstate in
                app.tables.cells.element(boundBy:2).tap()
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(SearchSettings) { screenState in
        let table = app.tables.element(boundBy: 0)
        screenState.tap(table.cells["customEngineViewButton"], to: AddCustomSearchSettings)
        screenState.backAction = navigationControllerBackAction
        screenState.gesture(forAction: Action.RemoveCustomSearchEngine) {userSTate in
            // Screengraph will go back to main Settings screen. Manually tap on settings
            app.tables["AppSettingsTableViewController.tableView"].staticTexts["Google"].tap()
            app.navigationBars["Search"].buttons["Edit"].tap()
            app.tables.buttons["Delete Mozilla Engine"].tap()
            app.tables.buttons["Delete"].tap()
        }
    }

    map.addScreenState(SiriSettings) { screenState in
        screenState.gesture(forAction: Action.OpenSiriFromSettings) { userState in
            // Tap on Open New Tab to open Siri
            app.cells["SiriSettings"].staticTexts.element(boundBy: 0).tap()
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
                app.webViews.textFields.firstMatch.tap()
                app.webViews.textFields.firstMatch.typeText(userState.fxaUsername!)
            } else {
                app.textFields["Email"].tap()
                app.textFields["Email"].typeText(userState.fxaUsername!)
            }
        }
        screenState.gesture(forAction: Action.FxATypePassword) { userState in
            app.secureTextFields.element(boundBy: 0).tap()
            app.secureTextFields.element(boundBy: 0).typeText(userState.fxaPassword!)
        }
        screenState.gesture(forAction: Action.FxATapOnContinueButton) { userState in
            app.webViews.buttons["Continue"].tap()
        }
        screenState.gesture(forAction: Action.FxATapOnSignInButton) { userState in
            app.webViews.buttons.element(boundBy: 0).tap()
        }
        screenState.tap(app.webViews.links["Create an account"].firstMatch, to: FxCreateAccount)
    }

    map.addScreenState(FxCreateAccount) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(AddCustomSearchSettings) { screenState in
        screenState.gesture(forAction: Action.AddCustomSearchEngine) { userState in
            app.tables.textViews["customEngineTitle"].staticTexts["Search Engine"].tap()
            app.typeText("Mozilla Engine")
            app.tables.textViews["customEngineUrl"].tap()
            
            UIPasteboard.general.string = "https://developer.mozilla.org/search?q=%s"
            
            let tablesQuery = app.tables
            let customengineurlTextView = tablesQuery.textViews["customEngineUrl"]
            sleep(1)
            customengineurlTextView.press(forDuration: 1.0)
            app.staticTexts["Paste"].tap()
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(WebsiteDataSettings) { screenState in
        screenState.gesture(forAction: Action.AcceptClearAllWebsiteData) { userState in
            app.tables.cells["ClearAllWebsiteData"].tap()
            app.alerts.buttons["OK"].tap()
        }
        // The swipeDown() is a workaround for an intermitent issue that the search filed is not always in view.
        screenState.gesture(forAction: Action.TapOnFilterWebsites) { userState in
            app.searchFields["Filter Sites"].tap()
        }
        screenState.gesture(forAction: Action.ShowMoreWebsiteDataEntries) { userState in
            app.tables.cells["ShowMoreWebsiteData"].tap()
        }
        screenState.backAction = navigationControllerBackAction
    }
    
    map.addScreenState(NewTabSettings) { screenState in
        let table = app.tables.element(boundBy: 0)

        screenState.gesture(forAction: Action.SelectNewTabAsBlankPage) { UserState in
            table.cells["NewTabAsBlankPage"].tap()
        }
        screenState.gesture(forAction: Action.SelectNewTabAsFirefoxHomePage) { UserState in
            table.cells["NewTabAsFirefoxHome"].tap()
        }
        screenState.gesture(forAction: Action.SelectNewTabAsCustomURL) { UserState in
            table.cells["NewTabAsCustomURL"].tap()
        }

        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(HomeSettings) { screenState in
        screenState.gesture(forAction: Action.SelectHomeAsFirefoxHomePage) { UserState in
            app.cells["HomeAsFirefoxHome"].tap()
        }

        screenState.gesture(forAction: Action.SelectHomeAsCustomURL) { UserState in
            app.cells["HomeAsCustomURL"].tap()
        }

        screenState.gesture(forAction: Action.TogglePocketInNewTab) { userState in
            userState.pocketInNewTab = !userState.pocketInNewTab
            app.switches["ASPocketStoriesVisible"].tap()
        }

        screenState.gesture(forAction: Action.SelectTopSitesRows) { userState in
            app.tables.cells["TopSitesRows"].tap()
            select(rows: userState.numTopSitesRows)
            app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
        }

        screenState.backAction = navigationControllerBackAction
    }

    func select(rows: Int) {
        app.staticTexts[String(rows)].firstMatch.tap()
    }

    map.addScreenState(PasscodeSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
        let table = app.tables.element(boundBy: 0)
        screenState.tap(table.cells["TurnOnPasscode"], to: SetPasscodeScreen, if: "passcode == nil")
        screenState.tap(table.cells["TurnOffPasscode"], to: DisablePasscodeSettings, if: "passcode != nil")
        screenState.tap(table.cells["PasscodeInterval"], to: PasscodeIntervalSettings, if: "passcode != nil")
        screenState.tap(table.cells["ChangePasscode"], to: ChangePasscodeSettings, if: "passcode != nil")
    }

    func type(text: String) {
        text.forEach { char in
            app.keys[String(char)].tap()
        }
    }

    map.addScreenState(SetPasscodeScreen) { screenState in
        screenState.gesture(forAction: Action.SetPasscode, transitionTo: PasscodeSettings) { userState in
            type(text: userState.newPasscode)
            type(text: userState.newPasscode)
            userState.passcode = userState.newPasscode
        }

        screenState.gesture(forAction: Action.SetPasscodeTypeOnce) { userState in
            type(text: userState.newPasscode)
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(DisablePasscodeSettings) { screenState in
        screenState.gesture(forAction: Action.DisablePasscode, transitionTo: PasscodeSettings) { userState in
            if let passcode = userState.passcode {
                type(text: passcode)
            }
        }

        screenState.gesture(forAction: Action.DisablePasscodeTypeIncorrectPasscode) { userState in
            type(text: userState.wrongPasscode)
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(PasscodeIntervalSettings) { screenState in
        screenState.onEnter { userState in
            if let passcode = userState.passcode {
                type(text: passcode)
            }
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(ChangePasscodeSettings) { screenState in
        screenState.gesture(forAction: Action.ChangePasscode, transitionTo: PasscodeSettings) { userState in
            if let passcode = userState.passcode {
                type(text: passcode)
                type(text: userState.newPasscode)
                type(text: userState.newPasscode)
                userState.passcode = userState.newPasscode
            }
        }

        screenState.gesture(forAction: Action.ConfirmPasscodeToChangePasscode) { userState in
            if let passcode = userState.passcode {
                type(text: passcode)
            }
        }
        screenState.gesture(forAction: Action.ChangePasscodeTypeOnce) { userState in
            type(text: userState.newPasscode)
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(LoginsSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(LockedLoginsSettings) { screenState in
        screenState.backAction = cancelTypePasscode
        screenState.dismissOnUse = true

        screenState.gesture(forAction: Action.LoginPasscodeTypeIncorrectOne) { userState in
            type(text: userState.wrongPasscode)
        }

        // Gesture to get to the protected screen.
        screenState.gesture(forAction: Action.UnlockLoginsSettings, transitionTo: LoginsSettings) { userState in
            if let passcode = userState.passcode {
                type(text: passcode)
            }
        }
    }

    map.addScreenState(ClearPrivateDataSettings) { screenState in
        let table = app.tables.element(boundBy: 0)
        screenState.tap(app.cells["WebsiteData"], to: WebsiteDataSettings)
        screenState.gesture(forAction: Action.AcceptClearPrivateData) { userState in
            app.tables.cells["ClearPrivateData"].tap()
            app.alerts.buttons["OK"].tap()
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(OpenWithSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(ShowTourInSettings) { screenState in
        screenState.gesture(to: Intro_FxASignin) {
            let turnOnSyncButton = app.buttons["signInOnboardingButton"]
            turnOnSyncButton.tap()
        }
    }

    map.addScreenState(TrackingProtectionSettings) { screenState in
        screenState.backAction = navigationControllerBackAction

        screenState.tap(app.switches["prefkey.trackingprotection.normalbrowsing"], forAction: Action.SwitchETP) { userState in
            userState.trackingProtectionSettingOnNormalMode = !userState.trackingProtectionSettingOnNormalMode
        }
    }

    map.addScreenState(Intro_FxASignin) { screenState in
        screenState.tap(app.navigationBars["Client.FirefoxAccountSignInView"].buttons.element(boundBy: 0), to: HomePanelsScreen)
        screenState.tap(app.buttons["EmailSignIn.button"], forAction: Action.OpenEmailToSignIn, transitionTo: FxASigninScreen)
        screenState.tap(app.buttons["QRCodeSignIn.button"], forAction: Action.OpenEmailToQR, transitionTo: Intro_FxASignin)

        screenState.tap(app.navigationBars["Turn on Sync"].buttons["Settings"], to: SettingsScreen)
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(TabTray) { screenState in
        screenState.tap(app.buttons["TabTrayController.addTabButton"], forAction: Action.OpenNewTabFromTabTray, transitionTo: NewTabScreen)
        screenState.tap(app.buttons["TabTrayController.maskButton"], forAction: Action.TogglePrivateMode) { userState in
            userState.isPrivate = !userState.isPrivate
        }
        screenState.tap(app.buttons["TabTrayController.removeTabsButton"], to: CloseTabMenu)

        screenState.onEnter { userState in
            userState.numTabs = Int(app.collectionViews.cells.count)
        }
    }

    // This menu is only available for iPhone, NOT for iPad, no menu when long tapping on tabs button
    if !isTablet {
        map.addScreenState(TabTrayLongPressMenu) { screenState in
            screenState.dismissOnUse = true
            screenState.tap(app.cells["quick_action_new_tab"], forAction: Action.OpenNewTabLongPressTabsButton, transitionTo: NewTabScreen)
            screenState.tap(app.cells["tab_close"], forAction: Action.CloseTabFromTabTrayLongPressMenu, Action.CloseTab, transitionTo: HomePanelsScreen)
            screenState.tap(app.cells["nav-tabcounter"], forAction: Action.OpenPrivateTabLongPressTabsButton, transitionTo: NewTabScreen) { userState in
                userState.isPrivate = !userState.isPrivate
            }
        }
    }

    map.addScreenState(CloseTabMenu) { screenState in
        screenState.tap(app.sheets.buttons["TabTrayController.deleteButton.closeAll"], forAction: Action.AcceptRemovingAllTabs, transitionTo: HomePanelsScreen)
        screenState.backAction = cancelBackAction
    }

    func makeURLBarAvailable(_ screenState: MMScreenStateNode<FxUserState>) {
        screenState.tap(app.textFields["url"], to: URLBarOpen)
        screenState.gesture(to: URLBarLongPressMenu) {
            sleep(1)
            app.textFields["url"].press(forDuration: 1.0)
        }
    }

    func makeToolBarAvailable(_ screenState: MMScreenStateNode<FxUserState>) {
        screenState.tap(app.buttons["TabToolbar.menuButton"], to: BrowserTabMenu)
        if isTablet {
            screenState.tap(app.buttons["TopTabsViewController.tabsButton"], to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                if (app.buttons["TabToolbar.tabsButton"].exists) {
                    app.buttons["TabToolbar.tabsButton"].tap()
                } else {
                    app.buttons["URLBarView.tabsButton"].tap()
                }
            }
        }
    }

    map.addScreenState(BrowserTab) { screenState in
        makeURLBarAvailable(screenState)
        screenState.tap(app.buttons["TabLocationView.pageOptionsButton"], to: PageOptionsMenu)
        screenState.tap(app.buttons["TabToolbar.menuButton"], to: BrowserTabMenu)

        screenState.tap(app.buttons["TabLocationView.trackingProtectionButton"], to: TrackingProtectionContextMenuDetails)

        makeToolBarAvailable(screenState)
        let link = app.webViews.element(boundBy: 0).links.element(boundBy: 0)
        let image = app.webViews.element(boundBy: 0).images.element(boundBy: 0)

        screenState.press(link, to: WebLinkContextMenu)
        screenState.press(image, to: WebImageContextMenu)
        
        if !isTablet {
            let reloadButton = app.buttons["TabToolbar.stopReloadButton"]
        screenState.press(reloadButton, to: ReloadLongPressMenu)
        screenState.tap(reloadButton, forAction: Action.ReloadURL, transitionTo: WebPageLoading) { _ in }
        } else {
            let reloadButton = app.buttons["Reload"]
        screenState.press(reloadButton, to: ReloadLongPressMenu)
        screenState.tap(reloadButton, forAction: Action.ReloadURL, transitionTo: WebPageLoading) { _ in }
        }
        // For iPad there is no long press on tabs button
        if !isTablet {
            let tabsButton = app.buttons["TabToolbar.tabsButton"]
            screenState.press(tabsButton, to: TabTrayLongPressMenu)
        }

        if isTablet {
            screenState.tap(app.buttons["TopTabsViewController.tabsButton"], to: TabTray)
        } else {
            screenState.gesture(to: TabTray) {
                if (app.buttons["TabToolbar.tabsButton"].exists) {
                    app.buttons["TabToolbar.tabsButton"].tap()
                } else {
                    app.buttons["URLBarView.tabsButton"].tap()
                }
            }
        }

        screenState.tap(app.buttons["Private Mode"], forAction: Action.TogglePrivateModeFromTabBarBrowserTab) { userState in
            userState.isPrivate = !userState.isPrivate
        }

        screenState.noop(to: TranslatePageMenu, if: "localeIsExpectedDifferent == true")
    }

    map.addScreenState(TranslatePageMenu) { screenState in
        screenState.onEnterWaitFor(element: app.buttons["TranslationPrompt.doTranslate"])

        screenState.tap(app.buttons["TranslationPrompt.dontTranslate"], forAction: Action.SelectDontTranslateThisPage)

        screenState.tap(app.buttons["TranslationPrompt.doTranslate"], forAction: Action.SelectTranslateThisPage, transitionTo: WebPageLoading)
        screenState.dismissOnUse = true
    }

    map.addScreenState(ReloadLongPressMenu) { screenState in
        screenState.backAction = cancelBackAction
        screenState.dismissOnUse = true

        let rdsButton = app.tables["Context Menu"].cells.element(boundBy: 0)
        screenState.tap(rdsButton, forAction: Action.ToggleRequestDesktopSite) { userState in
            userState.requestDesktopSite = !userState.requestDesktopSite
        }

        let trackingProtectionButton = app.tables["Context Menu"].cells.element(boundBy: 1)

        screenState.tap(trackingProtectionButton, forAction: Action.ToggleTrackingProtectionPerTabEnabled) { userState in
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

    // make sure after the menu action, navigator.nowAt() is used to set the current state
    map.addScreenState(PageOptionsMenu) {screenState in
        screenState.tap(app.tables["Context Menu"].cells["menu-RequestDesktopSite"], to: RequestDesktopSite)
        screenState.tap(app.tables["Context Menu"].cells["menu-FindInPage"], to: FindInPage)
        screenState.tap(app.tables["Context Menu"].cells["menu-Bookmark"], forAction: Action.BookmarkThreeDots, Action.Bookmark)
        screenState.tap(app.tables.cells["action_pin"], forAction: Action.PinToTopSitesPAM)
        screenState.tap(app.tables.cells["menu-Copy-Link"], forAction: Action.CopyAddressPAM)
        screenState.backAction = cancelBackAction
        screenState.dismissOnUse = true
    }

    map.addScreenState(FxAccountManagementPage) { screenState in
        screenState.backAction = navigationControllerBackAction
    }
    
    map.addScreenState(FindInPage) { screenState in
        screenState.tap(app.buttons["FindInPage.close"], to: BrowserTab)
    }

    map.addScreenState(RequestDesktopSite) { _ in }

    map.addScreenState(HomePanel_Library) { screenState in
        screenState.dismissOnUse = true
        screenState.backAction = navigationControllerBackAction

        screenState.tap(app.buttons["LibraryPanels.Bookmarks"], to: LibraryPanel_Bookmarks)
        screenState.tap(app.buttons["LibraryPanels.History"], to: LibraryPanel_History)
        screenState.tap(app.buttons["LibraryPanels.ReadingList"], to: LibraryPanel_ReadingList)
        screenState.tap(app.buttons["LibraryPanels.Downloads"], to: LibraryPanel_Downloads)
        screenState.tap(app.buttons["LibraryPanels.SyncedTabs"], to: LibraryPanel_SyncedTabs)
    }

    map.addScreenState(BrowserTabMenu) { screenState in
        screenState.tap(app.tables.cells["menu-Settings"], to: SettingsScreen)
        screenState.tap(app.tables.cells["menu-sync"], to: Intro_FxASignin, if: "fxaUsername == nil")
        screenState.tap(app.tables.cells["key"], to: LoginsSettings)
        screenState.tap(app.tables.cells["menu-library"], to: HomePanel_Library)
        screenState.tap(app.tables.cells["placeholder-avatar"], to: FxAccountManagementPage)

        screenState.tap(app.tables.cells["menu-NoImageMode"], forAction: Action.ToggleNoImageMode, transitionTo: BrowserTabMenu) { userState in
            userState.noImageMode = !userState.noImageMode
        }

        screenState.tap(app.tables.cells["menu-NightMode"], forAction: Action.ToggleNightMode, transitionTo: BrowserTabMenu) { userState in
            userState.nightMode = !userState.nightMode
        }

        screenState.tap(app.tables.cells["menu-Home"], forAction: Action.GoToHomePage) { userState in
        }
        screenState.tap(app.tables.cells["whatsnew"], forAction: Action.OpenWhatsNewPage) { userState in
        }

        screenState.dismissOnUse = true
        screenState.backAction = cancelBackAction
    }

    return map
}

extension MMNavigator where T == FxUserState {

    func openURL(_ urlString: String, waitForLoading: Bool = true) {
        UIPasteboard.general.string = urlString
        userState.url = urlString
        userState.waitForLoading = waitForLoading
        performAction(Action.LoadURL)
    }

    // Opens a URL in a new tab.
    func openNewURL(urlString: String) {
        let app = XCUIApplication()
        if isTablet {
            waitForExistence(app.buttons["TopTabsViewController.tabsButton"], timeout: 15)
        } else {
            waitForExistence(app.buttons["TabToolbar.tabsButton"], timeout: 10)
        }
        self.goto(TabTray)
        createNewTab()
        self.openURL(urlString)
    }

    // Add a new Tab from the New Tab option in Browser Tab Menu
    func createNewTab() {
        let app = XCUIApplication()
        self.goto(TabTray)
        app.buttons["TabTrayController.addTabButton"].tap()
        self.nowAt(NewTabScreen)
    }

    // Add Tab(s) from the Tab Tray
    func createSeveralTabsFromTabTray(numberTabs: Int) {
        let app = XCUIApplication()
        for _ in 1...numberTabs {
            if isTablet {
                waitForExistence(app.buttons["TopTabsViewController.tabsButton"], timeout: 5)
            } else {
                waitForExistence(app.buttons["TabToolbar.tabsButton"], timeout: 5)
            }
            self.goto(TabTray)
            self.goto(HomePanelsScreen)
        }
    }

    func browserPerformAction(_ view: BrowserPerformAction) {
        let PageMenuOptions = [.shareOption, .toggleBookmarkOption, .addReadingListOption, .findInPageOption, .sendToDeviceOption, .toggleDesktopOption, BrowserPerformAction.copyURLOption]
        let BrowserMenuOptions = [.openTopSitesOption, .toggleHideImages, .toggleNightMode, BrowserPerformAction.openSettingsOption]

        let app = XCUIApplication()

        if PageMenuOptions.contains(view) {
            self.goto(PageOptionsMenu)
            app.tables["Context Menu"].cells[view.rawValue].tap()
        } else if BrowserMenuOptions.contains(view) {
            waitForExistence(app.buttons["TabToolbar.menuButton"], timeout: 5)
            self.goto(BrowserTabMenu)
            app.tables["Context Menu"].cells[view.rawValue].tap()
        }
    }
}
enum BrowserPerformAction: String {
    // Page Menu
    case toggleBookmarkOption  = "menu-Bookmark"
    case addReadingListOption = "addToReadingList"
    case copyURLOption = "menu-Copy-Link"
    case findInPageOption = "menu-FindInPage"
    case toggleDesktopOption = "menu-RequestDesktopSite"
    case pinToTopSitesOption = "action_pin"
    case sendToDeviceOption = "menu-Send-to-Device"
    case shareOption = "action_share"

    // Tab Menu
    case openTopSitesOption = "menu-panel-TopSites"
    case openBookMarksOption = "menu-panel-Bookmarks"
    case openHistoryOption = "menu-panel-History"
    case openReadingListOption = "menu-panel-ReadingList"
    case toggleHideImages = "menu-NoImageMode"
    case toggleNightMode = "menu-NightMode"
    case openSettingsOption = "menu-Settings"
}

extension XCUIElement {
    /// For tables only: scroll the table downwards until
    /// the end is reached.
    /// Each time a whole screen has scrolled, the passed closure is
    /// executed with the index number of the screen.
    /// Care is taken to make sure that every cell is completely on screen
    /// at least once.
    func forEachScreen(_ eachScreen: (Int) -> ()) {
        guard self.elementType == .table else {
            return
        }

        func firstInvisibleCell(_ start: UInt) -> UInt {
            let cells = self.cells
            for i in start ..< UInt(cells.count) {
                let cell = cells.element(boundBy: Int(i))
                // if the cell's bottom is beyond the table's bottom
                // i.e. if the cell isn't completely visible.
                if self.frame.maxY <= cell.frame.maxY  {
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
