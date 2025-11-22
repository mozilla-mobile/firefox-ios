// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Glean
import MozillaAppServices

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

// TODO: FXIOS-14157 - GleanOhttpUploader shouldn't be @unchecked Sendable
struct GleanOhttpUploader: PingUploaderProtocol, @unchecked Sendable {
    let connectionTimeout = TimeInterval(10)
    let logger: Logger
    private let manager: ASOhttpManager

    init(manager: ASOhttpManager,
         logger: Logger = DefaultLogger.shared) {
        self.manager = manager
        self.logger = logger
    }

    /// Build the request and create upload operation using the `OhttpManager`
    func uploadOhttpRequest(request: GleanPingUploadRequest,
                            callback: @escaping @Sendable (UploadResult) -> Void) {
        var body = Data(capacity: request.data.count)
        body.append(contentsOf: request.data)

        if let request = buildRequest(
            url: request.url,
            data: body,
            headers: request.headers
        ) {
            Task {
                do {
                    let response = try await manager.data(for: request)
                    let httpResponse = response.1
                    let statusCode = Int32(httpResponse.statusCode)
                    // HTTP status codes are handled on the Rust side
                    callback(.httpStatus(code: statusCode))
                    logger.log("Sent http ping with status code: \(statusCode)", level: .debug, category: .telemetry)
                } catch {
                    // Upload failed on the client-side. We should try again.
                    logger.log("Upload failed on the client-side: \(error)", level: .info, category: .telemetry)
                    callback(.recoverableFailure(unused: 0))
                }
            }
        } else {
            logger.log("Rejected ohttp ping since couldn't build request", level: .info, category: .telemetry)
            callback(.unrecoverableFailure(unused: 0))
        }
    }
}
