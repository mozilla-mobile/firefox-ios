// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Mirrors the JSON returned by the merino `/api/v1/wcs/matches` endpoint
/// (wrapped by `MozillaAppServices.WorldCupClient.getMatches`). The `live`
/// endpoint returns the same shape but only populates `current`.
struct WorldCupMatchesResponse: Decodable, Equatable {
    let previous: [Match]?
    let current: [Match]?
    let next: [Match]?

    struct Match: Decodable, Equatable {
        let date: String
        let globalEventId: Int
        let homeTeam: Team
        let awayTeam: Team
        let period: String?
        let homeScore: Int?
        let awayScore: Int?
        let homeExtra: Int?
        let awayExtra: Int?
        let homePenalty: Int?
        let awayPenalty: Int?
        let clock: String?
        /// "past", "live", or "scheduled".
        /// Not typing this since we don't want to couple the client too tightly to the API's exact status values,
        /// in case of future additions or changes.
        let statusType: String?
    }

    struct Team: Decodable, Equatable {
        /// 3-letter FIFA-style team key (e.g. `BRA`, `ENG`, `USA`).
        let key: String
        let name: String
        let iconUrl: String?
        let group: String?
        let eliminated: Bool?
    }
}
