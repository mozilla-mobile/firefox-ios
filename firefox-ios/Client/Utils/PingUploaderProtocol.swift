// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

protocol PingUploaderProtocol {
    var connectionTimeout: TimeInterval { get }
    var logger: Logger { get }
    func buildRequest(url: String, data: Data, headers: [String: String]) -> URLRequest?
}

extension PingUploaderProtocol {
    /// Builds the request used for uploading the pings.
    ///
    /// - Parameters:
    ///   - url: The URL, including the path, to use for the destination of the ping
    ///   - data:  The serialized text data to send
    ///   - headers: Map of headers from Glean to annotate ping with
    ///
    /// - Returns: Optional `URLRequest` object with the configured headings set.
    func buildRequest(url: String, data: Data, headers: [String: String]) -> URLRequest? {
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

        return request
    }
}
