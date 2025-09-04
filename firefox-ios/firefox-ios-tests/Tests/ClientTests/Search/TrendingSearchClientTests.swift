// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage
import XCTest

@testable import Client

class TrendingSearchClientTest: XCTestCase {
    func test_getTrendingSearches_withSuccess_returnsExpectedSearches() async throws {
        let searchEngine = OpenSearchEngine(
            engineID: "Bing",
            shortName: "bing",
            telemetrySuffix: nil,
            image: UIImage(),
            searchTemplate: "some link",
            suggestTemplate: nil,
            trendingTemplate: "https://www.bing.com/osjson.aspx",
            isCustomEngine: true
        )
        let subject = createSubject(for: searchEngine)
        let searches = try await subject.getTrendingSearches()
        XCTAssertEqual(searches, [])
    }

    func test_getTrendingSearches_withError_returnsEmptySearches() async throws {
        let subject = createSubject(for: OpenSearchEngineTests.generateOpenSearchEngine(
            type: .wikipedia,
            withImage: UIImage()
        ))
        do {
            let searches = try await subject.getTrendingSearches()
            XCTFail("Expected error to be thrown, but receives \(searches)")
        } catch {
            XCTAssertThrowsError(error)
        }
    }

    func test_getTrendingSearches_forEngineWithNoTrendingURL_returnsEmptySearches() async throws {
        let subject = createSubject(for: OpenSearchEngineTests.generateOpenSearchEngine(
            type: .wikipedia,
            withImage: UIImage()
        ))
        let searches = try await subject.getTrendingSearches()
        XCTAssertEqual(searches, [])
    }

    func createSubject(for searchEngine: OpenSearchEngine) -> TrendingSearchClient {
        let subject = TrendingSearchClient(searchEngine: searchEngine)
        trackForMemoryLeaks(subject)
        return subject
    }
}
