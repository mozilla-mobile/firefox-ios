// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared
@testable import Client

final class DefaultRecentSearchProviderTests: XCTestCase {
    var mockHistoryStorage: MockHistoryHandler!

    override func setUp() {
        super.setUp()
        mockHistoryStorage = MockHistoryHandler()
    }

    override func tearDown() {
        mockHistoryStorage = nil
        super.tearDown()
    }

    func test_addRecentSearch_withMultipleCalls_returnsExpectedRecentSearches() {
        let sut = createSubject(for: "engineA")

        sut.addRecentSearch("swift enums", url: "https://example.com")
        sut.addRecentSearch("combine", url: "https://example.com")
        sut.addRecentSearch("async await", url: "https://example.com")

        XCTAssertEqual(mockHistoryStorage.noteHistoryMetadataCallCount, 3)
        XCTAssertEqual(mockHistoryStorage.searchTermList.reversed(), ["async await", "combine", "swift enums"])
    }

    func test_addRecentSearch_withWhitespaces_trimsAndReturnsValidSearchTerm() {
        let sut = createSubject(for: "engineA")

        sut.addRecentSearch("   swift  ", url: "https://example.com")
        sut.addRecentSearch("   ", url: "https://example.com")
        sut.addRecentSearch("", url: "https://example.com")

        XCTAssertEqual(mockHistoryStorage.noteHistoryMetadataCallCount, 1)
        XCTAssertEqual(mockHistoryStorage.searchTermList.reversed(), ["swift"])
    }

    func test_addRecentSearch_withCaseSensitivity_returnsLowercasedSearchTerm() {
        let sut = createSubject(for: "engineA")

        sut.addRecentSearch("SWIFT", url: "https://example.com")

        XCTAssertEqual(mockHistoryStorage.noteHistoryMetadataCallCount, 1)
        XCTAssertEqual(mockHistoryStorage.searchTermList.reversed(), ["swift"])
    }

    func test_loadRecentSearches_withSuccess_returnsExpectedList() {
        let sut = createSubject(for: "engineA")
        let expectation = XCTestExpectation(description: "Recent searches have been fetched successfully")

        sut.loadRecentSearches { results in
            XCTAssertEqual(results.count, 2)
            XCTAssertEqual(results.first, "search term 1")
            XCTAssertEqual(results.last, "search term 2")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(mockHistoryStorage.getMostRecentHistoryMetadataCallCount, 1)
    }

    func test_loadRecentSearches_withError_returnsEmptyList() {
        enum TestError: Error { case example }
        mockHistoryStorage.result = .failure(TestError.example)

        let sut = createSubject(for: "engineA")
        let expectation = XCTestExpectation(description: "Recent searches have been fetched successfully")

        sut.loadRecentSearches { results in
            XCTAssertEqual(results, [])
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        XCTAssertEqual(mockHistoryStorage.getMostRecentHistoryMetadataCallCount, 1)
    }

    func createSubject(for searchEngineID: String) -> RecentSearchProvider {
        let subject = DefaultRecentSearchProvider(
            historyStorage: mockHistoryStorage
        )
        return subject
    }
}
