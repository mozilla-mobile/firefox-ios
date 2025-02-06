// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Ecosia
import XCTest

final class FinancialReportsTests: XCTestCase {
    private var financialReports: FinancialReports!
    private var mockURLSession: MockURLSessionProtocol!

    override func setUp() {
        financialReports = FinancialReports.shared
        mockURLSession = MockURLSessionProtocol()
    }

    func testFetchAndUpdate() async throws {
        mockURLSession.data = Data("""
            {
                "2023-8": { "totalIncome": 456, "numberOfTreesFinanced": 11 },
                "2023-7": { "totalIncome": 123, "numberOfTreesFinanced": 10 }
            }
        """.utf8)

        try await financialReports.fetchAndUpdate(urlSession: mockURLSession)

        XCTAssertEqual(financialReports.latestMonth, Date(timeIntervalSince1970: 1690848000))
        XCTAssertEqual(financialReports.latestReport,
                       FinancialReports.Report(totalIncome: 456,
                                               numberOfTreesFinanced: 11))
    }

    func testLocalizedMonthAndYear() async throws {
        mockURLSession.data = Data("""
            {
                "2021-5": { "totalIncome": 1, "numberOfTreesFinanced": 1 }
            }
        """.utf8)

        try await financialReports.fetchAndUpdate(urlSession: mockURLSession)

        XCTAssertEqual(financialReports.localizedMonthAndYear, "May 2021")
    }
}
