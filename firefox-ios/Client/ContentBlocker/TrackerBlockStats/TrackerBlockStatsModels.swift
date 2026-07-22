// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Blocked-tracker counts for a single ISO-8601 week, keyed by category.
/// `year` is the ISO year-for-week-of-year (which can differ from the calendar
/// year around January), and `week` is the ISO week-of-year (1...53).
struct TrackerBlockStatsBucket: Codable, Equatable {
    let year: Int
    let week: Int
    /// Category storage key (`BlocklistCategory.storageKey`) to blocked count.
    var counts: [String: Int]

    var total: Int {
        return counts.values.reduce(0, +)
    }
}

/// The full persisted stats payload: an append-only list of weekly buckets.
/// Lifetime figures are derived by summing across all buckets, so there is no
/// separate running total to keep in sync.
struct TrackerBlockStatsData: Codable, Equatable {
    var buckets: [TrackerBlockStatsBucket]

    init(buckets: [TrackerBlockStatsBucket] = []) {
        self.buckets = buckets
    }
}
