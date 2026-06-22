// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common
import Shared

/// Middleware to handle generic homepage related actions
/// If this gets too big, can split out notifications and feature flags
@MainActor
final class HomepageMiddleware: FeatureFlaggable, Notifiable {
    private let profile: Profile
    private let homepageTelemetry: HomepageTelemetry
    private let privacyNoticeHelper: PrivacyNoticeHelperProtocol
    private let notificationCenter: NotificationProtocol
    private let windowManager: WindowManager
    private let logger: Logger

    init(profile: Profile = AppContainer.shared.resolve(),
         homepageTelemetry: HomepageTelemetry = HomepageTelemetry(),
         privacyNoticeHelper: PrivacyNoticeHelperProtocol? = nil,
         notificationCenter: NotificationProtocol,
         windowManager: WindowManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.profile = profile
        self.homepageTelemetry = homepageTelemetry
        self.privacyNoticeHelper = privacyNoticeHelper ?? PrivacyNoticeHelper(prefs: profile.prefs)
        self.notificationCenter = notificationCenter
        self.windowManager = windowManager
        self.logger = logger
        observeNotifications()
    }

    lazy var homepageProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.viewDidAppear:
            self.homepageTelemetry.sendHomepageImpressionEvent()

        case NavigationBrowserActionType.tapOnBookmarksShowMoreButton:
            self.homepageTelemetry.sendItemTappedTelemetryEvent(for: .bookmarkShowAll)

        case NavigationBrowserActionType.tapOnJumpBackInShowAllButton:
            guard case let .tabTray(panelType) = (action as? NavigationBrowserAction)?
                .navigationDestination.destination
            else { return }

            self.homepageTelemetry.sendItemTappedTelemetryEvent(
                for: panelType == .syncedTabs ? .jumpBackInSyncedTabShowAll : .jumpBackInTabShowAll
            )

        case HomepageActionType.didSelectItem:
            guard let extras = (action as? HomepageAction)?.telemetryExtras,
                  let type = extras.itemType else {
                return
            }
            self.homepageTelemetry.sendItemTappedTelemetryEvent(for: type)

        case HomepageActionType.sectionSeen:
            self.handleSectionSeenAction(action: action)

        case HomepageActionType.initialize:
            self.dispatchPrivacyNoticeConfigurationAction(action: action)
            self.dispatchSearchBarConfigurationAction(action: action)

        case HomepageActionType.viewWillTransition, ToolbarActionType.cancelEdit,
            GeneralBrowserActionType.navigateBack, GeneralBrowserActionType.didCloseTabFromToolbar:
            self.dispatchSearchBarConfigurationAction(action: action)

        default:
            break
        }
    }

    private func handleSectionSeenAction(action: Action) {
        guard let extras = (action as? HomepageAction)?.telemetryExtras,
              let type = extras.itemType else {
            return
        }
        self.homepageTelemetry.sendSectionLabeledCounter(for: type)
    }

    private func dispatchPrivacyNoticeConfigurationAction(action: Action) {
        if privacyNoticeHelper.shouldShowPrivacyNotice() {
            store.dispatch(
                HomepageAction(
                    windowUUID: action.windowUUID,
                    actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
                )
            )
        }
    }

    private func dispatchSearchBarConfigurationAction(action: Action) {
        store.dispatch(
            HomepageAction(
                isSearchBarEnabled: self.shouldShowSearchBar(),
                windowUUID: action.windowUUID,
                actionType: HomepageMiddlewareActionType.configuredSearchBar
            )
        )
    }

    private func shouldShowSearchBar(
        for device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
        and isLandscape: Bool = UIWindow.isLandscape
    ) -> Bool {
        let isHomepageSearchEnabled = featureFlagsProvider.isEnabled(.homepageSearchBar)
        let isCompact = device == .phone && !isLandscape

        guard isHomepageSearchEnabled, isCompact else {
            return false
        }
        return true
    }

    // MARK: - Notifications
    private func observeNotifications() {
        let notifications: [Notification.Name] = [
            UIApplication.didBecomeActiveNotification,
            UIApplication.willResignActiveNotification,
            UIApplication.didEnterBackgroundNotification,
            .FirefoxAccountChanged,
            .PrivateDataClearedHistory,
            .ProfileDidFinishSyncing,
            .TopSitesUpdated,
            .DefaultSearchEngineUpdated,
            .BookmarksUpdated,
            .RustPlacesOpened
        ]

        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: notifications
        )
    }

    func handleNotifications(_ notification: Notification) {
        // This update occurs for all windows and we need to pass along
        // the windowUUID to any subsequent actions or state changes.
        // Time complexity: O(n), where n is the number of windows in windowManager.windows
        // In the case of the phone layout, there should only be one window so n = 1

        // TODO: FXIOS-12199 Update to improve how we handle notifications for multi-window
        let notificationName = notification.name
        ensureMainThread {
            self.logger.log(
                "\(FreezeDiag.prefix)[Homepage] notification received name=\(notificationName.rawValue) appState=\(FreezeDiag.applicationState) windows=\(self.windowManager.windows.count)",
                level: .debug,
                category: .homepage
            )
            self.windowManager.windows.forEach { windowUUID, _ in
                self.handleNotification(notificationName, for: windowUUID)
            }
        }
    }

    private func handleNotification(_ notificationName: Notification.Name, for windowUUID: WindowUUID) {
        switch notificationName {
        case UIApplication.didBecomeActiveNotification:
            logger.log(
                "\(FreezeDiag.prefix)[Homepage] dispatch didBecomeActive window=\(FreezeDiag.shortWindowID(windowUUID)) appState=\(FreezeDiag.applicationState) windows=\(windowManager.windows.count)",
                level: .info,
                category: .homepage
            )
            let storiesAction = HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageMiddlewareActionType.didBecomeActive
            )
            store.dispatch(storiesAction)

        case UIApplication.willResignActiveNotification,
             UIApplication.didEnterBackgroundNotification:
            logger.log(
                "\(FreezeDiag.prefix)[Homepage] lifecycle notification diagnosticOnly name=\(notificationName.rawValue) window=\(FreezeDiag.shortWindowID(windowUUID)) appState=\(FreezeDiag.applicationState) windows=\(windowManager.windows.count)",
                level: .info,
                category: .homepage
            )

        case .PrivateDataClearedHistory,
                .TopSitesUpdated,
                .DefaultSearchEngineUpdated:
            dispatchActionToFetchTopSites(windowUUID: windowUUID)

        case .BookmarksUpdated, .RustPlacesOpened:
            let bookmarksAction = HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageMiddlewareActionType.bookmarksUpdated
            )
            store.dispatch(bookmarksAction)

        case .ProfileDidFinishSyncing, .FirefoxAccountChanged:
            dispatchActionToFetchTopSites(windowUUID: windowUUID)
            dispatchActionToFetchTabs(windowUUID: windowUUID)

        default: break
        }
    }

    private func dispatchActionToFetchTopSites(windowUUID: WindowUUID) {
        store.dispatch(
            HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageMiddlewareActionType.topSitesUpdated
            )
        )
    }

    private func dispatchActionToFetchTabs(windowUUID: WindowUUID) {
        store.dispatch(
            HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageMiddlewareActionType.jumpBackInLocalTabsUpdated
            )
        )
        store.dispatch(
            HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageMiddlewareActionType.jumpBackInRemoteTabsUpdated
            )
        )
    }
}
