// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// View-ready single match, built from a `WorldCupMatchesResponse.Match`.
/// Fields are pre-formatted for direct display by the homepage matches widget.
struct WorldCupMatch: Equatable {
    struct Score: Equatable {
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
         localeProvider: LocaleProvider = SystemLocaleProvider()) {
        self.homeCode = match.homeTeam.key
        self.awayCode = match.awayTeam.key
        // TODO: FXIOS-15778: Rename flag imageset names to 3-letter FIFA codes
        // (br -> bra, us -> usa, etc.) so the team key can be used directly.
        self.homeFlagAssetName = match.homeTeam.key.lowercased()
        self.awayFlagAssetName = match.awayTeam.key.lowercased()
        self.date = Self.formattedDate(match.date, locale: localeProvider.current)
        self.score = Self.score(from: match)
    }

    nonisolated(unsafe) private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private static func formattedDate(_ iso: String, locale: Locale) -> String {
        guard let date = isoFormatter.date(from: iso) else { return iso }
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("EEEMMMd")
        return formatter.string(from: date)
    }

    private static func score(from match: WorldCupMatchesResponse.Match) -> Score? {
        guard let home = match.homeScore, let away = match.awayScore else { return nil }
        return Score(
            score: scoreText(home: home, away: away,
                             homePenalty: match.homePenalty,
                             awayPenalty: match.awayPenalty),
            clock: clockText(match.clock)
        )
    }

    private static func scoreText(home: Int, away: Int,
                                  homePenalty: Int?, awayPenalty: Int?) -> String {
        if let homePK = homePenalty, let awayPK = awayPenalty {
            return "\(home) (\(homePK)) – \(away) (\(awayPK))"
        }
        return "\(home) – \(away)"
    }

    private static func clockText(_ clock: String?) -> String {
        clock.map { "\($0)'" } ?? ""
    }
}
