// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Send click and impression telemetry using the unified tile callbacks
protocol UnifiedAdsCallbackTelemetry {
    func sendImpressionTelemetry(tile: SponsoredTile, position: Int)
    func sendClickTelemetry(tile: SponsoredTile, position: Int)
}

final class DefaultUnifiedAdsCallbackTelemetry: UnifiedAdsCallbackTelemetry {
    private var networking: ContileNetworking
    private var logger: Logger

    init(
        networking: ContileNetworking = DefaultContileNetwork(with: NetworkUtils.defaultURLSession()),
        logger: Logger = DefaultLogger.shared
    ) {
        self.networking = networking
        self.logger = logger
    }

    func sendImpressionTelemetry(tile: SponsoredTile, position: Int) {
        let impressionURL = tile.impressionURL
        sendTelemetry(urlString: impressionURL, position: position)
        sendLegacyImpressionTelemetry(tile: tile, position: position)
    }

    func sendClickTelemetry(tile: SponsoredTile, position: Int) {
        let clickURL = tile.clickURL
        sendTelemetry(urlString: clickURL, position: position)
        sendLegacyClickTelemetry(tile: tile, position: position)
    }

    private func sendTelemetry(urlString: String, position: Int) {
        guard var urlComponents = URLComponents(string: urlString) else {
            logger.log("The provided URL is invalid: \(String(describing: urlString))",
                       level: .warning,
                       category: .legacyHomepage)
            return
        }

        var queryItems = urlComponents.queryItems ?? []
        queryItems.append(URLQueryItem(name: "position", value: String(position)))
        urlComponents.queryItems = queryItems

        guard let url = urlComponents.url else {
            logger.log("The provided URL components are invalid: \(String(describing: urlString))",
                       level: .warning,
                       category: .legacyHomepage)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = HTTPMethod.get.rawValue

        networking.data(from: request) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                break // We only want to know if it failed
            case .failure:
                logger.log("The unified ads telemetry call failed: \(String(describing: urlString))",
                           level: .warning,
                           category: .legacyHomepage)
            }
        }
    }

    // MARK: Legacy telemetry
    // FXIOS-11121 While we are migrating to the new Unified Ads telemetry system, we should
    // keep sending the legacy telemetry Glean pings

    private func sendLegacyImpressionTelemetry(tile: SponsoredTile, position: Int) {
        SponsoredTileTelemetry.sendImpressionTelemetry(tile: tile, position: position, isUnifiedAdsEnabled: true)
    }

    private func sendLegacyClickTelemetry(tile: SponsoredTile, position: Int) {
        SponsoredTileTelemetry.sendClickTelemetry(tile: tile, position: position, isUnifiedAdsEnabled: true)
    }
}
