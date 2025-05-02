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

    init(homepageTelemetry: HomepageTelemetry = HomepageTelemetry(),
         notificationCenter: NotificationProtocol) {
        self.homepageTelemetry = homepageTelemetry
        self.notificationCenter = notificationCenter
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
        // This update occurs independently of any specific window, so for now we send `.unavailable`
        // as the window UUID. Reducers responding to these types of messages need to use care not to
        // propagate that UUID in any subsequent actions or state changes.
        switch notification.name {
        case UIApplication.willEnterForegroundNotification:
            let storiesAction = HomepageAction(
                windowUUID: .unavailable,
                actionType: HomepageMiddlewareActionType.enteredForeground
            )
            store.dispatch(storiesAction)

        case .PrivateDataClearedHistory,
                .TopSitesUpdated,
                .DefaultSearchEngineUpdated:
            dispatchActionToFetchTopSites()

        case .BookmarksUpdated, .RustPlacesOpened:
            let bookmarksAction = HomepageAction(
                windowUUID: .unavailable,
                actionType: HomepageMiddlewareActionType.bookmarksUpdated
            )
            store.dispatch(bookmarksAction)

        case .ProfileDidFinishSyncing, .FirefoxAccountChanged:
            dispatchActionToFetchTopSites()
            dispatchActionToFetchTabs()

        default: break
        }
    }

    private func dispatchActionToFetchTopSites() {
        store.dispatch(
            HomepageAction(
                windowUUID: .unavailable,
                actionType: HomepageMiddlewareActionType.topSitesUpdated
            )
        )
    }

    private func dispatchActionToFetchTabs() {
        store.dispatch(
            HomepageAction(
                windowUUID: .unavailable,
                actionType: HomepageMiddlewareActionType.jumpBackInLocalTabsUpdated
            )
        )
        store.dispatch(
            HomepageAction(
                windowUUID: .unavailable,
                actionType: HomepageMiddlewareActionType.jumpBackInRemoteTabsUpdated
            )
        )
    }
}
