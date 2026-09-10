// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public extension AppAttestServiceError {
    /// Throws `serverError` for any non-2xx response, carrying the status code and the body as the
    /// message. Non-HTTP responses pass through, since they have no status to judge.
    static func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw AppAttestServiceError.serverError(statusCode: http.statusCode, description: message)
        }
    }
}
