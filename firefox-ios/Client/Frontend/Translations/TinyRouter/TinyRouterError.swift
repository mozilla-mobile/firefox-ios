// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Errors that can be thrown during request processing in TinyRouter.
/// These errors can be thrown from routes or the router itself.
public enum TinyRouterError: Error, Equatable {
    /// No route matched the request and no default route produced a reply
    case notFound
    /// URL couldn't be parsed into URLComponents
    case badURL
    /// URL scheme didn't match the handler's expected scheme
    case unsupportedScheme(expected: String, found: String?)
    /// URL host didn't match the handler's expected host
    case unsupportedHost(expected: String, found: String?)
    /// A required query parameter was missing from the request
    case missingParam(_ name: String)
    /// A query parameter value was present but invalid
    case invalidParam(_ name: String, _ value: String)
    /// The handler built an invalid response
    case badResponse
    /// A catch-all wrapper for unexpected errors, storing a textual description
    /// for logging and debugging while keeping this enum Equatable.
    case unknown(_ description: String)
}
