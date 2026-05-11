// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
@testable import Client

@Suite("WorldCupMatchesResponse decoding")
struct WorldCupMatchesResponseTests {
    // Representative payload modeled after the merino WCS fixture: one live match
    // (with PK fields), one scheduled match (with null scores). Verifies snake_case
    // -> camelCase decoding and that null-vs-missing optional fields decode cleanly.
    private let json = """
    {
      "current": [{
        "date": "2026-04-30T14:00:00+00:00",
        "global_event_id": 1002,
        "home_team": {
          "key": "ENG", "global_team_id": 5, "name": "England", "region": "ENG",
          "colors": ["White","Red"], "icon_url": "https://example.com/eng.png",
          "group": "Group C", "eliminated": false,
          "standing": {"wins":0,"losses":0,"draws":0,"points":0}
        },
        "away_team": {
          "key": "USA", "global_team_id": 6, "name": "United States", "region": "USA",
          "colors": ["Navy","White","Red"], "icon_url": "https://example.com/usa.png",
          "group": "Group C", "eliminated": false,
          "standing": {"wins":0,"losses":0,"draws":0,"points":0}
        },
        "period": "2", "home_score": 1, "away_score": 0,
        "home_extra": null, "away_extra": null,
        "home_penalty": null, "away_penalty": null,
        "clock": "67", "updated": 1, "status": "In Progress",
        "status_type": "live", "query": null, "sport": "soccer"
      }],
      "next": [{
        "date": "2026-05-01T15:00:00+00:00",
        "global_event_id": 1004,
        "home_team": {
          "key": "ARG", "global_team_id": 2, "name": "Argentina", "region": "ARG",
          "colors": [], "icon_url": null, "group": "Group A", "eliminated": false,
          "standing": {"wins":0,"losses":0,"draws":0,"points":0}
        },
        "away_team": {
          "key": "ENG", "global_team_id": 5, "name": "England", "region": "ENG",
          "colors": [], "icon_url": null, "group": "Group C", "eliminated": false,
          "standing": {"wins":0,"losses":0,"draws":0,"points":0}
        },
        "period": "1", "home_score": null, "away_score": null,
        "home_extra": null, "away_extra": null,
        "home_penalty": null, "away_penalty": null,
        "clock": "0", "updated": 1, "status": "Scheduled",
        "status_type": "scheduled", "query": null, "sport": "soccer"
      }]
    }
    """

    @Test
    func test_decodesLiveAndNextSections() throws {
        let response = try decode(json)

        #expect(response.previous == nil)
        #expect(response.current?.count == 1)
        #expect(response.next?.count == 1)

        let live = try #require(response.current?.first)
        #expect(live.homeTeam.key == "ENG")
        #expect(live.awayTeam.key == "USA")
        #expect(live.homeScore == 1)
        #expect(live.awayScore == 0)
        #expect(live.clock == "67")
        #expect(live.statusType == "live")
        #expect(live.homeTeam.iconUrl == "https://example.com/eng.png")
    }

    @Test
    func test_decodesScheduledMatchWithNullScores() throws {
        let response = try decode(json)
        let scheduled = try #require(response.next?.first)

        #expect(scheduled.homeScore == nil)
        #expect(scheduled.awayScore == nil)
        #expect(scheduled.homePenalty == nil)
        #expect(scheduled.awayPenalty == nil)
        #expect(scheduled.statusType == "scheduled")
        #expect(scheduled.awayTeam.iconUrl == nil)
    }

    private func decode(_ json: String) throws -> WorldCupMatchesResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WorldCupMatchesResponse.self, from: Data(json.utf8))
    }
}
