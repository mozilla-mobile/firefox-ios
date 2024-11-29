// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

/// Send click and impression telemetry using the unified tile callbacks
protocol UnifiedAdsCallbackTelemetry {
    func sendImpressionTelemetry(tile: SponsoredTile)
    func sendClickTelemetry(tile: SponsoredTile)
}

class DefaultUnifiedAdsCallbackTelemetry: UnifiedAdsCallbackTelemetry {
    private var networking: ContileNetworking
    private var logger: Logger

    init(
        networking: ContileNetworking = DefaultContileNetwork(
            with: makeURLSession(userAgent: UserAgent.mobileUserAgent(),
                                 configuration: URLSessionConfiguration.defaultMPTCP)),
        logger: Logger = DefaultLogger.shared
    ) {
        self.networking = networking
        self.logger = logger
    }

    func sendImpressionTelemetry(tile: SponsoredTile) {
        let impressionURL = tile.impressionURL
        sendTelemetry(urlString: impressionURL)
    }

    func sendClickTelemetry(tile: SponsoredTile) {
        let clickURL = tile.clickURL
        sendTelemetry(urlString: clickURL)
    }

    private func sendTelemetry(urlString: String) {
        guard let url = URL(string: urlString) else {
            logger.log("The provided URL is invalid: \(String(describing: urlString))",
                       level: .warning,
                       category: .legacyHomepage)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

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
}
