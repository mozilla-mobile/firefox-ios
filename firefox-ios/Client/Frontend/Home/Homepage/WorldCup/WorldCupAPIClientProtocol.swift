// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import MozillaAppServices

/// Which merino WCS endpoint to hit. Used by `WorldCupAPIClientProtocol`.
enum WorldCupQuery: Equatable {
    case matches, live
}

/// Surface for the merino World Cup matches client. Concrete impl lives in
/// `WorldCupAPIClient`; mocks conform to the same protocol in tests.
protocol WorldCupAPIClientProtocol: Sendable {
    /// Low-level sync fetch + decode. Throws on FFI error or decode failure.
    func fetch(_ query: WorldCupQuery, options: WorldCupOptions) throws -> WorldCupMatchesResponse?

    /// High-level async loader: dispatches the fetch through the configured
    /// fetch strategy and returns the decoded merino response. `nil` if the
    /// strategy fails. Callers transform the response into a view-model.
    func loadMatches(query: WorldCupQuery) async -> WorldCupMatchesResponse?
}
