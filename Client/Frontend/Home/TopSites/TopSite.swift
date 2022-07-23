// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

// Top site UI class, used in the home top site section
final class TopSite {

    var site: Site
    var title: String

    var sponsoredText: String {
        .FirefoxHomepage.Shortcuts.Sponsored
    }

    var accessibilityLabel: String? {
        isSponsoredTile ? "\(title), \(sponsoredText)" : title
    }

    var isPinned: Bool {
        (site as? PinnedSite) != nil
    }

    var isSuggested: Bool {
        (site as? SuggestedSite) != nil
    }

    var isSponsoredTile: Bool {
        (site as? SponsoredTile) != nil
    }

    var isGoogleGUID: Bool {
        site.guid == GoogleTopSiteManager.Constants.googleGUID
    }

    var isGoogleURL: Bool {
        site.url == GoogleTopSiteManager.Constants.usUrl || site.url == GoogleTopSiteManager.Constants.rowUrl
    }

    var imageLoaded: ((UIImage?) -> Void)?
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
}
