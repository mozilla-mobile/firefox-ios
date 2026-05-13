// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Default fetch strategy. A single attempt with no retry. Maps any thrown
/// error (FFI, decode, unexpected) into `WorldCupLoadError` so the UI can
/// distinguish network failures from other failures.
struct WorldCupNormalFetchStrategy: WorldCupFetchStrategyProtocol {
    func loadMatches(using client: WorldCupAPIClientProtocol,
                     query: WorldCupQuery,
                     team: String?) async -> Result<WorldCupMatchesResponse?, WorldCupLoadError> {
        await Task.detached(priority: .userInitiated) {
            () -> Result<WorldCupMatchesResponse?, WorldCupLoadError> in
            do {
                return .success(try client.fetch(query, team: team))
            } catch {
                return .failure(WorldCupLoadError.from(error))
            }
        }.value
    }

    func loadTeams(using client: WorldCupAPIClientProtocol,
                   team: String?) async -> Result<WorldCupTeamsResponse?, WorldCupLoadError> {
        await Task.detached(priority: .userInitiated) {
            () -> Result<WorldCupTeamsResponse?, WorldCupLoadError> in
            do {
                return .success(try client.fetchTeams(team: team))
            } catch {
                return .failure(WorldCupLoadError.from(error))
            }
        }.value
    }
}
