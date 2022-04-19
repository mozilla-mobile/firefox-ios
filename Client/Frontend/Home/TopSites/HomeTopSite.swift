// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import Shared

// Top site UI class, used in the home top site section
final class HomeTopSite {

    var site: Site
    var title: String
    var image: UIImage?

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

    var imageLoaded: ((UIImage?) -> Void)?
    var identifier = UUID().uuidString

    init(site: Site, profile: Profile) {
        self.site = site
        if let provider = site.metadata?.providerName {
            title = provider.lowercased().capitalized
        } else {
            title = site.title
        }

        let imageHelper = SiteImageHelper(profile: profile)
        imageHelper.fetchImageFor(site: site,
                                  imageType: .favicon,
                                  shouldFallback: false) { image in
            self.image = image
            self.imageLoaded?(image)
        }
    }

    // MARK: Telemetry

    private var sentSiteImpressionTelemetry = false

    func impressionTracking() {
        guard isSponsoredTile, !sentSiteImpressionTelemetry else { return }

        TelemetryWrapper.recordEvent(category: .information,
                                     method: .view,
                                     object: .topSiteImpression,
                                     value: nil,
                                     extras: getSiteExtra())
        sentSiteImpressionTelemetry = true
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

    private func getSiteExtra() -> [String: String] {
        return [TelemetryWrapper.EventExtraKey.topSiteUrl.rawValue: "\(site.url)"]
    }
}
