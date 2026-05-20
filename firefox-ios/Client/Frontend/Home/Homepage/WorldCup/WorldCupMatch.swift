// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// View-ready single match, built from a `WorldCupMatchesResponse.Match`.
/// Fields are pre-formatted for direct display by the homepage matches widget.
struct WorldCupMatch: Equatable, Hashable {
    struct Score: Equatable, Hashable {
        let score: String
        let clock: String
    }

    let homeFlagAssetName: String
    let homeCode: String
    let awayFlagAssetName: String
    let awayCode: String
    let date: String
    let score: Score?

    init(homeFlagAssetName: String,
         homeCode: String,
         awayFlagAssetName: String,
         awayCode: String,
         date: String,
         score: Score?) {
        self.homeFlagAssetName = homeFlagAssetName
        self.homeCode = homeCode
        self.awayFlagAssetName = awayFlagAssetName
        self.awayCode = awayCode
        self.date = date
        self.score = score
    }

    init(_ match: WorldCupMatchesResponse.Match,
         localeProvider: LocaleProvider = SystemLocaleProvider(),
         timeOnly: Bool = false) {
        self.homeCode = match.homeTeam?.key ?? Self.missingTeamPlaceholder
        self.awayCode = match.awayTeam?.key ?? Self.missingTeamPlaceholder
        self.homeFlagAssetName = match.homeTeam?.key ?? ""
        self.awayFlagAssetName = match.awayTeam?.key ?? ""
        self.date = Self.formattedDate(match.date, locale: localeProvider.current, timeOnly: timeOnly)
        self.score = Self.score(from: match)
    }

    /// Placeholder shown for team code and flag asset name when the merino
    /// response omits a team (e.g. a knockout fixture whose participants
    /// aren't decided yet). No asset matches this name so the flag view falls
    /// back to its background color.
    private static let missingTeamPlaceholder = "--"

    /// Parses a merino-style ISO8601 match date (e.g. `2026-06-12T18:00:00+00:00`
    /// or `2026-06-12T18:00:00.000Z`). Returns `nil` if neither formatter
    /// accepts the string.
    static func parseDate(_ iso: String) -> Date? {
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        if let date = plain.date(from: iso) { return date }

        let frac = ISO8601DateFormatter()
        frac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return frac.date(from: iso)
    }

    private static func formattedDate(_ iso: String, locale: Locale, timeOnly: Bool = false) -> String {
        guard let date = parseDate(iso) else { return iso }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate(timeOnly ? "jmm" : "MMMdjmm")
        return formatter.string(from: date)
    }

    private static func score(from match: WorldCupMatchesResponse.Match) -> Score? {
        guard let home = match.homeScore, let away = match.awayScore else { return nil }
        return Score(
            score: scoreText(
                    home: home,
                    away: away,
                    homePenalty: match.homePenalty,
                    awayPenalty: match.awayPenalty),
            clock: clockText(match.clock)
        )
    }

    private static func scoreText(home: Int,
                                  away: Int,
                                  homePenalty: Int?,
                                  awayPenalty: Int?) -> String {
        if let homePK = homePenalty, let awayPK = awayPenalty {
            return "\(home) (\(homePK)) – \(away) (\(awayPK))"
        }
        return "\(home) – \(away)"
    }

    private static func clockText(_ clock: String?) -> String {
        clock.map { "\($0)'" } ?? ""
    }
}
