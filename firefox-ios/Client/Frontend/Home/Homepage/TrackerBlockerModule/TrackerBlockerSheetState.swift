// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
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
/// `TrackerBlockerSheetStateProvider` builds whichever of the three the persisted stats call for.
struct TrackerBlockerSheetState {
    /// Which of the three visual states described above the sheet is in.
    enum Presentation {
        case empty
        case weeklyReset
        case filled
    }

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

            var localizedTitle: String {
                switch self {
                case .crossSiteTrackingCookies: return .PrivacyDashboard.CrossSiteTrackers
                case .fingerprinters: return .PrivacyDashboard.Fingerprinters
                case .trackingContent: return .PrivacyDashboard.TrackingContent
                case .socialMediaTrackers: return .PrivacyDashboard.SocialTrackers
                }
            }
        }

        let kind: Kind
        let title: String
        /// The blocked count for this category. `nil` hides both the count and the progress bar (empty state).
        let count: Int?

        init(kind: Kind, count: Int?, title: String? = nil) {
            self.kind = kind
            self.title = title ?? kind.localizedTitle
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
        var text: String {
            String(format: .PrivacyDashboard.TotalTrackersBlockedSince, countText, sinceDate)
        }
    }

    /// Trackers blocked this week. `nil` puts the sheet in its empty state.
    let weeklyCount: Int?
    /// Message shown instead of the weekly count when the sheet is empty.
    let emptyMessage: String?
    let categories: [Category]
    /// Lifetime total shown in the footer pill. `nil` hides the footer (empty state).
    let total: Total?
    /// Every tracker blocked so far, including this week. Unlike `total` this isn't tied to the footer, which
    /// needs a start date to count from, so it is available whatever the sheet shows.
    let lifetimeTotal: Int

    init(weeklyCount: Int?,
         emptyMessage: String?,
         categories: [Category],
         total: Total?,
         lifetimeTotal: Int = 0) {
        self.weeklyCount = weeklyCount
        self.emptyMessage = emptyMessage
        self.categories = categories
        self.total = total
        self.lifetimeTotal = lifetimeTotal
    }

    var presentation: Presentation {
        guard let weeklyCount else { return .empty }
        return weeklyCount == 0 ? .weeklyReset : .filled
    }

    var isEmpty: Bool { presentation == .empty }

    /// The share of this week's blocked trackers that belongs to `category`, in `0...1`, used to size its
    /// progress bar. Returns `0` when nothing was blocked this week or when the category has no count.
    func fillRatio(for category: Category) -> CGFloat {
        guard let weeklyCount, weeklyCount > 0, let count = category.count, count > 0 else { return 0 }
        return min(1, CGFloat(count) / CGFloat(weeklyCount))
    }
}

extension TrackerBlockerSheetState {
    /// What the sheet shows before anything has ever been blocked: every category listed, no counts.
    static var empty: TrackerBlockerSheetState {
        TrackerBlockerSheetState(
            weeklyCount: nil,
            emptyMessage: String(format: .PrivacyDashboard.HeaderLabelForNoTrackersBlocked,
                                 AppName.shortName.rawValue),
            categories: Category.Kind.allCases.map { Category(kind: $0, count: nil) },
            total: nil
        )
    }
}
