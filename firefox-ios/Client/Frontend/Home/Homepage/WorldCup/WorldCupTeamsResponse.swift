// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Mirrors the JSON returned by the merino `/api/v1/wcs/teams` endpoint
/// (wrapped by `MozillaAppServices.WorldCupClient.getTeams`).
///
/// Returns the full team roster with standings — useful for inferring round
/// from surviving (non-eliminated) team count, listing groups, etc.
struct WorldCupTeamsResponse: Decodable, Equatable {
    let teams: [Team]

    struct Team: Decodable, Equatable {
        /// 3-letter FIFA-style team key (e.g. `BRA`, `ENG`, `USA`).
        let key: String
        let globalTeamId: Int?
        let name: String
        let region: String?
        let colors: [String]?
        let iconUrl: String?
        /// Group label, e.g. `"Group A"`. Set throughout the tournament.
        let group: String?
        /// True once the team is out of the tournament.
        let eliminated: Bool?
        let standing: Standing?
    }

    struct Standing: Decodable, Equatable {
        let wins: Int?
        let losses: Int?
        let draws: Int?
        let points: Int?
    }
}
