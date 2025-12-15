// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean
import Storage

/// Telemetry for the Sponsored tiles located in the Top sites on the Firefox home page.
/// Using Pings to send the telemetry events. This is sent alongside the Unified Ads MARS API telemetry.
protocol SponsoredTileGleanTelemetry {
    func sendImpressionTelemetry(tileSite: Site,
                                 position: Int,
                                 isUnifiedAdsEnabled: Bool)
    func sendClickTelemetry(tileSite: Site,
                            position: Int,
                            isUnifiedAdsEnabled: Bool)
}

extension SponsoredTileGleanTelemetry {
    func sendImpressionTelemetry(tileSite: Site,
                                 position: Int,
                                 isUnifiedAdsEnabled: Bool = false) {
        sendImpressionTelemetry(tileSite: tileSite, position: position, isUnifiedAdsEnabled: isUnifiedAdsEnabled)
    }

    func sendClickTelemetry(tileSite: Site,
                            position: Int,
                            isUnifiedAdsEnabled: Bool = false) {
        sendClickTelemetry(tileSite: tileSite, position: position, isUnifiedAdsEnabled: isUnifiedAdsEnabled)
    }
}

struct DefaultSponsoredTileGleanTelemetry: SponsoredTileGleanTelemetry {
    // Source is only new tab at the moment, more source could be added later
    static let source = "newtab"
    private let gleanWrapper: GleanWrapper

    init(gleanWrapper: GleanWrapper = DefaultGleanWrapper()) {
        self.gleanWrapper = gleanWrapper
    }

    /// Send Sponsored tile impression telemetry with Glean Pings
    /// - Parameters:
    ///   - tile: The sponsored tile Site.
    ///   - position: The position of the sponsored tile in the top sites collection view
    ///   - isUnifiedAdsEnabled: Whether the unified ads is enabled, if enabled some information isn't set on the ping
    func sendImpressionTelemetry(tileSite: Site,
                                 position: Int,
                                 isUnifiedAdsEnabled: Bool = false) {
        guard case let .sponsoredSite(siteInfo) = tileSite.type else {
            assertionFailure("Only .sponsoredSite telemetry is supported right now")
            return
        }

        let extra = GleanMetrics.TopSites.ContileImpressionExtra(
            position: Int32(position),
            source: DefaultSponsoredTileGleanTelemetry.source
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TopSites.contileImpression, extras: extra)

        // Some information isn't set on the ping when unified ads is enabled
        if !isUnifiedAdsEnabled {
            gleanWrapper.recordQuantity(for: GleanMetrics.TopSites.contileTileId,
                                        value: Int64(siteInfo.tileId))
            if let impressionURL = URL(string: siteInfo.impressionURL) {
                gleanWrapper.recordUrl(for: GleanMetrics.TopSites.contileReportingUrl,
                                       value: impressionURL)
            }
        }

        gleanWrapper.recordString(for: GleanMetrics.TopSites.contileAdvertiser,
                                  value: tileSite.title)
        gleanWrapper.submit(ping: GleanMetrics.Pings.shared.topsitesImpression)
    }

    /// Send Sponsored tile click telemetry with Glean Pings
    /// - Parameters:
    ///   - tileSite: The sponsored tile Site.
    ///   - position: The position of the sponsored tile in the top sites collection view
    ///   - isUnifiedAdsEnabled: Whether the unified ads is enabled, if enabled some information isn't set on the ping
    func sendClickTelemetry(tileSite: Site,
                            position: Int,
                            isUnifiedAdsEnabled: Bool = false) {
        guard case let .sponsoredSite(siteInfo) = tileSite.type else {
            assertionFailure("Only .sponsoredSite telemetry is supported right now")
            return
        }

        let extra = GleanMetrics.TopSites.ContileClickExtra(
            position: Int32(position),
            source: DefaultSponsoredTileGleanTelemetry.source
        )
        gleanWrapper.recordEvent(for: GleanMetrics.TopSites.contileClick, extras: extra)

        // Some information isn't set on the ping when unified ads is enabled
        if !isUnifiedAdsEnabled {
            gleanWrapper.recordQuantity(for: GleanMetrics.TopSites.contileTileId,
                                        value: Int64(siteInfo.tileId))
            if let clickURL = URL(string: siteInfo.clickURL) {
                gleanWrapper.recordUrl(for: GleanMetrics.TopSites.contileReportingUrl,
                                       value: clickURL)
            }
        }

        gleanWrapper.recordString(for: GleanMetrics.TopSites.contileAdvertiser,
                                  value: tileSite.title)
        gleanWrapper.submit(ping: GleanMetrics.Pings.shared.topsitesImpression)
    }
}
