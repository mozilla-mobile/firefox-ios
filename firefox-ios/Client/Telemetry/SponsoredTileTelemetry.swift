// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import Storage

// Telemetry for the Sponsored tiles located in the Top sites on the Firefox home page
// Using Pings to send the telemetry events
struct SponsoredTileTelemetry {
    // Source is only new tab at the moment, more source could be added later
    static let source = "newtab"

    static func sendImpressionTelemetry(tileSite: Site, position: Int) {
        guard case let .sponsoredSite(siteInfo) = tileSite.type else { return }

        let extra = GleanMetrics.TopSites.ContileImpressionExtra(
            position: Int32(position),
            source: SponsoredTileTelemetry.source
        )
        GleanMetrics.TopSites.contileImpression.record(extra)

        GleanMetrics.TopSites.contileTileId.set(Int64(siteInfo.tileId))
        GleanMetrics.TopSites.contileAdvertiser.set(tileSite.title)
        GleanMetrics.TopSites.contileReportingUrl.set(siteInfo.impressionURL)
        GleanMetrics.Pings.shared.topsitesImpression.submit()
    }

    static func sendClickTelemetry(tileSite: Site, position: Int) {
        guard case let .sponsoredSite(siteInfo) = tileSite.type else { return }

        let extra = GleanMetrics.TopSites.ContileClickExtra(
            position: Int32(position),
            source: SponsoredTileTelemetry.source
        )
        GleanMetrics.TopSites.contileClick.record(extra)

        GleanMetrics.TopSites.contileTileId.set(Int64(siteInfo.tileId))
        GleanMetrics.TopSites.contileAdvertiser.set(tileSite.title)
        GleanMetrics.TopSites.contileReportingUrl.set(siteInfo.clickURL)
        GleanMetrics.Pings.shared.topsitesImpression.submit()
    }
}
