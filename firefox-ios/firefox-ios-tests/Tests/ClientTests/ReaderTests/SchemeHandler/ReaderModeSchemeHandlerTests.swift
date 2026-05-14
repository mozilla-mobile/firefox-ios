// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import WebKit

@MainActor
final class ReaderModeSchemeHandlerTests: XCTestCase {
    private var subject: ReaderModeSchemeHandler!

    override func setUp() async throws {
        try await super.setUp()
        // The validation tests in this file fail before reaching the route, so they don't
        // strictly need the AppContainer mocks. Bootstrapping here anyway keeps the file
        // consistent with PageRouteTests and avoids surprises when new tests are added
        // that do touch the render path.
        DependencyHelperMock().bootstrapDependencies()
        subject = ReaderModeSchemeHandler(profile: MockProfile())
    }

    override func tearDown() async throws {
        subject = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - Request validation

    func test_start_wrongScheme_failsWithUnsupportedScheme() {
        let task = MockWKURLSchemeTask(
            request: URLRequest(url: URL(string: "http://app/page")!)
        )
        let webView = makeWebView()
        let failExpectation = expectation(description: "onFail called")
        task.onFail = { failExpectation.fulfill() }

        subject.webView(webView, start: task)
        wait(for: [failExpectation], timeout: 1.0)

        XCTAssertTrue(task.receivedResponses.isEmpty)
        XCTAssertTrue(task.receivedBodies.isEmpty)
        XCTAssertEqual(task.finishCallCount, 0)
        XCTAssertEqual(task.failedErrors.count, 1)

        let error = task.failedErrors.first as? TinyRouterError
        XCTAssertEqual(error, .unsupportedScheme(expected: ReaderModeSchemeHandler.scheme, found: "http"))
    }

    func test_start_wrongHost_failsWithUnsupportedHost() {
        let task = MockWKURLSchemeTask(
            request: URLRequest(url: URL(string: "readermode://wronghost/page")!)
        )
        let webView = makeWebView()
        let failExpectation = expectation(description: "onFail called")
        task.onFail = { failExpectation.fulfill() }

        subject.webView(webView, start: task)
        wait(for: [failExpectation], timeout: 1.0)

        XCTAssertEqual(task.failedErrors.count, 1)
        let error = task.failedErrors.first as? TinyRouterError
        XCTAssertEqual(error, .unsupportedHost(expected: ReaderModeSchemeHandler.host, found: "wronghost"))
    }

    func test_start_nilURL_failsWithBadURL() {
        var request = URLRequest(url: URL(string: ReaderModeSchemeHandler.baseURL)!)
        request.url = nil
        let task = MockWKURLSchemeTask(request: request)
        let webView = makeWebView()
        let failExpectation = expectation(description: "onFail called")
        task.onFail = { failExpectation.fulfill() }

        subject.webView(webView, start: task)
        wait(for: [failExpectation], timeout: 1.0)

        XCTAssertEqual(task.failedErrors.count, 1)
        XCTAssertEqual(task.failedErrors.first as? TinyRouterError, .badURL)
    }

    // MARK: - Routing

    func test_start_unknownBundleResource_failsViaDefaultRoute() {
        // Path doesn't match the "page" prefix, so it falls through to the default route
        // (`StaticFileRoute`), which attempts `Bundle.main.url(forResource:withExtension:)`
        // for a resource that does not exist and throws `TinyRouterError.badURL`.
        let task = MockWKURLSchemeTask(
            request: URLRequest(url: URL(string: "readermode://app/nonexistent.xyz")!)
        )
        let webView = makeWebView()
        let failExpectation = expectation(description: "onFail called")
        task.onFail = { failExpectation.fulfill() }

        subject.webView(webView, start: task)
        wait(for: [failExpectation], timeout: 1.0)

        XCTAssertTrue(task.receivedResponses.isEmpty)
        XCTAssertEqual(task.failedErrors.count, 1)
        // `StaticFileRoute` throws `.badURL` on Bundle.main miss; the handler wraps
        // unrecognized errors as `.unknown`, but TinyRouterError passes through directly.
        let error = task.failedErrors.first as? TinyRouterError
        XCTAssertEqual(error, .badURL)
    }

    // MARK: - Helpers

    private func makeWebView() -> WKWebView {
        WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    }
}
