/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
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
let FindInPage = "FindInPage"
let SettingsScreen = "SettingsScreen"
let SyncSettings = "SyncSettings"
let HomePageSettings = "HomePageSettings"
let PasscodeSettings = "PasscodeSettings"
let PasscodeIntervalSettings = "PasscodeIntervalSettings"
let SearchSettings = "SearchSettings"
let NewTabSettings = "NewTabSettings"
let ClearPrivateDataSettings = "ClearPrivateDataSettings"
let LoginsSettings = "LoginsSettings"
let OpenWithSettings = "OpenWithSettings"
let ShowTourInSettings = "ShowTourInSettings"
let TrackingProtectionSettings = "TrackingProtectionSettings"
let Intro_FxASignin = "Intro_FxASignin"
let WebImageContextMenu = "WebImageContextMenu"
let WebLinkContextMenu = "WebLinkContextMenu"
let CloseTabMenu = "CloseTabMenu"
let AddCustomSearchSettings = "AddCustomSearchSettings"
let NewTabChoiceSettings = "NewTabChoiceSettings"

// These are in the exact order they appear in the settings
// screen. XCUIApplication loses them on small screens.
// This list should only be for settings screens that can be navigated to
// without changing userState. i.e. don't need conditional edges to be available
let allSettingsScreens = [
    SearchSettings,
    AddCustomSearchSettings,
    NewTabSettings,
    NewTabChoiceSettings,
    HomePageSettings,
    OpenWithSettings,

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
let Intro_Search = "Intro.Search"
let Intro_Private = "Intro.Private"
let Intro_Mail = "Intro.Mail"
let Intro_Sync = "Intro.Sync"

let allIntroPages = [
    Intro_Welcome,
    Intro_Search,
    Intro_Private,
    Intro_Mail,
    Intro_Sync
]

let HomePanelsScreen = "HomePanels"
let PrivateHomePanelsScreen = "PrivateHomePanels"
let HomePanel_TopSites = "HomePanel.TopSites.0"
let HomePanel_Bookmarks = "HomePanel.Bookmarks.1"
let HomePanel_History = "HomePanel.History.2"
let HomePanel_ReadingList = "HomePanel.ReadingList.3"
let P_HomePanel_TopSites = "P_HomePanel.TopSites.0"
let P_HomePanel_Bookmarks = "P_HomePanel.Bookmarks.1"
let P_HomePanel_History = "P_HomePanel.History.2"
let P_HomePanel_ReadingList = "P_HomePanel.ReadingList.3"

let allHomePanels = [
    HomePanel_Bookmarks,
    HomePanel_TopSites,
    HomePanel_History,
    HomePanel_ReadingList
]
let allPrivateHomePanels = [
    P_HomePanel_Bookmarks,
    P_HomePanel_TopSites,
    P_HomePanel_History,
    P_HomePanel_ReadingList
]

class Action {
    static let LoadURL = "LoadURL"
    static let LoadURLByTyping = "LoadURLByTyping"
    static let LoadURLByPasting = "LoadURLByPasting"

    static let SetURL = "SetURL"
    static let SetURLByTyping = "SetURLByTyping"
    static let SetURLByPasting = "SetURLByPasting"

    static let ReloadURL = "ReloadURL"

    static let TogglePrivateMode = "TogglePrivateBrowing"
    static let ToggleRequestDesktopSite = "ToggleRequestDesktopSite"
    static let ToggleNightMode = "ToggleNightMode"
    static let ToggleNoImageMode = "ToggleNoImageMode"

    static let Bookmark = "Bookmark"
    static let BookmarkThreeDots = "BookmarkThreeDots"

    static let SetPasscode = "SetPasscode"
    static let SetPasscodeTypeOnce = "SetPasscodeTypeOnce"

    static let TogglePocketInNewTab = "TogglePocketInNewTab"

    static let AcceptClearPrivateData = "AcceptClearPrivateData"
}

private var isTablet: Bool {
    // There is more value in a variable having the same name,
    // so it can be used in both predicates and in code
    // than avoiding the duplication of one line of code.
    return UIDevice.current.userInterfaceIdiom == .pad
}

class FxUserState: UserState {
    required init() {
        super.init()
        initialScreenState = FirstRun
    }

    var isTablet: Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }

    var isPrivate = false
    var showIntro = false
    var showWhatsNew = false
    var waitForLoading = true
    var url: String? = nil
    var requestDesktopSite = false

    var passcode: String? = nil
    var newPasscode: String = "111111"

    var noImageMode = false
    var nightMode = false

    var pocketInNewTab = false

    var fxaUsername: String? = nil
    var fxaPassword: String? = nil

    var numTabs: Int = 0
}

