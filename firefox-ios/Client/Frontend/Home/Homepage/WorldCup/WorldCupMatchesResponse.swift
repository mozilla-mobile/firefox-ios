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

    /// Returns a copy of this response with each bucket restricted to
    /// matches that involve `team` (by 3-letter FIFA key) as home or away.
    /// Used to derive the single-team card from the now-unfiltered
    /// `/matches` payload — see `WorldCupFeed.buildSnapshot`.
    func filtered(toTeam team: String) -> WorldCupMatchesResponse {
        func involvesTeam(_ match: Match) -> Bool {
            match.homeTeam?.key == team || match.awayTeam?.key == team
        }
        return WorldCupMatchesResponse(
            now: now,
            previous: previous?.filter(involvesTeam),
            current: current?.filter(involvesTeam),
            next: next?.filter(involvesTeam)
        )
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
        /// Tournament stage. Decoded from the merino `stage` string into a
        /// closed set of known values; unrecognized strings fall through to
        /// `.unknown(raw)` so a new merino value doesn't fail decode and the
        /// raw label is still available for logging.
        let stage: Stage?
        /// The game status, e.g. "Scheduled", "Delayed", "Postponed", "Break".
        let status: String?

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
             status: String? = nil,
             stage: Stage? = nil) {
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
            self.status = status
            self.stage = stage
        }

        /// The team that won this match, if a winner can be determined.
        /// Resolves a penalty shootout first (when both penalty scores are
        /// present), otherwise compares the regulation score plus any
        /// extra-time goals. Returns `nil` for draws, scoreless/in-progress
        /// matches, or matches missing either team.
        var winnerTeam: Team? {
            guard statusType == "past" else { return nil }
            guard let homeTeam, let awayTeam,
                  let homeScore, let awayScore else { return nil }
            if let homePenalty, let awayPenalty {
                if homePenalty > awayPenalty { return homeTeam }
                if awayPenalty > homePenalty { return awayTeam }
                return nil
            }
            let homeTotal = homeScore + (homeExtra ?? 0)
            let awayTotal = awayScore + (awayExtra ?? 0)
            if homeTotal > awayTotal { return homeTeam }
            if awayTotal > homeTotal { return awayTeam }
            return nil
        }

        /// Whether the match is currently in a half-time break, either the
        /// regulation half-time or the extra-time half-time break.
        var isInBreak: Bool {
            // During a penalty shootout we ignore the "Break" status: a
            // half-time label makes no sense in a shootout, so don't show it.
            if ["pen", "penaltyshootout"].contains(period?.lowercased() ?? "") || homePenalty != nil || awayPenalty != nil {
                return false
            }
            return status == "Break"
        }

        /// Closed set of tournament stages emitted by merino's `stage` field.
        /// `rawValue` round-trips the original server string — including the
        /// `.unknown` case — which makes it suitable both for decoding and as
        /// a stable, untranslated telemetry identifier.
        enum Stage: Decodable, Hashable, Sendable {
            case groupStage
            case roundOf32
            case roundOf16
            case quarterFinals
            case semiFinals
            case thirdPlace
            case final
            case unknown(String)

            var rawValue: String {
                switch self {
                case .groupStage: return "Group Stage"
                case .roundOf32: return "Round of 32"
                case .roundOf16: return "Round of 16"
                case .quarterFinals: return "Quarter-finals"
                case .semiFinals: return "Semi-finals"
                case .thirdPlace: return "3rd Place"
                case .final: return "Final"
                case .unknown(let raw): return raw
                }
            }

            init(from decoder: Decoder) throws {
                let raw = try decoder.singleValueContainer().decode(String.self)
                switch raw {
                case "Group Stage": self = .groupStage
                case "Round of 32": self = .roundOf32
                case "Round of 16": self = .roundOf16
                case "Quarter-finals": self = .quarterFinals
                case "Semi-finals": self = .semiFinals
                case "3rd Place": self = .thirdPlace
                case "Final": self = .final
                default: self = .unknown(raw)
                }
            }
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
