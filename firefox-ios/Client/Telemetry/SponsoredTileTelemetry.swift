// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

// Telemetry for the Sponsored tiles located in the Top sites on the Firefox home page
// Using Pings to send the telemetry events
struct SponsoredTileTelemetry {
    // Source is only new tab at the moment, more source could be added later
    static let source = "newtab"

    /// Send Sponsored tile impression telemetry with Glean Pings
    /// - Parameters:
    ///   - tile: The sponsored tile
    ///   - position: The position of the sponsored tile in the top sites collection view
    ///   - isUnifiedAdsEnabled: Whether the unified ads is enabled, if enabled some information isn't set on the ping
    static func sendImpressionTelemetry(tile: SponsoredTile,
                                        position: Int,
                                        isUnifiedAdsEnabled: Bool = false) {
        let extra = GleanMetrics.TopSites.ContileImpressionExtra(
            position: Int32(position),
            source: SponsoredTileTelemetry.source
        )
        GleanMetrics.TopSites.contileImpression.record(extra)

        // Some information isn't set on the ping when unified ads is enabled
        if !isUnifiedAdsEnabled {
            GleanMetrics.TopSites.contileTileId.set(Int64(tile.tileId))
            GleanMetrics.TopSites.contileReportingUrl.set(tile.impressionURL)
        }

        GleanMetrics.TopSites.contileAdvertiser.set(tile.title)
        GleanMetrics.Pings.shared.topsitesImpression.submit()
    }

    /// Send Sponsored tile click telemetry with Glean Pings
    /// - Parameters:
    ///   - tile: The sponsored tile
    ///   - position: The position of the sponsored tile in the top sites collection view
    ///   - isUnifiedAdsEnabled: Whether the unified ads is enabled, if enabled some information isn't set on the ping
    static func sendClickTelemetry(tile: SponsoredTile,
                                   position: Int,
                                   isUnifiedAdsEnabled: Bool = false) {
        let extra = GleanMetrics.TopSites.ContileClickExtra(
            position: Int32(position),
            source: SponsoredTileTelemetry.source
        )
        GleanMetrics.TopSites.contileClick.record(extra)

        // Some information isn't set on the ping when unified ads is enabled
        if !isUnifiedAdsEnabled {
            GleanMetrics.TopSites.contileTileId.set(Int64(tile.tileId))
            GleanMetrics.TopSites.contileReportingUrl.set(tile.clickURL)
        }

        GleanMetrics.TopSites.contileAdvertiser.set(tile.title)
        GleanMetrics.Pings.shared.topsitesImpression.submit()
    }
}
