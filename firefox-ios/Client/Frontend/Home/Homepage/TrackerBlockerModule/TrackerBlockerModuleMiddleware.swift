// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

/// Feeds the homepage tracker-blocker module its lifetime blocked-tracker count
/// from the persisted `TrackerBlockStatsStore`. The count is recomputed whenever
/// the homepage is shown or the app returns to the foreground, since blocking
/// happens off the homepage while the user browses.
@MainActor
final class TrackerBlockerModuleMiddleware {
    private let statsStore: TrackerBlockStatsStore

    init(statsStore: TrackerBlockStatsStore? = nil) {
        if let statsStore {
            self.statsStore = statsStore
        } else {
            let prefs = (AppContainer.shared.resolve() as Profile).prefs
            self.statsStore = DefaultTrackerBlockStatsStoreUtility(prefs: prefs)
        }
    }

    lazy var trackerBlockerModuleProvider: Middleware<AppState> = (legacyProvider, modernProvider)

    lazy var modernProvider: MiddlewareClosure<AppState> = { [self] state, action, windowUUID in
        // No modern actions handled yet; the homepage lifecycle actions this
        // module reacts to are still legacy actions (see legacyProvider).
    }

    lazy var legacyProvider: LegacyMiddlewareClosure<AppState> = { [self] state, action in
        switch action.actionType {
        case HomepageActionType.initialize,
             HomepageActionType.viewDidAppear,
             HomepageMiddlewareActionType.didBecomeActive:
            self.dispatchBlockedCount(windowUUID: action.windowUUID)
        default:
            break
        }
    }

    private func dispatchBlockedCount(windowUUID: WindowUUID) {
        store.dispatch(
            TrackerBlockerModuleAction(
                blockedTrackerCount: statsStore.lifetimeTotal(),
                windowUUID: windowUUID,
                actionType: TrackerBlockerModuleMiddlewareActionType.updateBlockedCount
            )
        )
    }
}
