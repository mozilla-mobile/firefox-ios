// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import XCTest

@testable import Client

@MainActor
final class TrendingSearchClientTest: XCTestCase, @unchecked Sendable {
    override func setUp() async throws {
        try await super.setUp()
        setupNimbusTrendingSearchesTesting(isEnabled: true)
        clearState()
    }

    override func tearDown() async throws {
        clearState()
        try await super.tearDown()
    }

    func test_getTrendingSearches_withSuccess_returnsExpectedSearches() async throws {
        loadStubResponse(response: sampleResponse, statusCode: 200, error: nil)
        let subject = createSubject()

        let result = try await subject.getTrendingSearches(for: MockTrendingSearchEngine())

        let expectedResult = [
            "funny cat videos",
            "easy pasta recipes",
            "golden retriever tricks",
            "best travel destinations 2025",
            "dogs wearing sunglasses",
        ]
        XCTAssertEqual(result, expectedResult)
    }

    func test_getTrendingSearches_forEngineWithNoTrendingURL_returnsEmptySearches() async throws {
        let subject = createSubject()
        let searches = try await subject.getTrendingSearches(for: MockTrendingSearchEngine(url: nil))
        XCTAssertEqual(searches, [])
    }

    func test_getTrendingSearches_withValidStatusCode_andNilData_returnsError() async throws {
        let subject = createSubject()
        loadStubResponse(response: nil, statusCode: 200, error: nil)

        await assertAsyncThrowsEqual(TrendingSearchClientError.unableToParseJsonData) {
            try await subject.getTrendingSearches(for: MockTrendingSearchEngine())
        }
    }

    func test_getTrendingSearches_withInvalidStatusCode_returnsError() async throws {
        let subject = createSubject()
        loadStubResponse(response: nil, statusCode: 404, error: nil)

        await assertAsyncThrowsEqual(TrendingSearchClientError.invalidHTTPResponse) {
            try await subject.getTrendingSearches(for: MockTrendingSearchEngine())
        }
    }

    func test_getTrendingSearches_withServerError_returnsError() async throws {
        let subject = createSubject()
        enum TestError: Error { case example }
        loadStubResponse(response: nil, statusCode: 200, error: TestError.example)

        await assertAsyncThrows(ofType: NSError.self) {
            try await subject.getTrendingSearches(for: MockTrendingSearchEngine())
        } verify: { err in
            XCTAssertNotNil(err)
        }
    }

    func test_getTrendingSearches_withMalformedJsonResponse_returnsExpectedSearches() async throws {
        loadStubResponse(response: malformedResponse, statusCode: 200, error: nil)
        let subject = createSubject()

        await assertAsyncThrowsEqual(TrendingSearchClientError.unableToParseJsonData) {
            try await subject.getTrendingSearches(for: MockTrendingSearchEngine())
        }
    }

    func test_getTrendingSearches_withEmptyArrayResponse_returnsExpectedSearches() async throws {
        loadStubResponse(response: emptyResponse, statusCode: 200, error: nil)
        let subject = createSubject()

        await assertAsyncThrowsEqual(TrendingSearchClientError.unableToParseJsonData) {
            try await subject.getTrendingSearches(for: MockTrendingSearchEngine())
        }
    }

    // MARK: - Helpers
    private func createSubject() -> TrendingSearchClient {
        let session = makeMockedSession()
        let subject = TrendingSearchClient(session: session)
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
        #"""
        [
          "",
          [
           "funny cat videos",
           "easy pasta recipes",
           "golden retriever tricks",
           "best travel destinations 2025",
           "dogs wearing sunglasses",
           "sleepy kittens",
           "board game night ideas",
           "cozy coffee shops"
          ]
        ]
        """#
    }

    private var emptyResponse: String {
        return #"[]"#
    }

    private var malformedResponse: String {
        return #"[["booo","incorrect"}"#
    }

    private func clearState() {
        URLProtocolStub.removeStub()
    }

    func loadStubResponse(
        response: String?,
        statusCode: Int,
        error: Error?
    ) {
        let testUrl = URL(string: "https://example.com")!
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

private func setupNimbusTrendingSearchesTesting(isEnabled: Bool) {
    FxNimbus.shared.features.trendingSearchesFeature.with { _, _ in
        return TrendingSearchesFeature(
            enabled: isEnabled,
            maxSuggestions: 5
        )
    }
}
