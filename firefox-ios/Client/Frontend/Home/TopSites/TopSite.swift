// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

// Top site UI class, used in the home top site section
final class TopSite: FeatureFlaggable {
    let site: Site
    let title: String

    var sponsoredText: String {
        return .FirefoxHomepage.Shortcuts.Sponsored
    }

    var accessibilityLabel: String? {
        return isSponsoredTile ? "\(title), \(sponsoredText)" : title
    }

    var isPinned: Bool {
        return site.type.isPinnedSite
    }

    var isSuggested: Bool {
        return site.type.isSuggestedSite
    }

    var isSponsoredTile: Bool { // FIXME naming
        return site.type.isSponsoredSite
    }

    var isGooglePinnedTile: Bool {
        guard case SiteType.pinnedSite(let siteInfo) = site.type else { return false }

        return siteInfo.isGooglePinnedTile
    }

    var isGoogleURL: Bool {
        return site.url == GoogleTopSiteManager.Constants.usUrl || site.url == GoogleTopSiteManager.Constants.rowUrl
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

    func impressionTracking(position: Int, unifiedAdsTelemetry: UnifiedAdsCallbackTelemetry) {
        // Only sending sponsored tile impressions for now
        guard site.type.isSponsoredSite else { return }

        if featureFlags.isFeatureEnabled(.unifiedAds, checking: .buildOnly) {
            unifiedAdsTelemetry.sendImpressionTelemetry(tileSite: site, position: position)
        } else {
            SponsoredTileTelemetry.sendImpressionTelemetry(tileSite: site, position: position)
        }
    }

    func getTelemetrySiteType() -> String {
        if isPinned && isGooglePinnedTile {
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
}
