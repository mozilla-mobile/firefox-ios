// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

/// Middleware to handle generic homepage related actions, if this gets too big, can split out notifications
final class HomepageMiddleware {
    private let homepageTelemetry: HomepageTelemetry
    private let notificationCenter: NotificationProtocol
    private let windowManager: WindowManager

    init(homepageTelemetry: HomepageTelemetry = HomepageTelemetry(),
         notificationCenter: NotificationProtocol,
         windowManager: WindowManager = AppContainer.shared.resolve()) {
        self.homepageTelemetry = homepageTelemetry
        self.notificationCenter = notificationCenter
        self.windowManager = windowManager
        observeNotifications()
    }

    lazy var homepageProvider: Middleware<AppState> = { state, action in
        switch action.actionType {
        case HomepageActionType.viewWillAppear, GeneralBrowserActionType.didSelectedTabChangeToHomepage:
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
            guard let extras = (action as? HomepageAction)?.telemetryExtras, let type = extras.itemType else {
                return
            }
            self.homepageTelemetry.sendItemTappedTelemetryEvent(for: type)

        case HomepageActionType.sectionSeen:
            guard let extras = (action as? HomepageAction)?.telemetryExtras, let type = extras.itemType else {
                return
            }
            self.homepageTelemetry.sendSectionLabeledCounter(for: type)

        default:
            break
        }
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

        notifications.forEach {
            notificationCenter.addObserver(
                self,
                selector: #selector(handleNotifications),
                name: $0,
                object: nil
            )
        }
    }

    @objc
    private func handleNotifications(_ notification: Notification) {
        // This update occurs for all windows and we need to pass along
        // the windowUUID to any subsequent actions or state changes.
        // Time complexity: O(n), where n is the number of windows in windowManager.windows
        // In the case of the phone layout, there should only be one window so n = 1

        // TODO: FXIOS-12199 Update to improve how we handle notifications for multi-window
        windowManager.windows.forEach { windowUUID, _ in
            switch notification.name {
            case UIApplication.willEnterForegroundNotification:
                let storiesAction = HomepageAction(
                    windowUUID: windowUUID,
                    actionType: HomepageMiddlewareActionType.enteredForeground
                )
                store.dispatchLegacy(storiesAction)

            case .PrivateDataClearedHistory,
                    .TopSitesUpdated,
                    .DefaultSearchEngineUpdated:
                dispatchActionToFetchTopSites(windowUUID: windowUUID)

            case .BookmarksUpdated, .RustPlacesOpened:
                let bookmarksAction = HomepageAction(
                    windowUUID: windowUUID,
                    actionType: HomepageMiddlewareActionType.bookmarksUpdated
                )
                store.dispatchLegacy(bookmarksAction)

            case .ProfileDidFinishSyncing, .FirefoxAccountChanged:
                dispatchActionToFetchTopSites(windowUUID: windowUUID)
                dispatchActionToFetchTabs(windowUUID: windowUUID)

            default: break
            }
        }
    }

    private func dispatchActionToFetchTopSites(windowUUID: WindowUUID) {
        store.dispatchLegacy(
            HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageMiddlewareActionType.topSitesUpdated
            )
        )
    }

    private func dispatchActionToFetchTabs(windowUUID: WindowUUID) {
        store.dispatchLegacy(
            HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageMiddlewareActionType.jumpBackInLocalTabsUpdated
            )
        )
        store.dispatchLegacy(
            HomepageAction(
                windowUUID: windowUUID,
                actionType: HomepageMiddlewareActionType.jumpBackInRemoteTabsUpdated
            )
        )
    }
}
