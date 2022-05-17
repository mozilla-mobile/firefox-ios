// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Glean

// Telemetry for the Sponsored tiles located in the Top sites on the Firefox home page
// Using Pings to send the telemetry events
class SponsoredTileTelemetry {

    // Source is only new tab at the moment, more source could be added later
    static let source = "newtab"

    enum UserDefaultsKey: String {
        case keyContextId = "com.moz.contextId.key"
    }

    static var contextId: String? {
        get { UserDefaults.standard.object(forKey: UserDefaultsKey.keyContextId.rawValue) as? String }
        set { UserDefaults.standard.set(newValue, forKey: UserDefaultsKey.keyContextId.rawValue) }
    }

    static func clearUserDefaults() {
        SponsoredTileTelemetry.contextId = nil
    }

    static func setupContextId() {
        // Use existing client UUID, if doesn't exists create a new one
        if let stringContextId = contextId, let clientUUID = UUID(uuidString: stringContextId) {
            GleanMetrics.TopSite.contextId.set(clientUUID)
        } else {
            let newUUID = UUID()
            GleanMetrics.TopSite.contextId.set(newUUID)
            contextId = newUUID.uuidString
        }
    }

    static func sendImpressionTelemetry(tile: SponsoredTile, position: Int) {
        let extra = GleanMetrics.TopSite.ContileImpressionExtra(position: Int32(position), source: SponsoredTileTelemetry.source)
        GleanMetrics.TopSite.contileImpression.record(extra)

        GleanMetrics.TopSite.contileTileId.set(Int64(tile.tileId))
        GleanMetrics.TopSite.contileAdvertiser.set(tile.title)
        GleanMetrics.TopSite.contileReportingUrl.set(tile.impressionURL)
        GleanMetrics.Pings.shared.topsitesImpression.submit()
    }

    static func sendClickTelemetry(tile: SponsoredTile, position: Int) {
        let extra = GleanMetrics.TopSite.ContileClickExtra(position: Int32(position), source: SponsoredTileTelemetry.source)
        GleanMetrics.TopSite.contileClick.record(extra)

        GleanMetrics.TopSite.contileTileId.set(Int64(tile.tileId))
        GleanMetrics.TopSite.contileAdvertiser.set(tile.title)
        GleanMetrics.TopSite.contileReportingUrl.set(tile.clickURL)
        GleanMetrics.Pings.shared.topsitesImpression.submit()
    }
}
