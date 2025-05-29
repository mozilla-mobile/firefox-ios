// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import Shared

final class StartAtHomeAction: Action {
    let shouldStartAtHome: Bool?
    init(
        shouldStartAtHome: Bool? = nil,
        windowUUID: WindowUUID,
        actionType: any ActionType
    ) {
        self.shouldStartAtHome = shouldStartAtHome
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum StartAtHomeActionType: ActionType {
    case didBrowserBecomeActive
}

enum StartAtHomeMiddlewareActionType: ActionType {
    case startAtHomeConfigured
}

final class StartAtHomeMiddleware {
    private let windowManager: WindowManager
    private let logger: Logger
    private let prefs: Prefs

    init(profile: Profile = AppContainer.shared.resolve(),
         windowManager: WindowManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.windowManager = windowManager
        self.logger = logger
        self.prefs = profile.prefs
    }

    lazy var startAtHomeProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case StartAtHomeActionType.didBrowserBecomeActive:
            let shouldStartAtHome = self.startAtHomeCheck(windowUUID: action.windowUUID)
            store.dispatch(
                StartAtHomeAction(
                    shouldStartAtHome: shouldStartAtHome,
                    windowUUID: action.windowUUID,
                    actionType: StartAtHomeMiddlewareActionType.startAtHomeConfigured
                )
            )
        default: break
        }
    }

    private func tabManager(for uuid: WindowUUID) -> TabManager {
        guard uuid != .unavailable else {
            assertionFailure()
            logger.log("Unexpected or unavailable window UUID for requested TabManager.", level: .fatal, category: .tabs)
            return windowManager.allWindowTabManagers().first!
        }

        return windowManager.tabManager(for: uuid)
    }

    /// Checks whether the app should start at the homepage and initiates the process if applicable.
    ///
    /// This method uses `StartAtHomeHelper` to determine if the app should launch with a homepage tab,
    /// based on user preferences and session state. If the conditions are met:
    /// - It identifies if the previous session was private.
    /// - Scans the appropriate tab set (private or normal) for an existing home tab.
    /// - Creates or reuses a homepage tab.
    /// - Selects the homepage tab for display.
    ///
    /// Logging is performed for debug purposes throughout the decision flow.
    ///
    /// - Returns: `true` if a homepage tab was selected and displayed, `false` otherwise.
    private func startAtHomeCheck(windowUUID: WindowUUID) -> Bool {
        let tabManager = tabManager(for: windowUUID)
        let startAtHomeManager = StartAtHomeHelper(
            prefs: prefs,
            isRestoringTabs: !tabManager.tabRestoreHasFinished
        )

        guard !startAtHomeManager.shouldSkipStartHome else {
            logger.log("Skipping start at home", level: .debug, category: .tabs)
            return false
        }

        if startAtHomeManager.shouldStartAtHome() {
            let wasLastSessionPrivate = tabManager.selectedTab?.isPrivate ?? false
            let scannableTabs = wasLastSessionPrivate ? tabManager.privateTabs : tabManager.normalTabs
            let existingHomeTab = startAtHomeManager.scanForExistingHomeTab(in: scannableTabs,
                                                                            with: prefs)
            let tabToSelect = createStartAtHomeTab(tabManager: tabManager,
                                                   withExistingTab: existingHomeTab,
                                                   inPrivateMode: wasLastSessionPrivate,
                                                   and: prefs)

            logger.log("Start at home triggered with last session private \(wasLastSessionPrivate)",
                       level: .debug,
                       category: .tabs)
            tabManager.selectTab(tabToSelect)
            return true
        }
        return false
    }

    /// Creates or reuses a tab to open at the configured "Start at Home" page.
    ///
    /// This function determines the appropriate page to load based on user preferences and whether
    /// a suitable tab already exists. It supports loading a custom homepage, the default top sites page,
    /// or falling back to the selected tab or a new one if necessary.
    ///
    /// - Parameters:
    ///   - existingTab: An optional existing tab that may be reused.
    ///   - privateMode: A Boolean indicating whether the tab should be opened in private mode.
    ///   - profilePreferences: The user's profile preferences.
    /// - Returns: A tab configured to show the appropriate home page content.
    private func createStartAtHomeTab(tabManager: TabManager,
                                      withExistingTab existingTab: Tab?,
                                      inPrivateMode privateMode: Bool,
                                      and profilePreferences: Prefs
    ) -> Tab? {
        let newTabPage = NewTabAccessors.getHomePage(profilePreferences)
        let customHomepageUrl = HomeButtonHomePageAccessors.getHomePage(profilePreferences)
        let homeUrl = URL(string: "internal://local/about/home")

        if newTabPage == .homePage, let customHomepageUrl {
            return existingTab ?? tabManager.addTab(URLRequest(url: customHomepageUrl), isPrivate: privateMode)
        } else if newTabPage == .topSites, let homeUrl {
            let home = existingTab ?? tabManager.addTab(isPrivate: privateMode)
            home.loadRequest(PrivilegedRequest(url: homeUrl) as URLRequest)
            home.url = homeUrl
            return home
        }

        return tabManager.selectedTab ?? tabManager.addTab()
    }
}
