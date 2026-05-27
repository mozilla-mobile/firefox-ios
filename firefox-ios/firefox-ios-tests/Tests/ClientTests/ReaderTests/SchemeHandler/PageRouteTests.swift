// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import WebEngine

@MainActor
final class PageRouteTests: XCTestCase {
    private let articleURL = URL(string: "https://example.com/article")!

    private var requestURL: URL {
        URL(string: "\(ReaderModeSchemeHandler.baseURL)?url=https%3A%2F%2Fexample.com%2Farticle")!
    }

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - URL parameter validation

    func test_handle_missingURLParam_throwsMissingParam() async {
        let subject = makeSubject(extractor: noOpExtractor)
        let request = URL(string: ReaderModeSchemeHandler.baseURL)!
        let components = URLComponents(url: request, resolvingAgainstBaseURL: false)!

        do {
            _ = try await subject.handle(url: request, components: components)
            XCTFail("Expected missingParam error")
        } catch {
            XCTAssertEqual(error as? TinyRouterError, .missingParam("url"))
        }
    }

    func test_handle_invalidURLParam_throwsInvalidParam() async {
        let subject = makeSubject(extractor: noOpExtractor)
        let request = URL(string: "\(ReaderModeSchemeHandler.baseURL)?url=ftp%3A%2F%2Fnope")!
        let components = URLComponents(url: request, resolvingAgainstBaseURL: false)!

        do {
            _ = try await subject.handle(url: request, components: components)
            XCTFail("Expected invalidParam error")
        } catch {
            if case .invalidParam(let name, _) = error as? TinyRouterError {
                XCTAssertEqual(name, "url")
            } else {
                XCTFail("Expected invalidParam, got: \(error)")
            }
        }
    }

    func test_handle_validURLParam_passesCorrectURLToExtractor() async throws {
        let expectedArticleURL = articleURL
        let extractor: PageRoute.Extractor = { url, _, _ in
            XCTAssertEqual(url, expectedArticleURL)
            return await Self.fixtureReadabilityResult()
        }
        let subject = makeSubject(extractor: extractor)
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)!

