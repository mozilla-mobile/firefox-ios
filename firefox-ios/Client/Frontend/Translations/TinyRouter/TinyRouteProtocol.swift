// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Protocol defining a route that can handle incoming URL requests.
/// Conforming types can process URLs and return appropriate HTTP responses.
protocol TinyRoute: Sendable {
    /// Attempts to handle an incoming URL request. Throws If the request is malformed or processing fails
    func handle(url: URL, components: URLComponents) async throws -> TinyHTTPReply?
}
