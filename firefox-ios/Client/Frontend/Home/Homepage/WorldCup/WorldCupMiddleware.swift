// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Redux
import Shared

/// Thin Redux adapter for the WorldCup feature. The polling lifecycle,
/// `/matches` + `/live` plumbing, and view-model assembly live in
/// `WorldCupFeed`. This middleware just routes Redux actions to the feed
/// and dispatches the feed's `Snapshot` back into the store.
@MainActor
final class WorldCupMiddleware {
    private let worldCupStore: WorldCupStoreProtocol
    private let feed: WorldCupFeed?
    private var lastWindowUUID: WindowUUID?

    convenience init() {
        let store = WorldCupStore()
        let feed = WorldCupMiddleware.makeDefaultFeed(store: store)
        self.init(worldCupStore: store, feed: feed)
    }

    init(worldCupStore: WorldCupStoreProtocol, feed: WorldCupFeed?) {
        self.worldCupStore = worldCupStore
        self.feed = feed
        feed?.onUpdate = { [weak self] snapshot in
            self?.dispatch(snapshot: snapshot)
        }
    }

    lazy var worldCupProvider: Middleware<AppState> = { state, action in
        self.lastWindowUUID = action.windowUUID
        switch action.actionType {
        case HomepageActionType.initialize,
             HomepageMiddlewareActionType.enteredForeground,
             WorldCupActionType.retryMatchesFetch:
            self.startFeed(windowUUID: action.windowUUID)
        case WorldCupActionType.didChangeHomepageSettings:
            self.dispatch(snapshot: self.feed?.latestSnapshot ?? .empty)
        case WorldCupActionType.removeHomepageCard:
            self.worldCupStore.setIsHomepageSectionEnabled(false)
            self.feed?.stop()
            self.dispatch(snapshot: .empty)
        case WorldCupActionType.selectTeam:
            let countryId = (action as? WorldCupAction)?.selectedCountryId
            self.worldCupStore.setSelectedTeam(countryId: countryId)
            self.startFeed(windowUUID: action.windowUUID)
        case WorldCupActionType.worldCupDidStart:
            self.dispatch(snapshot: self.feed?.latestSnapshot ?? .empty)
        default:
            break
        }
    }

    private func startFeed(windowUUID: WindowUUID) {
        guard worldCupStore.isMilestone2, let feed else {
            dispatch(snapshot: .empty)
            return
        }
        feed.start()
    }

    private func dispatch(snapshot: WorldCupFeed.Snapshot) {
        guard let windowUUID = lastWindowUUID else { return }
        store.dispatch(
            WorldCupAction(
                windowUUID: windowUUID,
                actionType: WorldCupMiddlewareActionType.didUpdate,
                shouldShowHomepageWorldCupSection: worldCupStore.isFeatureEnabledAndSectionEnabled,
                shouldShowMilestone2: worldCupStore.isMilestone2,
                hasWorldCupStarted: worldCupStore.hasWorldCupStarted,
                selectedCountryId: worldCupStore.selectedTeam,
                matches: snapshot.matches,
                apiError: snapshot.apiError,
                defaultMatchIndex: snapshot.defaultMatchIndex
            )
        )
    }

    private static func makeDefaultFeed(store: WorldCupStoreProtocol) -> WorldCupFeed? {
        guard let apiClient = WorldCupAPIClient.makeDefault() else { return nil }
        let prefs = (AppContainer.shared.resolve() as Profile).prefs
        let usesDevServerTimeline = prefs.stringForKey(PrefsKeys.HomepageSettings.WorldCupBaseHost) != nil
        return WorldCupFeed(
            apiClient: apiClient,
            usesDevServerTimeline: usesDevServerTimeline,
            selectedTeamProvider: { store.selectedTeam }
        )
    }
}
