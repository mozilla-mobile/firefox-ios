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

        XCTAssertTrue(task.receivedResponses.isEmpty)
        XCTAssertTrue(task.receivedBodies.isEmpty)
        XCTAssertEqual(task.finishCallCount, 0)
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

        XCTAssertTrue(task.receivedResponses.isEmpty)
        XCTAssertTrue(task.receivedBodies.isEmpty)
        XCTAssertEqual(task.finishCallCount, 0)
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

        XCTAssertTrue(task.receivedBodies.isEmpty)
        XCTAssertEqual(task.finishCallCount, 0)
        XCTAssertEqual(task.failedErrors.count, 1)
        XCTAssertTrue(task.receivedResponses.isEmpty)
        // `StaticFileRoute` throws `.badURL` on Bundle.main miss; the handler wraps
        // unrecognized errors as `.unknown`, but TinyRouterError passes through directly.
        let error = task.failedErrors.first as? TinyRouterError
        XCTAssertEqual(error, .badURL)
    }

    func test_start_incorrectURLComponents_failsWithExpectedErrors() {
        let webView = makeWebView()

        // Wrong scheme
        let schemeTask = MockWKURLSchemeTask(
            request: URLRequest(url: URL(string: "https://app/page?url=https%3A%2F%2Fexample.com")!)
        )
        let schemeExpectation = expectation(description: "wrong scheme fails")
        schemeTask.onFail = { schemeExpectation.fulfill() }
        subject.webView(webView, start: schemeTask)
        wait(for: [schemeExpectation], timeout: 1.0)
        XCTAssertEqual(
            schemeTask.failedErrors.first as? TinyRouterError,
            .unsupportedScheme(expected: "readermode", found: "https")
        )

        // Wrong host
        let hostTask = MockWKURLSchemeTask(
            request: URLRequest(url: URL(string: "readermode://badhost/page?url=https%3A%2F%2Fexample.com")!)
        )
        let hostExpectation = expectation(description: "wrong host fails")
        hostTask.onFail = { hostExpectation.fulfill() }
        subject.webView(webView, start: hostTask)
        wait(for: [hostExpectation], timeout: 1.0)
        XCTAssertEqual(
            hostTask.failedErrors.first as? TinyRouterError,
            .unsupportedHost(expected: "app", found: "badhost")
        )

        // Wrong path
        let pathTask = MockWKURLSchemeTask(
            request: URLRequest(url: URL(string: "readermode://app/unknown")!)
        )
        let pathExpectation = expectation(description: "wrong path fails")
        pathTask.onFail = { pathExpectation.fulfill() }
        subject.webView(webView, start: pathTask)
        wait(for: [pathExpectation], timeout: 1.0)
        let pathError = pathTask.failedErrors.first as? TinyRouterError
        XCTAssertNotNil(pathError)

        // Missing url query param
        let paramTask = MockWKURLSchemeTask(
            request: URLRequest(url: URL(string: "readermode://app/page")!)
        )
        let paramExpectation = expectation(description: "missing param fails")
        paramTask.onFail = { paramExpectation.fulfill() }
        subject.webView(webView, start: paramTask)
        wait(for: [paramExpectation], timeout: 1.0)
        XCTAssertEqual(
            paramTask.failedErrors.first as? TinyRouterError,
            .missingParam("url")
        )
    }

    // MARK: - Helpers

    private func makeWebView() -> WKWebView {
        WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    }
}
