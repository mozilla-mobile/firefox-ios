// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

/// Top site UI class, used in the homepage top site section
final class TopSiteState: Hashable, Equatable {
    var site: Site
    var title: String

    var sponsoredText: String {
        return .FirefoxHomepage.Shortcuts.Sponsored
    }

    var accessibilityLabel: String? {
        return isSponsoredTile ? "\(title), \(sponsoredText)" : title
    }

    var isPinned: Bool {
        return (site as? PinnedSite) != nil
    }

    var isSuggested: Bool {
        return (site as? SuggestedSite) != nil
    }

    var isSponsoredTile: Bool {
        return (site as? SponsoredTile) != nil
    }

    var isGoogleGUID: Bool {
        return site.guid == GoogleTopSiteManager.Constants.googleGUID
    }

    var isGoogleURL: Bool {
        return site.url == GoogleTopSiteManager.Constants.usUrl || site.url == GoogleTopSiteManager.Constants.rowUrl
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
        guard let tile = site as? SponsoredTile else { return }

        SponsoredTileTelemetry.sendImpressionTelemetry(tile: tile, position: position)
    }

    func getTelemetrySiteType() -> String {
        if isPinned && isGoogleGUID {
            return "google"
        } else if isPinned {
            return "user-added"
        } else if isSuggested {
            return "suggested"
        } else if isSponsoredTile {
            return "sponsored"
        }

        return "history-based"
    }

    // MARK: - Equatable
    static func == (lhs: TopSiteState, rhs: TopSiteState) -> Bool {
        lhs.site == rhs.site &&
        lhs.isPinned == rhs.isPinned &&
        lhs.isSuggested == rhs.isSuggested &&
        lhs.isSponsoredTile == rhs.isSponsoredTile &&
        lhs.isGoogleGUID == rhs.isGoogleGUID &&
        lhs.isGoogleURL == rhs.isGoogleURL
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.site)
        hasher.combine(self.isPinned)
        hasher.combine(self.isSuggested)
        hasher.combine(self.isSponsoredTile)
        hasher.combine(self.isGoogleGUID)
        hasher.combine(self.isGoogleURL)
    }
}
