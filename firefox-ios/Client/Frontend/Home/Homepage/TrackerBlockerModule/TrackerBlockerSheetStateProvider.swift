// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

/// Builds the state the tracker blocker sheet is presented with, out of the persisted blocked-tracker stats.
///
/// The sheet is a snapshot taken when it is presented: nothing is blocked while it is on screen, since the user
/// isn't browsing, so it doesn't observe the store for changes.
protocol TrackerBlockerSheetStateProviding {
    func sheetState() -> TrackerBlockerSheetState
}

struct TrackerBlockerSheetStateProvider: TrackerBlockerSheetStateProviding {
    /// The category rows, in the order the sheet lists them, and the blocklist category each one counts.
    /// Mirrors the breakdown the enhanced tracking protection panel shows (see
    /// `BlockedTrackersTableModel.getItems()`). `cryptomining` has no row on either surface, but it still
    /// counts towards the weekly and lifetime totals.
    private static let rowCategories: [(kind: TrackerBlockerSheetState.Category.Kind, blocklist: BlocklistCategory)] = [
        (.crossSiteTrackingCookies, .advertising),
        (.fingerprinters, .fingerprinting),
        (.trackingContent, .analytics),
        (.socialMediaTrackers, .social)
    ]

    private let statsStore: TrackerBlockStatsStore
    private let dateProvider: DateProvider

    init(statsStore: TrackerBlockStatsStore, dateProvider: DateProvider = SystemDateProvider()) {
        self.statsStore = statsStore
        self.dateProvider = dateProvider
    }

    func sheetState() -> TrackerBlockerSheetState {
        let lifetimeTotal = statsStore.lifetimeTotal()
        // Nothing has ever been blocked, so there is no breakdown to show yet.
        guard lifetimeTotal > 0 else { return .empty }

        let now = dateProvider.now()
        let weeklyByCategory = statsStore.currentWeekByCategory(for: now)

        return TrackerBlockerSheetState(
            weeklyCount: statsStore.currentWeekTotal(for: now),
            emptyMessage: nil,
            categories: Self.rowCategories.map {
                TrackerBlockerSheetState.Category(kind: $0.kind, count: weeklyByCategory[$0.blocklist] ?? 0)
            },
            // The footer needs a date to count from; without one the counts are still shown on their own.
            total: statsStore.trackingStartDate().map {
                TrackerBlockerSheetState.Total(count: lifetimeTotal, sinceDate: Self.dateText(for: $0))
            },
            lifetimeTotal: lifetimeTotal
        )
    }

    private static func dateText(for date: Date) -> String {
        return date.formatted(date: .numeric, time: .omitted)
    }
}
