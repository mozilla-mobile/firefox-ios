// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

class TrendingSearchClientTest: XCTestCase {
    func test_getTrendingSearches_withSuccess_returnsExpectedSearches() async throws {
        let subject = createSubject()

        loadStubResponse(response: sampleResponse, statusCode: 200, error: nil)

        let result = try await subject.getTrendingSearches()

        XCTAssertEqual(result, ["cats", "dogs"])
    }

    func test_getTrendingSearches_withSuccessAndEmptyData_returnsEmptySearches() async throws {
        let subject = createSubject()
        loadStubResponse(response: nil, statusCode: 200, error: nil)

        do {
            let searches = try await subject.getTrendingSearches()
            XCTFail("Expected error to be thrown, but receives \(searches)")
        } catch {
            XCTAssertThrowsError(error)
        }
    }

    func test_getTrendingSearches_withError_returnsEmptySearches() async throws {
        let subject = createSubject()
        enum TestError: Error { case example }
        loadStubResponse(response: nil, statusCode: 404, error: TestError.example)

        do {
            let searches = try await subject.getTrendingSearches()
            XCTFail("Expected error to be thrown, but receives \(searches)")
        } catch {
            XCTAssertThrowsError(error)
        }
    }

    func test_getTrendingSearches_forEngineWithNoTrendingURL_returnsEmptySearches() async throws {
        let subject = createSubject(for: MockTrendingSearchEngine(url: nil))
        let searches = try await subject.getTrendingSearches()
//        XCTAssertEqual(searches, [])
    }

    private func createSubject(
        for searchEngine: TrendingSearchEngine = MockTrendingSearchEngine()
    ) -> TrendingSearchClient {
        let session = makeMockedSession()
        let subject = TrendingSearchClient(searchEngine: searchEngine, session: session)
        trackForMemoryLeaks(subject)
        return subject
    }

    private func makeMockedSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeralMPTCP
        config.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: config)
    }

    // MARK: URLProtocolStub
    private var sampleResponse: String {
        return "['',['cats', 'dogs'],[],[],{}]"
    }

    private func clearState() {
        URLProtocolStub.removeStub()
    }

    func loadStubResponse(
        response: String?,
        statusCode: Int,
        error: Error?
    ) {
        let testUrl = URL(string: "https://mozilla.com")!
        let mockData = response?.data(using: .utf8)
        let response = HTTPURLResponse(
            url: testUrl,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )

        URLProtocolStub.stub(
            data: mockData,
            response: response,
            error: error
        )
    }
}
