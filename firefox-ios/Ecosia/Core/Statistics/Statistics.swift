// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class Statistics {
    public struct Response: Decodable {
        var results: [Result]
    }
    public struct Result: Decodable {
        var name: String
        var value: String
        var lastUpdated: String?

        enum StatisticName: String, Decodable {
            case treesPlanted = "Total Trees Planted"
            case timePerTree = "Time per tree (seconds)"
            case searchesPerTree = "Searches per tree"
            case activeUsers = "Active Users"
            case eurToUsdMultiplier = "EUR=>USD"
            case investmentPerSecond = "Investments amount per second"
            case totalInvestments = "Total investments amount"
        }

        func statisticName() -> StatisticName? { StatisticName(rawValue: name) }

        func doubleValue() -> Double? { Double(value) }

        func lastUpdatedDate() -> Date? {
            guard let dateString = lastUpdated else { return nil }
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return formatter.date(from: dateString)
        }
    }

    public static let shared = Statistics()
    public internal(set) var treesPlanted = Double(113016418)
    public internal(set) var treesPlantedLastUpdated = Date(timeIntervalSince1970: 1604671200)
    public internal(set) var timePerTree = Double(1.3)
    public internal(set) var searchesPerTree = Double(50)
    public internal(set) var activeUsers = Double(20000000)
    public internal(set) var eurToUsdMultiplier = Double(1.08)
    public internal(set) var investmentPerSecond = Double(0.35)
    public internal(set) var totalInvestments = Double(76776000)
    public internal(set) var totalInvestmentsLastUpdated = Date(timeIntervalSince1970: 1685404800)

    init() { }

    public func fetchAndUpdate(urlSession: URLSessionProtocol = URLSession.shared) async throws {
        let (data, _) = try await urlSession.data(from: EcosiaEnvironment.current.urlProvider.statistics)
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(Response.self, from: data)
        response.results.forEach { statistic in
            switch statistic.statisticName() {
            case .treesPlanted:
                if let value = statistic.doubleValue(),
                    let date = statistic.lastUpdatedDate() {
                    treesPlanted = value
                    treesPlantedLastUpdated = date
                }
            case .timePerTree: timePerTree = statistic.doubleValue() ?? timePerTree
            case .searchesPerTree: searchesPerTree = statistic.doubleValue() ?? searchesPerTree
            case .activeUsers: activeUsers = statistic.doubleValue() ?? activeUsers
            case .eurToUsdMultiplier: eurToUsdMultiplier = statistic.doubleValue() ?? eurToUsdMultiplier
            case .investmentPerSecond: investmentPerSecond = statistic.doubleValue() ?? investmentPerSecond
            case .totalInvestments:
                if let value = statistic.doubleValue(),
                    let date = statistic.lastUpdatedDate() {
                    totalInvestments = value
                    totalInvestmentsLastUpdated = date
                }
            case nil: break
            }
        }
    }
}
