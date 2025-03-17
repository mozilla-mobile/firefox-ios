// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

// Top site UI class, used in the home top site section
struct TopSite: FeatureFlaggable {
    let site: Site
    let title: String

    private var isSuggested: Bool {
        site.isSuggestedSite
    }

    private var pinnedTitle: String {
        .localizedStringWithFormat(
            .FirefoxHomepage.Shortcuts.PinnedAccessibilityLabel,
            title
        )
    }

    private var pinnedStatusTitle: String {
        isPinned ? pinnedTitle : title
    }

    var isGooglePinnedTile: Bool {
        guard case SiteType.pinnedSite(let siteInfo) = site.type else { return false }
        return siteInfo.isGooglePinnedTile
    }

    var sponsoredText: String {
        .FirefoxHomepage.Shortcuts.Sponsored
    }

    var accessibilityLabel: String? {
        isSponsored ? "\(pinnedStatusTitle), \(sponsoredText)" : pinnedStatusTitle
    }

    var isPinned: Bool {
        site.isPinnedSite
    }

    var isSponsored: Bool {
        site.isSponsoredSite
    }

    var type: SiteType {
        site.type
    }

    var isGoogleURL: Bool {
        site.url == GoogleTopSiteManager.Constants.usUrl || site.url == GoogleTopSiteManager.Constants.rowUrl
    }

    var identifier = UUID().uuidString

    init(site: Site) {
        self.site = site
        if let provider = site.metadata?.providerName {
            title = provider.lowercased().capitalized
        } else {
            title = site.title
        }
    }

    // MARK: Telemetry
    func getTelemetrySiteType() -> String {
        if isGooglePinnedTile {
            return "google"
        } else if isPinned {
            return "user-added"
        } else if isSuggested {
            return "suggested"
        } else if isSponsored {
            return "sponsored"
        }

        return "history-based"
    }
}
