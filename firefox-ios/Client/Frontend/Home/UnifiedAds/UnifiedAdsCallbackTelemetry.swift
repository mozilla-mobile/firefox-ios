// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import MozillaAppServices
import Shared
import Storage

/// Send click and impression telemetry using the unified tile callbacks.
/// This both sends the telemetry to Glean and MARS API.
protocol UnifiedAdsCallbackTelemetry {
    func sendImpressionTelemetry(tileSite: Site, position: Int)
    func sendClickTelemetry(tileSite: Site, position: Int)
}

final class DefaultUnifiedAdsCallbackTelemetry: UnifiedAdsCallbackTelemetry {
    private let adsClient: MozAdsClient
    private let networking: UnifiedTileNetworking
    private let logger: Logger
    private let sponsoredTileGleanTelemetry: SponsoredTileGleanTelemetry
    private let adsClientCallbackQueue: DispatchQueueInterface

    init(
        adsClientFactory: MozAdsClientFactory = DefaultMozAdsClientFactory(),
        networking: UnifiedTileNetworking = DefaultUnifiedTileNetwork(with: NetworkUtils.defaultURLSession()),
        logger: Logger = DefaultLogger.shared,
        sponsoredTileGleanTelemetry: SponsoredTileGleanTelemetry = DefaultSponsoredTileGleanTelemetry(),
        adsClientCallbackQueue: DispatchQueueInterface = DispatchQueue(
            label: "org.mozilla.ios.unified-ads-callback-telemetry",
            qos: .utility
        )
    ) {
        self.adsClient = adsClientFactory.createClient()
        self.networking = networking
        self.logger = logger
        self.sponsoredTileGleanTelemetry = sponsoredTileGleanTelemetry
        self.adsClientCallbackQueue = adsClientCallbackQueue
    }

    /// Impression telemetry can only be sent for `Site`s with `SiteType` `.sponsoredSite`.
    func sendImpressionTelemetry(tileSite: Site, position: Int) {
        guard case let SiteType.sponsoredSite(siteInfo) = tileSite.type else {
            assertionFailure("Only .sponsoredSite telemetry is supported right now")
            return
        }

        let impressionURL = siteInfo.impressionURL
        adsClientCallbackQueue.async { [adsClient, logger] in
            do {
                try adsClient.recordImpression(impressionUrl: impressionURL, options: nil)
            } catch {
                logger.log("Ads client recordImpression failed",
                           level: .warning,
                           category: .homepage)
            }
        }
        sendGleanImpressionTelemetry(tileSite: tileSite, position: position)
    }

    /// Click telemetry can only be sent for `Site`s with `SiteType` `.sponsoredSite`.
    func sendClickTelemetry(tileSite: Site, position: Int) {
        guard case let SiteType.sponsoredSite(siteInfo) = tileSite.type else {
            assertionFailure("Only .sponsoredSite telemetry is supported right now")
            return
        }

        let clickURL = siteInfo.clickURL
        adsClientCallbackQueue.async { [adsClient, logger] in
            do {
                try adsClient.recordClick(clickUrl: clickURL, options: nil)
            } catch {
                logger.log("Ads client recordClick failed",
                           level: .warning,
                           category: .homepage)
            }
        }
        sendGleanClickTelemetry(tileSite: tileSite, position: position)
    }

    // MARK: Glean telemetry

    private func sendGleanImpressionTelemetry(tileSite: Site, position: Int) {
        sponsoredTileGleanTelemetry.sendImpressionTelemetry(
            tileSite: tileSite,
            position: position
        )
    }

    private func sendGleanClickTelemetry(tileSite: Site, position: Int) {
        sponsoredTileGleanTelemetry.sendClickTelemetry(
            tileSite: tileSite,
            position: position
        )
    }
}
