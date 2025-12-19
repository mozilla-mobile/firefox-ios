// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public final class FinancialReports {
    public struct Report: Decodable, Equatable {
        public internal(set) var totalIncome: Double
        public internal(set) var numberOfTreesFinanced: Double
    }

    public static let shared = FinancialReports()
    public internal(set) var latestMonth: Date = .init(timeIntervalSince1970: 1685577600)
    public internal(set) var latestReport: Report = .init(totalIncome: 3206010,
                                                          numberOfTreesFinanced: 961642)

    public var localizedMonthAndYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone(abbreviation: "GMT")

        let localizedMonth = formatter.string(from: latestMonth)
        return localizedMonth
    }

    init() { }

    public func fetchAndUpdate(urlSession: URLSessionProtocol = URLSession.shared) async throws {
        let (data, _) = try await urlSession.data(from: EcosiaEnvironment.current.urlProvider.financialReportsData)

        let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-M"
        dateFormatter.timeZone = .init(abbreviation: "UTC")
        let months = response?.keys.compactMap { dateFormatter.date(from: $0) } ?? []
        let latestMonth = months.reduce(Date.distantPast) { $0 > $1 ? $0 : $1 }
        let latestKey = dateFormatter.string(from: latestMonth)
        let latestObject = response?[latestKey] as? [String: Any] ?? [:]

        self.latestMonth = latestMonth
        self.latestReport = try JSONDecoder().decode(Report.self, from: JSONSerialization.data(withJSONObject: latestObject))
    }
}
