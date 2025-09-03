// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import MozillaAppServices
import Shared

protocol ASOhttpManager {
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

extension OhttpManager: ASOhttpManager {}

/// An enumeration representing different environments for the OHTTP client.
/// This is an enum in case we want to add other environment other than production.
enum OhttpEnvironment {
    case prod

    /// Returns the configuration URL based on the selected environment.
    var config: URL? {
        switch self {
        case .prod:
            return URL(string: "https://prod.ohttp-gateway.prod.webservices.mozgcp.net/ohttp-configs")
        }
    }

    /// Returns the relay URL based on the selected environment.
    var relay: URL? {
        switch self {
        case .prod:
            return URL(string: "https://mozilla-ohttp.fastly-edge.com/")
        }
    }
}

struct GleanOhttpUploader {
    private let connectionTimeout = TimeInterval(10)
    private let manager: ASOhttpManager
    private let logger: Logger

    init(manager: ASOhttpManager,
         logger: Logger = DefaultLogger.shared) {
        self.manager = manager
        self.logger = logger
    }

    /// Build the request and create upload operation using the `OhttpManager`
    func uploadOhttpRequest(request: GleanPingUploadRequest,
                            callback: @escaping (UploadResult) -> Void) {
        guard let url = URL(string: request.url)
        else {
            logger.log("Rejected ohttp ping upload due environment variables", level: .info, category: .telemetry)
            callback(.unrecoverableFailure(unused: 0))
            return
        }

        var body = Data(capacity: request.data.count)
        body.append(contentsOf: request.data)

        var oHttpRequest = URLRequest(url: url,
                                      cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)
        for (field, value) in request.headers {
            oHttpRequest.addValue(value, forHTTPHeaderField: field)
        }
        oHttpRequest.timeoutInterval = connectionTimeout
        oHttpRequest.httpBody = body
        oHttpRequest.httpMethod = HTTPMethod.post.rawValue
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
                logger.log("Upload failed on the client-side: \(error)", level: .info, category: .telemetry)
                callback(.recoverableFailure(unused: 0))
            }
        }
    }
}
