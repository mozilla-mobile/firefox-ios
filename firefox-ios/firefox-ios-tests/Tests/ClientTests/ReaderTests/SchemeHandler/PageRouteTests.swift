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
        // Registers MockThemeManager + other dependencies into AppContainer. PageRoute's
        // render path may call ReaderModeTheme.preferredTheme(window:), which resolves a
        // ThemeManager from the container. Async setUp is required so this @MainActor
        // class can override XCTestCase.setUp without losing its actor isolation.
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - URL parameter validation

    func test_handle_missingURLParam_throwsMissingParam() async {
        let subject = makeSubject(extractor: failOnCall)
        let request = URL(string: ReaderModeSchemeHandler.baseURL)!
        let components = URLComponents(url: request, resolvingAgainstBaseURL: false)!

        do {
            _ = try await subject.handle(url: request, components: components)
            XCTFail("Expected missingParam error")
        } catch let error as TinyRouterError {
            XCTAssertEqual(error, .missingParam("url"))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_handle_invalidURLParam_throwsInvalidParam() async {
        let subject = makeSubject(extractor: failOnCall)
        let request = URL(string: "\(ReaderModeSchemeHandler.baseURL)?url=ftp%3A%2F%2Fnope")!
        let components = URLComponents(url: request, resolvingAgainstBaseURL: false)!

        do {
            _ = try await subject.handle(url: request, components: components)
            XCTFail("Expected invalidParam error")
        } catch let error as TinyRouterError {
            if case .invalidParam(let name, _) = error {
                XCTAssertEqual(name, "url")
            } else {
                XCTFail("Expected invalidParam, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - Cache hit

    func test_handle_cacheHit_returns200WithReaderHTML() async throws {
        let cache = MockReaderModeCache([articleURL: Self.fixtureReadabilityResult()])
        let subject = makeSubject(cache: cache, extractor: failOnCall)
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)!

        let reply = try await subject.handle(url: requestURL, components: components)

        let unwrapped = try XCTUnwrap(reply)
        let http = try XCTUnwrap(unwrapped.httpResponse)
        XCTAssertEqual(http.statusCode, 200)
        XCTAssertFalse(unwrapped.body.isEmpty)
    }

    func test_handle_cacheHit_includesCorrectHeaders() async throws {
        let cache = MockReaderModeCache([articleURL: Self.fixtureReadabilityResult()])
        let subject = makeSubject(cache: cache, extractor: failOnCall)
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)!

        let reply = try await subject.handle(url: requestURL, components: components)
        let http = try XCTUnwrap(reply?.httpResponse)

        XCTAssertEqual(http.value(forHTTPHeaderField: "Content-Type"), "text/html; charset=utf-8")
        let csp = try XCTUnwrap(http.value(forHTTPHeaderField: "Content-Security-Policy"))
        XCTAssertTrue(csp.contains("default-src 'none'"))
        XCTAssertTrue(csp.contains("img-src *"))
        XCTAssertTrue(csp.contains("readermode://app"))
    }

    // MARK: - Cache miss

    func test_handle_cacheMiss_invokesExtractorAndReturns200() async throws {
        let cache = MockReaderModeCache()
        let extractorCalled = expectation(description: "extractor invoked")
        let stubResult = Self.fixtureReadabilityResult()
        // Pull `articleURL` into a local before the closure. The `Extractor` typealias
        // is `@Sendable`, so the closure cannot capture `self` (XCTestCase isn't Sendable).
        let expectedArticleURL = articleURL
        let extractor: PageRoute.Extractor = { url, _, _ in
            XCTAssertEqual(url, expectedArticleURL)
            extractorCalled.fulfill()
            return stubResult
        }
        let subject = makeSubject(cache: cache, extractor: extractor)
        let components = URLComponents(url: requestURL, resolvingAgainstBaseURL: false)!

        let reply = try await subject.handle(url: requestURL, components: components)
        await fulfillment(of: [extractorCalled], timeout: 1.0)

        let http = try XCTUnwrap(reply?.httpResponse)
        XCTAssertEqual(http.statusCode, 200)
    }

    // MARK: - Failure fallback

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

        // Failure path returns a recovery page, not an HTTP error, so the link is reachable.
        XCTAssertEqual(http.statusCode, 200)
        XCTAssertEqual(http.value(forHTTPHeaderField: "Content-Type"), "text/html; charset=utf-8")

        let bodyString = try XCTUnwrap(String(data: unwrapped.body, encoding: .utf8))
        // The recovery page must link back to the original article so the user can recover.
        XCTAssertTrue(
            bodyString.contains("href=\"https://example.com/article\""),
            "Expected original-article link in body, got: \(bodyString)"
        )
    }

    // MARK: - Helpers

    private func makeSubject(
        cache: ReaderModeCache = MockReaderModeCache(),
        profile: Profile = MockProfile(),
        extractor: @escaping PageRoute.Extractor
    ) -> PageRoute {
        return PageRoute(cache: cache, profile: profile, extractor: extractor)
    }

    /// Default extractor stub for tests that must not reach the extraction path.
    /// If the route accidentally calls into extraction, the test fails loudly.
    private let failOnCall: PageRoute.Extractor = { _, _, _ in
        XCTFail("Extractor was called but the test expected the cache-hit / validation path")
        throw ReadabilityServiceError.noResult
    }

    /// A fixture `ReadabilityResult` constructed via its `init?(object:)` path. Tests use this
    /// to seed the cache for cache-hit assertions and to stub the extractor return.
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
