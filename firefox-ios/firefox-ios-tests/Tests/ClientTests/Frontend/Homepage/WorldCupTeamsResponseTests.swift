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

    @Test
    func test_responseEquality_sameContent() {
        let responseA = WorldCupTeamsResponse(teams: [])
        let responseB = WorldCupTeamsResponse(teams: [])
        #expect(responseA == responseB)
    }

    @Test
    func test_responseEquality_differentTeams() {
        let responseA = WorldCupTeamsResponse(teams: [])
        let responseB = WorldCupTeamsResponse(teams: [makeTeam(key: "BRA")])
        #expect(responseA != responseB)
    }

    @Test
    func test_teamEquality() {
        let teamA = makeTeam(key: "BRA")
        let teamB = makeTeam(key: "BRA")
        let teamC = makeTeam(key: "USA")
        #expect(teamA == teamB)
        #expect(teamA != teamC)
    }

    @Test
    func test_teamMemberwiseInit_preservesFields() {
        let team = WorldCupTeamsResponse.Team(
            key: "BRA",
            globalTeamId: 42,
            name: "Brazil",
            region: "BRA",
            colors: ["#009C3B"],
            iconUrl: "https://example.com/bra.svg",
            group: "Group A",
            eliminated: false,
            standing: WorldCupTeamsResponse.Standing(wins: 2, losses: 0, draws: 1, points: 7)
        )
        #expect(team.key == "BRA")
        #expect(team.globalTeamId == 42)
        #expect(team.name == "Brazil")
        #expect(team.region == "BRA")
        #expect(team.colors == ["#009C3B"])
        #expect(team.iconUrl == "https://example.com/bra.svg")
        #expect(team.group == "Group A")
        #expect(team.eliminated == false)
        #expect(team.standing?.points == 7)
    }

    @Test
    func test_standingEquality() {
        let a = WorldCupTeamsResponse.Standing(wins: 1, losses: 2, draws: 0, points: 3)
        let b = WorldCupTeamsResponse.Standing(wins: 1, losses: 2, draws: 0, points: 3)
        let c = WorldCupTeamsResponse.Standing(wins: 0, losses: 0, draws: 0, points: 0)
        #expect(a == b)
        #expect(a != c)
    }

    private func makeTeam(key: String) -> WorldCupTeamsResponse.Team {
        WorldCupTeamsResponse.Team(
            key: key,
            globalTeamId: nil,
            name: key,
            region: nil,
            colors: nil,
            iconUrl: nil,
            group: nil,
            eliminated: nil,
            standing: nil
        )
    }

    private func decode(_ json: String) throws -> WorldCupTeamsResponse {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WorldCupTeamsResponse.self, from: Data(json.utf8))
    }
}
