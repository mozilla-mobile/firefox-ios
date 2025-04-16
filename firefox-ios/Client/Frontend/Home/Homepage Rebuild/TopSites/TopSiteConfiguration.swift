// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

/// Top site UI class, used in the homepage top site section
struct TopSiteConfiguration: Hashable, Equatable, CustomStringConvertible, CustomDebugStringConvertible {
    var site: Site
    var title: String

    var sponsoredText: String {
        return .FirefoxHomepage.Shortcuts.Sponsored
    }

    private var pinnedTitle: String {
        .localizedStringWithFormat(
            .FirefoxHomepage.Shortcuts.PinnedAccessibilityLabel,
            title
        )
    }

    private var pinnedStatusTitle: String {
        return isPinned ? pinnedTitle : title
    }

    var accessibilityLabel: String? {
        return isSponsored ? "\(pinnedStatusTitle), \(sponsoredText)" : pinnedStatusTitle
    }

    var isPinned: Bool {
        return site.isPinnedSite
    }

    var isSuggested: Bool {
        return site.isSuggestedSite
    }

    var isSponsored: Bool {
        return site.isSponsoredSite
    }

    var type: SiteType {
        return site.type
    }

    var isGooglePinnedTile: Bool {
        guard case SiteType.pinnedSite(let siteInfo) = site.type else {
            return false
        }

        return siteInfo.isGooglePinnedTile
    }

    var isGoogleURL: Bool {
        return site.url == GoogleTopSiteManager.Constants.usUrl || site.url == GoogleTopSiteManager.Constants.rowUrl
    }

    public var debugDescription: String {
        return "TopSiteConfiguration (\(site))"
    }

    public var description: String {
        return debugDescription
    }

    init(site: Site) {
        self.site = site
        if let provider = site.metadata?.providerName {
            title = provider.lowercased().capitalized
        } else {
            title = site.title
        }
    }

    // MARK: Telemetry

    func impressionTracking(position: Int) {
        // Only sending sponsored tile impressions for now
        guard site.isSponsoredSite else { return }

        DefaultSponsoredTileTelemetry().sendImpressionTelemetry(tileSite: site, position: position)
    }

    var getTelemetrySiteType: String {
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
