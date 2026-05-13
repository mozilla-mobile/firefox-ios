// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Which merino WCS endpoint to hit. Used by `WorldCupAPIClientProtocol`.
enum WorldCupQuery: Equatable {
    case matches, live
}

/// Surface for the merino World Cup matches client. Concrete impl lives in
/// `WorldCupAPIClient`; mocks conform to the same protocol in tests.
///
/// `team` (3-letter FIFA key) is the only filter exposed at this layer. The
/// underlying FFI `WorldCupOptions` is intentionally hidden.
protocol WorldCupAPIClientProtocol: Sendable {
    /// Low-level sync matches fetch + decode. Throws on FFI error or decode failure.
    func fetch(_ query: WorldCupQuery, team: String?) throws -> WorldCupMatchesResponse?

    /// Low-level sync teams fetch + decode. Throws on FFI error or decode failure.
    func fetchTeams(team: String?) throws -> WorldCupTeamsResponse?

    /// High-level async loader: dispatches the matches fetch through the
    /// configured fetch strategy and returns either the decoded merino
    /// response or a `WorldCupLoadError` the UI can pattern-match on.
    /// Callers transform the success response into a view-model.
    func loadMatches(query: WorldCupQuery,
                     team: String?) async -> Result<WorldCupMatchesResponse?, WorldCupLoadError>

    /// High-level async loader for the teams roster. Runs the blocking FFI
    /// call off-main and returns the decoded response or a `WorldCupLoadError`
    /// the UI can pattern-match on.
    func loadTeams(team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError>
}
