// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Glean
import Shared
import MozillaAppServices

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

    static func getEnvironment() -> OhttpEnvironment {
        return OhttpEnvironment.prod
    }
}

/// Custom Glean Ping Uploader adding the OHTTP capability into Glean, as well as supporting the default HTTP capability
struct GleanPingUploader: PingUploader {
    private let ohttpEnvironment: OhttpEnvironment
    private let connectionTimeout = TimeInterval(10)
    private let logger: Logger
    private let session: URLSessionProtocol

    enum PingCapability: String {
        case ohttp, http
    }

    init(ohttpEnvironment: OhttpEnvironment,
         logger: Logger = DefaultLogger.shared,
         session: URLSessionProtocol = NetworkUtils.defaultGleanPingURLSession) {
        self.ohttpEnvironment = ohttpEnvironment
        self.logger = logger
        self.session = session
    }

    func upload(request: CapablePingUploadRequest,
                callback: @escaping (UploadResult) -> Void) {
        if let capableRequest = request.capable([PingCapability.ohttp.rawValue]) {
            uploadOhttpRequest(request: capableRequest, callback: callback)
        } else if let capableRequest = request.capable([PingCapability.http.rawValue]) {
            uploadHttpRequest(request: capableRequest, callback: callback)
        } else {
            logger.log("Rejected ping upload due to unsupported capabilities", level: .info, category: .telemetry)
            callback(.incapable(unused: 0))
            return
        }
    }

    /// Build the request and create upload operation using the `OhttpManager`
    private func uploadOhttpRequest(request: PingUploadRequest,
                                    callback: @escaping (UploadResult) -> Void) {
        guard let config = ohttpEnvironment.config,
              let relay = ohttpEnvironment.relay,
              let url = URL(string: request.url)
        else {
            logger.log("Rejected ohttp ping upload due environment variables", level: .info, category: .telemetry)
            callback(.unrecoverableFailure(unused: 0))
            return
        }

        let manager = OhttpManager(configUrl: config, relayUrl: relay)
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

    /// Build the request and create upload operation using a URLSession
    private func uploadHttpRequest(request: PingUploadRequest,
                                   callback: @escaping (UploadResult) -> Void) {
        var body = Data(capacity: request.data.count)
        body.append(contentsOf: request.data)

        if let request = self.buildRequest(
            url: request.url,
            data: body,
            headers: request.headers
        ) {
            // Create an URLSessionUploadTask to upload our ping and handle the
            // server responses.
            let uploadTask = session.uploadTask(with: request, from: body) { _, response, error in
                if let error {
                    // Upload failed on the client-side. We should try again.
                    logger.log("Upload failed on the client-side: \(error)", level: .info, category: .telemetry)
                    callback(.recoverableFailure(unused: 0))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    logger.log("Upload failed due to unexpected response type", level: .info, category: .telemetry)
                    callback(.recoverableFailure(unused: 0))
                    return
                }

                // HTTP status codes are handled on the Rust side
                let statusCode = Int32(httpResponse.statusCode)
                callback(.httpStatus(code: statusCode))
            }

            uploadTask.countOfBytesClientExpectsToSend = 1024 * 1024
            uploadTask.countOfBytesClientExpectsToReceive = 512
            uploadTask.resume()
        }
    }

    /// Builds the request used for uploading the pings.
    ///
    /// - Parameters:
    ///   - url: The URL, including the path, to use for the destination of the ping
    ///   - data:  The serialized text data to send
    ///   - headers: Map of headers from Glean to annotate ping with
    ///
    /// - Returns: Optional `URLRequest` object with the configured headings set.
    private func buildRequest(url: String, data: Data, headers: [String: String]) -> URLRequest? {
        guard let url = URL(string: url) else {
            logger.log("HTTP request could not be built", level: .info, category: .telemetry)
            return nil
        }

        var request = URLRequest(url: url)
        for (field, value) in headers {
            request.addValue(value, forHTTPHeaderField: field)
        }
        request.timeoutInterval = connectionTimeout
        request.httpMethod = HTTPMethod.post.rawValue
        request.httpShouldHandleCookies = false

        // NOTE: We're using `URLSession.uploadTask` which ignores the `httpBody` and
        // instead takes the body payload as a parameter to add to the request.
        // However in tests we're using OHHTTPStubs to stub out the HTTP upload.
        // It has the known limitation that it doesn't simulate data upload,
        // because the underlying protocol doesn't expose a hook for that.
        // By setting `httpBody` here the data is still attached to the request,
        // so OHHTTPStubs sees it.
        // It shouldn't be too bad memory-wise and not duplicate the data in memory.
        // This should only be a reference and Swift keeps track of all the places it's needed.
        //
        // See https://github.com/AliSoftware/OHHTTPStubs#known-limitations.
        request.httpBody = data

        return request
    }
}
