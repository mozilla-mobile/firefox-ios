// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Glean

/// An enumeration representing different environments for the OHTTP client.
public enum OhttpEnvironment {
    case staging
    case prod

    // TODO: Laurie - config URL to pass into the OHTTPManager?
    /// Returns the configuration URL based on the selected environment.
    var config: URL? {
        switch self {
        case .staging:
            return URL(string: "https://stage.ohttp-gateway.nonprod.webservices.mozgcp.net/ohttp-configs")
        case .prod:
            return URL(string: "https://prod.ohttp-gateway.prod.webservices.mozgcp.net/ohttp-configs")
        }
    }

    // TODO: Laurie - relay URL to pass into the OHTTPManager?
    /// Returns the relay URL based on the selected environment.
    var relay: URL? {
        switch self {
        case .staging:
            return URL(string: "https://mozilla-ohttp-dev.fastly-edge.com/")
        case .prod:
            return URL(string: "https://mozilla-ohttp-dev.fastly-edge.com/")
        }
    }

    static func getEnvironment() -> OhttpEnvironment {
        // TODO: Laurie - Double-check this is accurate
        let shouldUseRelease = AppConstants.buildChannel == .release || AppConstants.buildChannel == .beta
        return shouldUseRelease ? OhttpEnvironment.prod: OhttpEnvironment.staging
    }
}

public struct OhttpGleanUploader: PingUploader {
    private let environment: OhttpEnvironment
    private let capabilities = ["ohttp"]
    private let connectionTimeout = TimeInterval(10)

    public init(environment: OhttpEnvironment) {
        self.environment = environment
    }

    public func upload(request: CapablePingUploadRequest, callback: @escaping (UploadResult) -> Void) {
        guard let config = environment.config,
              let relay = environment.relay
        else {
            // TODO: Laurie - What Int8 should be passed here for the unrecoverableFailure?
            callback(UploadResult.unrecoverableFailure(unused: 0))
            return
        }

        let manager = StubOhttpManager(configUrl: config, relayUrl: relay)
        guard let capableRequest = request.capable(capabilities),
              let url = URL(string: capableRequest.url) else { return }

        var body = Data(capacity: capableRequest.data.count)
        body.append(contentsOf: capableRequest.data)

        // TODO: Laurie - Cache policy? timeoutInterval? etc. Double check request info
        var oHttpRequest = URLRequest(url: url,
                                      cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        for (field, value) in capableRequest.headers {
            oHttpRequest.addValue(value, forHTTPHeaderField: field)
        }
        oHttpRequest.timeoutInterval = connectionTimeout
        oHttpRequest.httpBody = body
        oHttpRequest.httpMethod = "POST"
        oHttpRequest.httpShouldHandleCookies = false

        Task {
            do {
                let response = try await manager.data(for: oHttpRequest)
                let httpResponse = response.1
                let statusCode = Int32(httpResponse.statusCode)
                // HTTP status codes are handled on the Rust side
                callback(.httpStatus(code: statusCode))
            } catch {
                // Upload failed on the client-side. We should try again.
                callback(.recoverableFailure(unused: 0))
            }
        }
    }
}