fileprivate let defaultURL = "https://www.mozilla.org/en-US/book/"

func createScreenGraph(for test: XCTestCase, with app: XCUIApplication) -> ScreenGraph<FxUserState> {
    let map = ScreenGraph(for: test, with: FxUserState.self)

    let navigationControllerBackAction = {
        app.navigationBars.element(boundBy: 0).buttons.element(boundBy: 0).tap()
    }

    let cancelBackAction = {
        if isTablet {
            // There is no Cancel option in iPad.
            app/*@START_MENU_TOKEN@*/.otherElements["PopoverDismissRegion"]/*[[".otherElements[\"dismiss popup\"]",".otherElements[\"PopoverDismissRegion\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        } else {
            app.buttons["PhotonMenu.cancel"].tap()
        }
    }

    let dismissContextMenuAction = {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25)).tap()
    }

    let introScrollView = app.scrollViews["IntroViewController.scrollView"]
    map.addScreenState(FirstRun) { screenState in
        screenState.noop(to: BrowserTab, if: "showIntro == false && showWhatsNew == true")
        screenState.noop(to: NewTabScreen, if: "showIntro == false && showWhatsNew == false")
        screenState.noop(to: allIntroPages[0], if: "showIntro == true")
    }

    // Add the intro screens.
    var i = 0
    let introLast = allIntroPages.count - 1
    let introPager = app.scrollViews["IntroViewController.scrollView"]
    for intro in allIntroPages {
        let prev = i == 0 ? nil : allIntroPages[i - 1]
        let next = i == introLast ? nil : allIntroPages[i + 1]

        map.addScreenState(intro) { screenState in
            if let prev = prev {
                screenState.swipeRight(introPager, to: prev)
            }

            if let next = next {
                screenState.swipeLeft(introPager, to: next)
            }

            if i > 0 {
                let startBrowsingButton = app.buttons["IntroViewController.startBrowsingButton"]
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
        makeURLBarAvailable(screenState)
        screenState.tap(app.buttons["TabToolbar.menuButton"], to: BrowserTabMenu)
    }

    map.addScreenState(URLBarLongPressMenu) { screenState in
        let menu = app.sheets.element(boundBy: 0)
        screenState.onEnterWaitFor(element: menu)

        screenState.gesture(forAction: Action.LoadURLByPasting, Action.LoadURL) { userState in
            UIPasteboard.general.string = userState.url ?? defaultURL
            menu.buttons.element(boundBy: 0).tap()
        }

        screenState.gesture(forAction: Action.SetURLByPasting) { userState in
            UIPasteboard.general.string = userState.url ?? defaultURL
            menu.buttons.element(boundBy: 1).tap()
        }

        screenState.backAction = {
            let buttons = menu.buttons
            buttons.element(boundBy: buttons.count - 1).tap()
        }

        screenState.dismissOnUse = true
    }

    // URLBarOpen is dismissOnUse, which ScreenGraph interprets as "now we've done this action, then go back to the one before it"
    // but SetURL is an action than keeps us in URLBarOpen. So let's put it here.
    map.addScreenAction(Action.SetURL, transitionTo: URLBarOpen)

    map.addScreenState(URLBarOpen) { screenState in
        // This is used for opening BrowserTab with default mozilla URL
        // For custom URL, should use Navigator.openNewURL or Navigator.openURL.
        screenState.gesture(forAction: Action.LoadURLByTyping, Action.LoadURL) { userState in
            let url = userState.url ?? defaultURL
            app.textFields["address"].typeText("\(url)\r")
        }

        screenState.gesture(forAction: Action.SetURLByTyping, Action.SetURL) { userState in
            let url = userState.url ?? defaultURL
            app.textFields["address"].typeText("\(url)")
        }

        screenState.noop(to: HomePanelsScreen)

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
        screenState.onEnterWaitFor("exists != true",
                                   element: app.progressIndicators.element(boundBy: 0),
                                   if: "waitForLoading == true")

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
        screenState.tap(app.buttons["HomePanels.TopSites"], to: HomePanel_TopSites)
        screenState.tap(app.buttons["HomePanels.Bookmarks"], to: HomePanel_Bookmarks)
        screenState.tap(app.buttons["HomePanels.History"], to: HomePanel_History)
        screenState.tap(app.buttons["HomePanels.ReadingList"], to: HomePanel_ReadingList)

        // Workaround to bug Bug 1417522
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

    map.addScreenState(HomePanel_Bookmarks) { screenState in
        let bookmarkCell = app.tables["Bookmarks List"].cells.element(boundBy: 0)
        screenState.press(bookmarkCell, to: BookmarksPanelContextMenu)
        screenState.noop(to: HomePanelsScreen)
    }

    map.addScreenState(HomePanel_TopSites) { screenState in
        let topSites = app.cells["TopSitesCell"]
        screenState.press(topSites.cells.matching(identifier: "TopSite").element(boundBy: 0), to: TopSitesPanelContextMenu)
        screenState.noop(to: HomePanelsScreen)
    }

    map.addScreenState(HomePanel_History) { screenState in
        screenState.press(app.tables["History List"].cells.element(boundBy: 2), to: HistoryPanelContextMenu)
        screenState.noop(to: HomePanelsScreen)
    }

    map.addScreenState(HomePanel_ReadingList) { screenState in
        screenState.noop(to: HomePanelsScreen)
    }

    map.addScreenState(HistoryPanelContextMenu) { screenState in
        screenState.dismissOnUse = true
        screenState.backAction = dismissContextMenuAction
    }

    map.addScreenState(TopSitesPanelContextMenu) { screenState in
        screenState.dismissOnUse = true
        screenState.backAction = dismissContextMenuAction
    }

    map.addScreenState(BookmarksPanelContextMenu) { screenState in
        screenState.dismissOnUse = true
        screenState.backAction = dismissContextMenuAction
    }

    map.addScreenState(SettingsScreen) { screenState in
        let table = app.tables.element(boundBy: 0)

        screenState.tap(table.cells["Sync"], to: SyncSettings, if: "fxaUsername != nil")
        screenState.tap(table.cells["Search"], to: SearchSettings)
        screenState.tap(table.cells["NewTab"], to: NewTabSettings)
        screenState.tap(table.cells["Homepage"], to: HomePageSettings)
        screenState.tap(table.cells["OpenWith.Setting"], to: OpenWithSettings)
        screenState.tap(table.cells["TouchIDPasscode"], to: PasscodeSettings)
        screenState.tap(table.cells["Logins"], to: LoginsSettings)
        screenState.tap(table.cells["ClearPrivateData"], to: ClearPrivateDataSettings)
        screenState.tap(table.cells["TrackingProtection"], to: TrackingProtectionSettings)
        screenState.tap(table.cells["ShowTour"], to: ShowTourInSettings)

        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(SearchSettings) { screenState in
        let table = app.tables.element(boundBy: 0)
        screenState.tap(table.cells["customEngineViewButton"], to: AddCustomSearchSettings)
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(SyncSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(AddCustomSearchSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(NewTabSettings) { screenState in
        let table = app.tables.element(boundBy: 0)
        screenState.tap(table.cells["NewTabOption"], to: NewTabChoiceSettings)
        screenState.gesture(forAction: Action.TogglePocketInNewTab) { userState in
            userState.pocketInNewTab = !userState.pocketInNewTab
            table.switches["ASPocketStoriesVisible"].tap()
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(NewTabChoiceSettings) { screenState in
        let table = app.tables.element(boundBy: 0)
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(HomePageSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(PasscodeSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
        let table = app.tables.element(boundBy: 0)
        screenState.tap(table.cells["TurnOnPasscode"], to: SetPasscodeScreen, if: "passcode == nil")
        screenState.tap(table.cells["PasscodeInterval"], to: PasscodeIntervalSettings, if: "passcode != nil")
    }

    func typePasscode(_ passCode: String) {
        passCode.forEach { char in
            app.keys["\(char)"].tap()
        }
    }

    map.addScreenState(SetPasscodeScreen) { screenState in
        screenState.gesture(forAction: Action.SetPasscode, transitionTo: PasscodeSettings) { userState in
            typePasscode(userState.newPasscode)
            typePasscode(userState.newPasscode)
            userState.passcode = userState.newPasscode
        }

        screenState.gesture(forAction: Action.SetPasscodeTypeOnce) { userState in
            typePasscode(userState.newPasscode)
        }
    }

    map.addScreenState(PasscodeIntervalSettings) { screenState in
        screenState.onEnter { userState in
            if let passcode = userState.passcode {
                typePasscode(passcode)
            }
        }
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(LoginsSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(ClearPrivateDataSettings) { screenState in
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
            let introScrollView = app.scrollViews["IntroViewController.scrollView"]
            for _ in 1...4 {
                introScrollView.swipeLeft()
            }
            app.buttons["Sign in to Firefox"].tap()
        }
        screenState.backAction = {
            introScrollView.swipeLeft()
            let startBrowsingButton = app.buttons["IntroViewController.startBrowsingButton"]
            startBrowsingButton.tap()
        }
    }

    map.addScreenState(TrackingProtectionSettings) { screenState in
        screenState.backAction = navigationControllerBackAction
    }

    map.addScreenState(Intro_FxASignin) { screenState in
       screenState.tap(app.navigationBars["Client.FxAContentView"].buttons.element(boundBy: 0), to: HomePanelsScreen)
    }

    map.addScreenState(TabTray) { screenState in
        screenState.tap(app.buttons["TabTrayController.addTabButton"], to: NewTabScreen)
        screenState.tap(app.buttons["TabTrayController.maskButton"], forAction: Action.TogglePrivateMode) { userState in
            userState.isPrivate = !userState.isPrivate
        }
        screenState.tap(app.buttons["TabTrayController.removeTabsButton"], to: CloseTabMenu)

        screenState.onEnter { userState in
            userState.numTabs = Int(app.collectionViews.cells.count)
        }
    }

    map.addScreenState(CloseTabMenu) { screenState in
        screenState.backAction = cancelBackAction
    }

    let lastButtonIsCancel = {
        let lastIndex = app.sheets.element(boundBy: 0).buttons.count - 1
        app.sheets.element(boundBy: 0).buttons.element(boundBy: lastIndex).tap()
    }

    func makeURLBarAvailable(_ screenState: ScreenStateNode<FxUserState>) {

        screenState.tap(app.textFields["url"], to: URLBarOpen)
        screenState.gesture(to: URLBarLongPressMenu) {
            app.textFields["url"].press(forDuration: 1.0)
        }
    }

    func makeToolBarAvailable(_ screenState: ScreenStateNode<FxUserState>) {
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

        makeToolBarAvailable(screenState)
        let link = app.webViews.element(boundBy: 0).links.element(boundBy: 0)
        let image = app.webViews.element(boundBy: 0).images.element(boundBy: 0)

        screenState.press(link, to: WebLinkContextMenu)
        screenState.press(image, to: WebImageContextMenu)

        let reloadButton = app.buttons["TabToolbar.stopReloadButton"]
        screenState.press(reloadButton, to: ReloadLongPressMenu)
        screenState.tap(reloadButton, forAction: Action.ReloadURL, transitionTo: WebPageLoading) { _ in }
    }

    map.addScreenState(ReloadLongPressMenu) { screenState in
        screenState.backAction = lastButtonIsCancel
        screenState.dismissOnUse = true

        let rdsButton = app.sheets.element(boundBy: 0).buttons.element(boundBy: 0)
        screenState.tap(rdsButton, forAction: Action.ToggleRequestDesktopSite) { userState in
            userState.requestDesktopSite = !userState.requestDesktopSite
        }
    }

    map.addScreenState(WebImageContextMenu) { screenState in
        screenState.dismissOnUse = true
        screenState.backAction = lastButtonIsCancel
    }

    map.addScreenState(WebLinkContextMenu) { screenState in
        screenState.dismissOnUse = true
        screenState.backAction = lastButtonIsCancel
    }

    // make sure after the menu action, navigator.nowAt() is used to set the current state
    map.addScreenState(PageOptionsMenu) {screenState in
        screenState.tap(app.tables["Context Menu"].cells["menu-FindInPage"], to: FindInPage)
        screenState.tap(app.tables["Context Menu"].cells["menu-Bookmark"], forAction: Action.BookmarkThreeDots, Action.Bookmark)
        screenState.backAction = cancelBackAction
        screenState.dismissOnUse = true
    }

    map.addScreenState(FindInPage) { screenState in
        screenState.tap(app.buttons["FindInPage.close"], to: BrowserTab)
    }

    map.addScreenState(BrowserTabMenu) { screenState in
        screenState.tap(app.tables.cells["menu-Settings"], to: SettingsScreen)

        screenState.tap(app.tables.cells["menu-panel-TopSites"], to: HomePanel_TopSites)
        screenState.tap(app.tables.cells["menu-panel-Bookmarks"], to: HomePanel_Bookmarks)
        screenState.tap(app.tables.cells["menu-panel-History"], to: HomePanel_History)
        screenState.tap(app.tables.cells["menu-panel-ReadingList"], to: HomePanel_ReadingList)

        screenState.tap(app.tables.cells["menu-NoImageMode"], forAction: Action.ToggleNoImageMode) { userState in
            userState.noImageMode = !userState.noImageMode
        }

        screenState.tap(app.tables.cells["menu-NightMode"], forAction: Action.ToggleNightMode) { userState in
            userState.nightMode = !userState.nightMode
        }

        screenState.dismissOnUse = true
        screenState.backAction = cancelBackAction
    }

    return map
}

extension Navigator where T == FxUserState {

    // Open a URL. Will use/re-use the first BrowserTab or NewTabScreen it comes to.
    @available(*, deprecated, message: "use openURL(_ urlString) instead")
    func openURL(urlString: String) {
        openURL(urlString)
    }

    func openURL(_ urlString: String, waitForLoading: Bool = true) {
        userState.url = urlString
        userState.waitForLoading = waitForLoading
        performAction(Action.LoadURL)
    }

    // Opens a URL in a new tab.
    func openNewURL(urlString: String) {
        self.goto(TabTray)
        createNewTab()
        self.openURL(urlString: urlString)
    }

    // Closes all Tabs from the option in TabTrayMenu
    func closeAllTabs() {
        let app = XCUIApplication()
        app.buttons["TabTrayController.removeTabsButton"].tap()
        app.sheets.buttons["Close All Tabs"].tap()
        self.nowAt(HomePanelsScreen)
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
        for _ in 1...numberTabs {
            self.goto(TabTray)
            self.goto(HomePanelsScreen)

        }
    }

    func browserPerformAction(_ view: BrowserPerformAction) {
        let PageMenuOptions = [.toggleBookmarkOption, .addReadingListOption, .copyURLOption, .findInPageOption, .toggleDesktopOption, .pinToTopSitesOption, .sendToDeviceOption, BrowserPerformAction.shareOption]
        let BrowserMenuOptions = [.openTopSitesOption, .openBookMarksOption, .openHistoryOption, .openReadingListOption, .toggleHideImages, .toggleNightMode, BrowserPerformAction.openSettingsOption]

        let app = XCUIApplication()

        if PageMenuOptions.contains(view) {
            self.goto(PageOptionsMenu)
            app.tables["Context Menu"].cells[view.rawValue].tap()
        } else if BrowserMenuOptions.contains(view) {
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
            for i in start ..< cells.count {
                let cell = cells.element(boundBy: i)
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
            let firstCell = self.cells.element(boundBy: cellNum)
            cellNum = firstInvisibleCell(cellNum)
            if cellNum == UInt.min {
                return
            }

            let lastCell = self.cells.element(boundBy: cellNum)
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
