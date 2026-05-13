// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing
import Foundation
@testable import Client

@Suite("WorldCupTeamsResponse decoding")
struct WorldCupTeamsResponseTests {
    private let json = """
    {
      "teams": [
        {
          "key": "BRA",
          "global_team_id": 90000861,
          "name": "Brazil",
          "region": "BRA",
          "colors": ["#009C3B", "#FFDF00", "#002776"],
          "icon_url": "https://example.com/bra.svg",
          "group": "Group A",
          "eliminated": false,
          "standing": {"wins": 2, "losses": 0, "draws": 1, "points": 7}
        },
        {
          "key": "USA",
          "global_team_id": 90000872,
          "name": "United States",
          "region": "USA",
          "colors": ["#B22234", "#FFFFFF", "#3C3B6E"],
          "icon_url": null,
          "group": "Group C",
          "eliminated": true,
          "standing": {"wins": 0, "losses": 3, "draws": 0, "points": 0}
        }
      ]
    }
    """

    @Test
    func test_decodesTeamsRoster() throws {
        let response = try decode(json)

        #expect(response.teams.count == 2)

        let bra = try #require(response.teams.first)
        #expect(bra.key == "BRA")
        #expect(bra.name == "Brazil")
        #expect(bra.group == "Group A")
        #expect(bra.eliminated == false)
        #expect(bra.iconUrl == "https://example.com/bra.svg")
        #expect(bra.standing?.points == 7)
    }

    @Test
    func test_decodesEliminatedTeam() throws {
        let response = try decode(json)
        let usa = try #require(response.teams.last)

        #expect(usa.key == "USA")
        #expect(usa.eliminated == true)
        #expect(usa.iconUrl == nil)
        #expect(usa.standing?.losses == 3)
    }

    @Test
    func test_decodesEmptyTeamsArray() throws {
        let response = try decode(#"{ "teams": [] }"#)
        #expect(response.teams.isEmpty)
    }

    private func decode(_ json: String) throws -> WorldCupTeamsResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WorldCupTeamsResponse.self, from: Data(json.utf8))
    }
}
