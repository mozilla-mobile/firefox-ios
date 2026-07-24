// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Blocked-tracker counts for the in-progress ISO-8601 week, keyed by category.
/// `year` is the ISO year-for-week-of-year (which can differ from the calendar
/// year around January), and `week` is the ISO week-of-year (1...53). Once the
/// week rolls over, its counts are folded into `TrackerBlockStatsRunningTotal`.
struct TrackerBlockStatsBucket: Codable, Equatable {
    let year: Int
    let week: Int
    /// Category storage key (`BlocklistCategory.storageKey`) to blocked count.
    var counts: [String: Int]

    var total: Int {
        return counts.values.reduce(0, +)
    }
}

/// The lifetime running total of completed weeks, keyed by category. Holds no
/// per-week identity: each completed week is added into these counts on rollover
/// so lifetime figures stay a fixed-size value regardless of how long tracking
/// has run. Lifetime totals add the in-progress week on top of this.
struct TrackerBlockStatsRunningTotal: Codable, Equatable {
    /// Category storage key (`BlocklistCategory.storageKey`) to blocked count.
    var counts: [String: Int]

    var total: Int {
        return counts.values.reduce(0, +)
    }

    init(counts: [String: Int] = [:]) {
        self.counts = counts
    }
}
