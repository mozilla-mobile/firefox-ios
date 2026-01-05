// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

/// Middleware to handle generic homepage related actions
/// If this gets too big, can split out notifications and feature flags
@MainActor
final class HomepageMiddleware: FeatureFlaggable, Notifiable {
    private let profile: Profile
    private let homepageTelemetry: HomepageTelemetry
    private let privacyNoticeHelper: PrivacyNoticeHelperProtocol
    private let notificationCenter: NotificationProtocol
    private let windowManager: WindowManager

    init(profile: Profile = AppContainer.shared.resolve(),
         homepageTelemetry: HomepageTelemetry = HomepageTelemetry(),
         privacyNoticeHelper: PrivacyNoticeHelperProtocol? = nil,
         notificationCenter: NotificationProtocol,
         windowManager: WindowManager = AppContainer.shared.resolve()) {
        self.profile = profile
        self.homepageTelemetry = homepageTelemetry
        self.privacyNoticeHelper = privacyNoticeHelper ?? PrivacyNoticeHelper(prefs: profile.prefs)
        self.notificationCenter = notificationCenter
        self.windowManager = windowManager
        observeNotifications()
    }

    lazy var homepageProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.viewDidAppear, GeneralBrowserActionType.didSelectedTabChangeToHomepage:
            self.homepageTelemetry.sendHomepageImpressionEvent()

        case NavigationBrowserActionType.tapOnCustomizeHomepageButton:
            self.homepageTelemetry.sendItemTappedTelemetryEvent(for: .customizeHomepage)

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
            self.dispatchSpacerConfigurationAction(action: action)

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
        store.dispatch(
            HomepageAction(
                shouldShowPrivacyNotice: privacyNoticeHelper.shouldShowPrivacyNotice(),
                windowUUID: action.windowUUID,
                actionType: HomepageMiddlewareActionType.configuredPrivacyNotice
            )
        )
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

    private func dispatchSpacerConfigurationAction(action: Action) {
        store.dispatch(
            HomepageAction(
                shouldShowSpacer: self.shouldShowSpacer(),
                windowUUID: action.windowUUID,
                actionType: HomepageMiddlewareActionType.configuredSpacer
            )
        )
    }

    private func shouldShowSearchBar(
        for device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom,
        and isLandscape: Bool = UIWindow.isLandscape
    ) -> Bool {
        let isHomepageSearchEnabled = featureFlags.isFeatureEnabled(.homepageSearchBar, checking: .buildOnly)
        let isCompact = device == .phone && !isLandscape

        guard isHomepageSearchEnabled, isCompact else {
            return false
        }
        return true
    }

    private func shouldShowSpacer(for device: UIUserInterfaceIdiom = UIDevice.current.userInterfaceIdiom) -> Bool {
        return device == .phone && isAnyStoriesRedesignEnabled
    }

    // MARK: - Notifications
    private func observeNotifications() {
        let notifications: [Notification.Name] = [
            UIApplication.didBecomeActiveNotification,
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
            self.windowManager.windows.forEach { windowUUID, _ in
                switch notificationName {
                case UIApplication.willEnterForegroundNotification:
                    let storiesAction = HomepageAction(
                        windowUUID: windowUUID,
                        actionType: HomepageMiddlewareActionType.enteredForeground
                    )
                    store.dispatch(storiesAction)

                case .PrivateDataClearedHistory,
                        .TopSitesUpdated,
                        .DefaultSearchEngineUpdated:
                    self.dispatchActionToFetchTopSites(windowUUID: windowUUID)

                case .BookmarksUpdated, .RustPlacesOpened:
                    let bookmarksAction = HomepageAction(
                        windowUUID: windowUUID,
                        actionType: HomepageMiddlewareActionType.bookmarksUpdated
                    )
                    store.dispatch(bookmarksAction)

                case .ProfileDidFinishSyncing, .FirefoxAccountChanged:
                    self.dispatchActionToFetchTopSites(windowUUID: windowUUID)
                    self.dispatchActionToFetchTabs(windowUUID: windowUUID)

                default: break
                }
            }
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
