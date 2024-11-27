// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// Used only for sponsored tiles content and telemetry. This is aiming to be a temporary API
/// as we'll migrate to using A-S for this at some point next year
protocol UnifiedAdsProviderInterface {
    func fetchTiles(completion: @escaping (ContileResult) -> Void)
}

class UnifiedAdsProvider: UnifiedAdsProviderInterface {
    private static let resourceEndpoint = "https://ads.mozilla.org/v1/ads"

    var urlCache: URLCache
    private var logger: Logger
    private var networking: UnifiedAdsNetwork

    init(
        networking: UnifiedAdsNetwork = DefaultUnifiedAdsNetwork(
            with: makeURLSession(userAgent: UserAgent.mobileUserAgent(),
                                 configuration: URLSessionConfiguration.defaultMPTCP)),
        urlCache: URLCache = URLCache.shared,
        logger: Logger = DefaultLogger.shared
    ) {
        self.logger = logger
        self.networking = networking
        self.urlCache = urlCache
    }

    func fetchTiles(completion: @escaping (ContileResult) -> Void) {
        // TODO: FXIOS-10715
    }
}
