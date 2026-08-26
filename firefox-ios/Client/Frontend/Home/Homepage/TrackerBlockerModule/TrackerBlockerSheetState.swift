// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// The content shown by `TrackerBlockerSheetViewController`.
///
/// The sheet has three visual states, all represented by this type:
/// - **Empty** – nothing has ever been blocked. `weeklyCount` and `total` are `nil`; the descriptive
///   `emptyMessage` is shown in place of the weekly count and the category rows show titles only.
/// - **Filled** – trackers were blocked this week. `weeklyCount` is a positive number and every category has a count.
/// - **Weekly reset** – the same as filled but with `weeklyCount == 0` and empty category bars, while the lifetime
///   `total` still exists.
///
/// Note: this is placeholder/dummy data. Real values are wired up separately.
struct TrackerBlockerSheetState {
    /// A single tracker category row.
    struct Category {
        let title: String
        /// The blocked count for this category. `nil` hides both the count and the progress bar (empty state).
        let count: Int?
    }

    /// The lifetime total shown in the footer pill. The count is kept separate from the surrounding copy so the
    /// footer can render it in bold.
    struct Total {
        let count: Int
        /// The formatted date the count is measured from.
        let sinceDate: String

        var countText: String { count.formatted(.number) }
        // TODO: FXIOS-XXXXX - Replace with a localized format string once available.
        var text: String { "\(countText) since \(sinceDate) 🎉" }
    }

    /// Trackers blocked this week. `nil` puts the sheet in its empty state.
    let weeklyCount: Int?
    /// Message shown instead of the weekly count when the sheet is empty.
    let emptyMessage: String?
    let categories: [Category]
    /// Lifetime total shown in the footer pill. `nil` hides the footer (empty state).
    let total: Total?

    var isEmpty: Bool { weeklyCount == nil }

    /// The share of this week's blocked trackers that belongs to `category`, in `0...1`, used to size its
    /// progress bar. Returns `0` when nothing was blocked this week or when the category has no count.
    func fillRatio(for category: Category) -> CGFloat {
        guard let weeklyCount, weeklyCount > 0, let count = category.count, count > 0 else { return 0 }
        return min(1, CGFloat(count) / CGFloat(weeklyCount))
    }
}

// MARK: - Placeholder data
// TODO: FXIOS-XXXXX - Replace with real data + localized strings once available.
extension TrackerBlockerSheetState {
    private static let placeholderCategoryTitles = [
        "Cross-Site Tracking Cookies",
        "Fingerprinters",
        "Tracking Content",
        "Social Media Trackers"
    ]

    static var dummyEmpty: TrackerBlockerSheetState {
        TrackerBlockerSheetState(
            weeklyCount: nil,
            emptyMessage: "Firefox blocks trackers as you browse, you'll see them here.",
            categories: placeholderCategoryTitles.map { Category(title: $0, count: nil) },
            total: nil
        )
    }

    static var dummyFilled: TrackerBlockerSheetState {
        TrackerBlockerSheetState(
            weeklyCount: 306,
            emptyMessage: nil,
            categories: [
                Category(title: placeholderCategoryTitles[0], count: 120),
                Category(title: placeholderCategoryTitles[1], count: 87),
                Category(title: placeholderCategoryTitles[2], count: 99),
                Category(title: placeholderCategoryTitles[3], count: 0)
            ],
            total: Total(count: 5305, sinceDate: "02/13/26")
        )
    }

    static var dummyWeeklyReset: TrackerBlockerSheetState {
        TrackerBlockerSheetState(
            weeklyCount: 0,
            emptyMessage: nil,
            categories: placeholderCategoryTitles.map { Category(title: $0, count: 0) },
            total: Total(count: 5305, sinceDate: "02/13/26")
        )
    }
}