        _ = try await subject.handle(url: requestURL, components: components)
    }

    // MARK: - Cache hit

    func test_handle_cacheHit_returns200WithReaderHTML() async throws {
        let cache = MockReaderModeCache([articleURL: Self.fixtureReadabilityResult()])
        let subject = makeSubject(cache: cache, extractor: noOpExtractor)
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)!

        let reply = try await subject.handle(url: requestURL, components: components)

        let unwrapped = try XCTUnwrap(reply)
        let http = try XCTUnwrap(unwrapped.httpResponse)
        XCTAssertEqual(http.statusCode, 200)
        XCTAssertFalse(unwrapped.body.isEmpty)
    }

    func test_handle_cacheHit_includesCorrectHeaders() async throws {
        let cache = MockReaderModeCache([articleURL: Self.fixtureReadabilityResult()])
        let subject = makeSubject(cache: cache, extractor: noOpExtractor)
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)!

        let reply = try await subject.handle(url: requestURL, components: components)
        let http = try XCTUnwrap(reply?.httpResponse)

        XCTAssertEqual(http.value(forHTTPHeaderField: "Content-Type"), "text/html; charset=utf-8")
        let csp = try XCTUnwrap(http.value(forHTTPHeaderField: "Content-Security-Policy"))
        XCTAssertTrue(csp.contains("default-src 'none'"))
        XCTAssertTrue(csp.contains("img-src *"))
        XCTAssertTrue(csp.contains("readermode://app"))
    }

    // MARK: - Cache miss (uses test-only extractor override — see PageRoute.Extractor)

    func test_handle_cacheMiss_invokesExtractorAndReturns200() async throws {
        let cache = MockReaderModeCache()
        let extractorCalled = expectation(description: "extractor invoked")
        let expectedArticleURL = articleURL
        let extractor: PageRoute.Extractor = { url, _, _ in
            XCTAssertEqual(url, expectedArticleURL)
            extractorCalled.fulfill()
            return await Self.fixtureReadabilityResult()
        }
        let subject = makeSubject(cache: cache, extractor: extractor)
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)!

        let reply = try await subject.handle(url: requestURL, components: components)
        await fulfillment(of: [extractorCalled], timeout: 1.0)

        let http = try XCTUnwrap(reply?.httpResponse)
        XCTAssertEqual(http.statusCode, 200)
    }

    // MARK: - Extraction failure

    func test_handle_extractorFails_returnsErrorPageWithLoadOriginalLink() async throws {
        let cache = MockReaderModeCache()
        let extractor: PageRoute.Extractor = { _, _, _ in
            throw ReadabilityServiceError.timeout
        }
        let subject = makeSubject(cache: cache, extractor: extractor)
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)!

        let reply = try await subject.handle(url: requestURL, components: components)
        let unwrapped = try XCTUnwrap(reply)
        let http = try XCTUnwrap(unwrapped.httpResponse)

        XCTAssertEqual(http.statusCode, 200)
        XCTAssertEqual(http.value(forHTTPHeaderField: "Content-Type"), "text/html; charset=utf-8")

        let bodyString = try XCTUnwrap(String(data: unwrapped.body, encoding: .utf8))
        XCTAssertTrue(
            bodyString.contains("href=\"https://example.com/article\""),
            "Expected original-article link in body, got: \(bodyString)"
        )
    }

    // MARK: - Response builders

    func test_buildSuccessReply_includesCSPHeader() throws {
        let subject = makeSubject(extractor: noOpExtractor)
        let url = requestURL
        let body = "<html>test</html>".data(using: .utf8)!

        let reply = try subject.buildSuccessReply(url: url, body: body)
        let http = try XCTUnwrap(reply.httpResponse)

        XCTAssertEqual(http.statusCode, 200)
        let csp = try XCTUnwrap(http.value(forHTTPHeaderField: "Content-Security-Policy"))
        XCTAssertTrue(csp.contains("default-src 'none'"))
        XCTAssertTrue(csp.contains("style-src 'unsafe-inline' readermode://app"))
        XCTAssertTrue(csp.contains("font-src readermode://app"))
    }

    func test_buildErrorReply_containsOriginalLink() throws {
        let subject = makeSubject(extractor: noOpExtractor)
        let reply = try subject.buildErrorReply(url: requestURL, originalURL: articleURL)
        let http = try XCTUnwrap(reply.httpResponse)

        XCTAssertEqual(http.statusCode, 200)
        XCTAssertEqual(http.value(forHTTPHeaderField: "Content-Type"), "text/html; charset=utf-8")

        let bodyString = try XCTUnwrap(String(data: reply.body, encoding: .utf8))
        XCTAssertTrue(bodyString.contains("href=\"https://example.com/article\""))
    }

    // MARK: - Helpers

    private func makeSubject(
        cache: ReaderModeCache = MockReaderModeCache(),
        profile: Profile = MockProfile(),
        extractor: @escaping PageRoute.Extractor
    ) -> PageRoute {
        return PageRoute(cache: cache, profile: profile, extractor: extractor)
    }

    // Fails the test if the extractor is called — used for tests that should
    // never reach extraction (validation, cache-hit, response builder tests).
    private let noOpExtractor: PageRoute.Extractor = { _, _, _ in
        XCTFail("Extractor should not have been called")
        throw ReadabilityServiceError.noResult
    }

    static func fixtureReadabilityResult() -> ReadabilityResult {
        let dict: NSDictionary = [
            "content": "<p>Fixture article body</p>",
            "textContent": "Fixture article body",
            "title": "Fixture Article",
            "credits": "Fixture Author",
            "excerpt": "Fixture excerpt",
            "byline": "Fixture Author",
            "length": 21,
            "language": "en",
            "siteName": "example.com",
            "dir": "ltr",
            "jsonld": ""
        ]
        return ReadabilityResult(object: dict)!
    }
}
