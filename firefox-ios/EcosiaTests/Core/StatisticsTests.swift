// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class StatisticsTests: XCTestCase {
    private var statistics: Statistics!
    private var mockURLSession: MockURLSessionProtocol!

    override func setUp() {
        statistics = Statistics.shared
        mockURLSession = MockURLSessionProtocol()
    }

    func testFetchAndUpdate() async throws {
        mockURLSession.data = Data("""
            {
                "results": [
                    {"name": "Total Trees Planted", "value": "123456789", "last_updated": "2023-08-01T11:40:00.000000Z"},
                    {"name": "Time per tree (seconds)", "value": "0.8"},
                    {"name": "Searches per tree", "value": "20"},
                    {"name": "Active Users", "value": "80000000"},
                    {"name": "EUR=>USD", "value": "1.5"},
                    {"name": "Some other name", "value": "123"},
                    {"name": "Investments amount per second", "value": "0.423", "last_updated": null},
                    {"name": "Total investments amount", "value": "2345678", "last_updated": "2023-07-30T00:00:00.000000Z"}
                ]
            }
        """.utf8)

        try await statistics.fetchAndUpdate(urlSession: mockURLSession)

        XCTAssertEqual(statistics.treesPlanted, 123456789)
        XCTAssertEqual(statistics.treesPlantedLastUpdated, Date(timeIntervalSince1970: 1690890000))
        XCTAssertEqual(statistics.timePerTree, 0.8)
        XCTAssertEqual(statistics.searchesPerTree, 20)
        XCTAssertEqual(statistics.activeUsers, 80000000)
        XCTAssertEqual(statistics.eurToUsdMultiplier, 1.5)
        XCTAssertEqual(statistics.investmentPerSecond, 0.423)
        XCTAssertEqual(statistics.totalInvestments, 2345678)
        XCTAssertEqual(statistics.totalInvestmentsLastUpdated, Date(timeIntervalSince1970: 1690675200))
    }
}
