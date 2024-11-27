// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

/// Used only for sponsored tiles content and telemetry. This is aiming to be a temporary API
/// as we'll migrate to using A-S for this at some point in 2025
protocol UnifiedAdsNetwork {
    func data(from request: URLRequest, completion: @escaping (NetworkingContileResult) -> Void)
}

class DefaultUnifiedAdsNetwork: UnifiedAdsNetwork {
    private var urlSession: URLSessionProtocol
    private var logger: Logger

    init(with urlSession: URLSessionProtocol,
         logger: Logger = DefaultLogger.shared) {
        self.urlSession = urlSession
        self.logger = logger
    }

    func data(from request: URLRequest, completion: @escaping (NetworkingContileResult) -> Void) {
        urlSession.dataTaskWith(request: request) { [weak self] data, response, error in
            guard self != nil else { return }
            // TODO: FXIOS-10715
        }.resume()
    }
}
