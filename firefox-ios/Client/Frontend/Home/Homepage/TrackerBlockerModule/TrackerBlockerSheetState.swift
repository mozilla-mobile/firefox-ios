// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
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
/// Nothing populates the filled states yet: `empty` is the only one the app constructs, and it is what the sheet
/// is presented with until the blocked-tracker data is wired up separately. The populated states are exercised
/// from sample data in `TrackerBlockerSheetViewControllerTests`.
struct TrackerBlockerSheetState {
    /// A single tracker category row.
    struct Category {
        /// The tracker categories the weekly count is broken down by. These mirror the ones the enhanced
        /// tracking protection panel reports, so both surfaces show the same icon for the same category
        /// (see `BlockedTrackersTableModel.getItems()`).
        enum Kind: CaseIterable {
            case crossSiteTrackingCookies
            case fingerprinters
            case trackingContent
            case socialMediaTrackers

            var imageName: String {
                switch self {
                case .crossSiteTrackingCookies: return StandardImageIdentifiers.Large.cookies
                case .fingerprinters: return StandardImageIdentifiers.Large.fingerprinter
                case .trackingContent: return StandardImageIdentifiers.Large.image
                case .socialMediaTrackers: return StandardImageIdentifiers.Large.socialMedia
                }
            }

            // TODO: FXIOS-16429 - Replace with localized strings once available.
            var placeholderTitle: String {
                switch self {
                case .crossSiteTrackingCookies: return "Cross-Site Tracking Cookies"
                case .fingerprinters: return "Fingerprinters"
                case .trackingContent: return "Tracking Content"
                case .socialMediaTrackers: return "Social Media Trackers"
                }
            }
        }

        let kind: Kind
        let title: String
        /// The blocked count for this category. `nil` hides both the count and the progress bar (empty state).
        let count: Int?

        init(kind: Kind, count: Int?, title: String? = nil) {
            self.kind = kind
            self.title = title ?? kind.placeholderTitle
            self.count = count
        }
    }

    /// The lifetime total shown in the footer pill. The count is kept separate from the surrounding copy so the
    /// footer can render it in bold.
    struct Total {
        let count: Int
        /// The formatted date the count is measured from.
        let sinceDate: String

        var countText: String { count.formatted(.number) }
        // TODO: FXIOS-16429 - Replace with a localized format string once available.
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

extension TrackerBlockerSheetState {
    // TODO: FXIOS-16429 - Replace the message with a localized string once available.
    /// What the sheet shows until it is handed real blocked-tracker data: every category listed, no counts.
    static var empty: TrackerBlockerSheetState {
        TrackerBlockerSheetState(
            weeklyCount: nil,
            emptyMessage: "Firefox blocks trackers as you browse, you'll see them here.",
            categories: Category.Kind.allCases.map { Category(kind: $0, count: nil) },
            total: nil
        )
    }
}
