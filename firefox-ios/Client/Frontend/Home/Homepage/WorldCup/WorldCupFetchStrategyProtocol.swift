// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Stream of `/matches` results — single emission for one-shot strategies,
/// continuous emission for polling strategies. The `Result` carries the
/// decoded body (or `nil` for HTTP 204) or a mapped `WorldCupLoadError`.
typealias WorldCupMatchesStream = AsyncStream<Result<WorldCupMatchesResponse?, WorldCupLoadError>>

/// Stream of `/live` results, same shape as `WorldCupMatchesStream`.
typealias WorldCupLiveStream = AsyncStream<Result<WorldCupLiveResponse?, WorldCupLoadError>>

protocol WorldCupFetchStrategyProtocol: Sendable {
    /// Emits results from the `/matches` endpoint until the stream's
    /// iterator is cancelled. A "single attempt" strategy yields exactly
    /// once and finishes; a polling strategy yields until cancelled.
    func matchesStream(using client: WorldCupAPIClientProtocol, team: String?) -> WorldCupMatchesStream

    /// Emits results from the `/live` endpoint, same shape as `matchesStream`.
    func liveStream(using client: WorldCupAPIClientProtocol, team: String?) -> WorldCupLiveStream

    /// One-shot teams roster fetch.
    func loadTeams(using client: WorldCupAPIClientProtocol,
                   team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError>
}
