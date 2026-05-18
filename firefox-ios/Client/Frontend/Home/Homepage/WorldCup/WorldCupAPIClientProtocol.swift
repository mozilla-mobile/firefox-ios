// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Surface for the merino World Cup matches client. Concrete impl lives in
/// `WorldCupAPIClient`; mocks conform to the same protocol in tests.
///
/// The `/matches` and `/live` merino endpoints emit different JSON shapes —
/// `{ previous/current/next }` vs `{ matches }` — so they get their own
/// typed methods and response types rather than sharing a query enum.
///
/// `team` (3-letter FIFA key) is the only filter exposed at this layer. The
/// underlying FFI `WorldCupOptions` is intentionally hidden.
protocol WorldCupAPIClientProtocol: Sendable {
    /// Low-level sync matches fetch + decode. Throws on FFI error or decode failure.
    func fetchMatches(team: String?) throws -> WorldCupMatchesResponse?

    /// Low-level sync live fetch + decode. Throws on FFI error or decode failure.
    func fetchLive(team: String?) throws -> WorldCupLiveResponse?

    /// Low-level sync teams fetch + decode. Throws on FFI error or decode failure.
    func fetchTeams(team: String?) throws -> WorldCupTeamsResponse?

    /// High-level async loader for `/matches`. Dispatches through the configured
    /// matches fetch strategy.
    func loadMatches(team: String?) async -> Result<WorldCupMatchesResponse?, WorldCupLoadError>

    /// High-level async loader for `/live`. Dispatches through the configured
    /// live fetch strategy.
    func loadLive(team: String?) async -> Result<WorldCupLiveResponse?, WorldCupLoadError>

    /// High-level async loader for the teams roster. Runs the blocking FFI
    /// call off-main and returns the decoded response or a `WorldCupLoadError`
    /// the UI can pattern-match on.
    func loadTeams(team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError>
}
