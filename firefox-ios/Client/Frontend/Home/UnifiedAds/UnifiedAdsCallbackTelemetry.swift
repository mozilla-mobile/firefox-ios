// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage

/// Send click and impression telemetry using the unified tile callbacks.
/// This both sends the telemetry to Glean and MARS API.
protocol UnifiedAdsCallbackTelemetry {
    func sendImpressionTelemetry(tileSite: Site, position: Int)
    func sendClickTelemetry(tileSite: Site, position: Int)
}

final class DefaultUnifiedAdsCallbackTelemetry: UnifiedAdsCallbackTelemetry {
    private let networking: UnifiedTileNetworking
    private let logger: Logger
    private let sponsoredTileGleanTelemetry: SponsoredTileGleanTelemetry

    init(
        networking: UnifiedTileNetworking = DefaultUnifiedTileNetwork(with: NetworkUtils.defaultURLSession()),
        logger: Logger = DefaultLogger.shared,
        sponsoredTileGleanTelemetry: SponsoredTileGleanTelemetry = DefaultSponsoredTileGleanTelemetry()
    ) {
        self.networking = networking
        self.logger = logger
        self.sponsoredTileGleanTelemetry = sponsoredTileGleanTelemetry
    }

    /// Impression telemetry can only be sent for `Site`s with `SiteType` `.sponsoredSite`.
    func sendImpressionTelemetry(tileSite: Site, position: Int) {
        guard case let SiteType.sponsoredSite(siteInfo) = tileSite.type else {
            assertionFailure("Only .sponsoredSite telemetry is supported right now")
            return
        }

        sendTelemetry(urlString: siteInfo.impressionURL, position: position)
        sendGleanImpressionTelemetry(tileSite: tileSite, position: position)
    }

    /// Click telemetry can only be sent for `Site`s with `SiteType` `.sponsoredSite`.
    func sendClickTelemetry(tileSite: Site, position: Int) {
        guard case let SiteType.sponsoredSite(siteInfo) = tileSite.type else {
            assertionFailure("Only .sponsoredSite telemetry is supported right now")
            return
        }

        sendTelemetry(urlString: siteInfo.clickURL, position: position)
        sendGleanClickTelemetry(tileSite: tileSite, position: position)
    }

    private func sendTelemetry(urlString: String, position: Int) {
        guard var urlComponents = URLComponents(string: urlString) else {
            logger.log("The provided URL is invalid: \(String(describing: urlString))",
                       level: .warning,
                       category: .homepage)
            return
        }

        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: "position", value: String(position)))
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            logger.log("The provided URL components are invalid: \(String(describing: urlString))",
                       level: .warning,
                       category: .homepage)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue

        networking.data(from: request) { [logger] result in
            switch result {
            case .success:
                break // We only want to know if it failed
            case .failure:
                logger.log("The unified ads telemetry call failed: \(String(describing: urlString))",
                           level: .warning,
                           category: .homepage)
            }
        }
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
