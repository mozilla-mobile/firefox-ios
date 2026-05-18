// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Policy that drives how a WCS response is loaded, single attempt, retry
/// with backoff, etc. Each strategy is a complete recipe: it receives the
/// low-level client and is responsible for orchestrating the call(s) and
/// returning the decoded response (or a mapped error). Add a new conformer
/// (e.g. exponential backoff) without changing call sites by passing it to
/// `WorldCupAPIClient.init(matchesStrategy:liveStrategy:teamsStrategy:)`.
protocol WorldCupFetchStrategyProtocol: Sendable {
    func loadMatches(using client: WorldCupAPIClientProtocol,
                     query: WorldCupQuery,
                     team: String?) async -> Result<WorldCupMatchesResponse?, WorldCupLoadError>

    func loadTeams(using client: WorldCupAPIClientProtocol,
                   team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError>
}
