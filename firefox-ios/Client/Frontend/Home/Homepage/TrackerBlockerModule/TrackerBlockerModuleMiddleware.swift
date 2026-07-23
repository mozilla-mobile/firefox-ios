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
    private static let minReportableFigures = 4
    private static let maxReportableFigures = 8

    private let statsStore: TrackerBlockStatsStore
    private let telemetry: TrackerBlockerTelemetry

    init(
        statsStore: TrackerBlockStatsStore? = nil,
        telemetry: TrackerBlockerTelemetry = TrackerBlockerTelemetry()
    ) {
        if let statsStore {
            self.statsStore = statsStore
        } else {
            let prefs = (AppContainer.shared.resolve() as Profile).prefs
            self.statsStore = DefaultTrackerBlockStatsStoreUtility(prefs: prefs)
        }
        self.telemetry = telemetry
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
        let count = statsStore.lifetimeTotal()
        recordThresholdCrossings(for: count)
        store.dispatch(
            TrackerBlockerModuleAction(
                blockedTrackerCount: count,
                windowUUID: windowUUID,
                actionType: TrackerBlockerModuleMiddlewareActionType.updateBlockedCount
            )
        )
    }

    /// Fires a telemetry event for each digit-count boundary (4...8 figures) the
    /// lifetime total has newly crossed, then persists the high-water mark so no
    /// boundary is reported more than once.
    private func recordThresholdCrossings(for count: Int) {
        guard count > 0 else { return }
        let figures = String(count).count
        guard figures >= Self.minReportableFigures else { return }

        let cappedFigures = min(figures, Self.maxReportableFigures)
        let alreadyReported = statsStore.highestReportedFigures()
        guard cappedFigures > alreadyReported else { return }

        let firstToReport = max(Self.minReportableFigures, alreadyReported + 1)
        for boundary in firstToReport...cappedFigures {
            telemetry.lifetimeThresholdReached(figures: boundary)
        }
        statsStore.setHighestReportedFigures(cappedFigures)
    }
}
