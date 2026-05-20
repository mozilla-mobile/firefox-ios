// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Mirrors the JSON returned by the merino `/api/v1/wcs/matches` endpoint
/// (wrapped by `MozillaAppServices.WorldCupClient.getMatches`). The `live`
/// endpoint emits a flat `{ matches: [...] }` shape and is decoded into
/// `WorldCupLiveResponse` instead — don't confuse `current` here with "live".
/// `current` just means "matches whose date equals the query `date=`".
struct WorldCupMatchesResponse: Decodable, Equatable, Sendable {
    /// ISO8601 timestamp the server considers "now" for this response. Only
    /// the dev/mock server populates this — prod merino omits the key so it
    /// decodes as `nil`. Honored by `WorldCupMiddleware` only when the
    /// `WorldCupBaseHost` pref is set, so a stray prod value can't shift
    /// bucketing for real users.
    let now: String?
    let previous: [Match]?
    let current: [Match]?
    let next: [Match]?

    init(now: String? = nil,
         previous: [Match]? = nil,
         current: [Match]? = nil,
         next: [Match]? = nil) {
        self.now = now
        self.previous = previous
        self.current = current
        self.next = next
    }

    struct Match: Decodable, Equatable, Sendable {
        let date: String
        let globalEventId: Int
        let homeTeam: Team?
        let awayTeam: Team?
        let period: String?
        let homeScore: Int?
        let awayScore: Int?
        let homeExtra: Int?
        let awayExtra: Int?
        let homePenalty: Int?
        let awayPenalty: Int?
        let clock: String?
        /// Server-side last-updated timestamp for this match. Useful for
        /// de-duping or short-circuiting "no change since last fetch" logic.
        /// Type intentionally untyped (Int) — merino's docs show it but don't
        /// nail down whether it's epoch seconds, millis, or a revision counter.
        let updated: Int?
        /// "past", "live", or "scheduled".
        /// Not typing this since we don't want to couple the client too tightly to the API's exact status values,
        /// in case of future additions or changes.
        let statusType: String?
        /// Tournament stage, e.g. "Group Stage", "Round of 32", "Round of 16",
        /// "Quarterfinals", "Semifinals", "Third Place", "Final". Mapped to a
        /// localized phase label by `WorldCupMatches.phaseTitle`. Untyped on
        /// purpose so a new merino value doesn't fail decode — unknown values
        /// fall back to a generic label.
        let stage: String?

        init(date: String,
             globalEventId: Int,
             homeTeam: Team?,
             awayTeam: Team?,
             period: String? = nil,
             homeScore: Int? = nil,
             awayScore: Int? = nil,
             homeExtra: Int? = nil,
             awayExtra: Int? = nil,
             homePenalty: Int? = nil,
             awayPenalty: Int? = nil,
             clock: String? = nil,
             updated: Int? = nil,
             statusType: String? = nil,
             stage: String? = nil) {
            self.date = date
            self.globalEventId = globalEventId
            self.homeTeam = homeTeam
            self.awayTeam = awayTeam
            self.period = period
            self.homeScore = homeScore
            self.awayScore = awayScore
            self.homeExtra = homeExtra
            self.awayExtra = awayExtra
            self.homePenalty = homePenalty
            self.awayPenalty = awayPenalty
            self.clock = clock
            self.updated = updated
            self.statusType = statusType
            self.stage = stage
        }
    }

    struct Team: Decodable, Equatable, Sendable {
        /// 3-letter FIFA-style team key (e.g. `BRA`, `ENG`, `USA`).
        let key: String
        let name: String
        let iconUrl: String?
        let group: String?
        let eliminated: Bool?
    }
}
