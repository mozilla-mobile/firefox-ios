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

    func test_start_realBundleFileNotOnAllowlist_rejectedByReaderFileRoute() {
        // Info.plist exists in Bundle.main but isn't on ReaderFileRoute's allowlist.
        // Verifies that the allowlist blocks access to arbitrary bundle resources.
        let task = MockWKURLSchemeTask(
            request: URLRequest(url: URL(string: "readermode://app/Info.plist")!)
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
        XCTAssertEqual(error, .pathNotAllowed(path: "Info.plist"))
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

    func test_start_validURL_passesValidationAndReachesRoute() {
        let url = "\(ReaderModeSchemeHandler.baseURL)?url=https%3A%2F%2Fexample.com%2Farticle"
        let task = MockWKURLSchemeTask(
            request: URLRequest(url: URL(string: url)!)
        )
        let webView = makeWebView()
        let failExpectation = expectation(description: "onFail called")
        task.onFail = { failExpectation.fulfill() }

        subject.webView(webView, start: task)
        wait(for: [failExpectation], timeout: 1.0)

        // PageRoute always throws an error in this PR,
        // but if the request passed scheme/host validation then it wasn't rejected as
        // unsupportedScheme, unsupportedHost, or badURL
        // TODO: FXIOS-15783 Update this test once PageRoute is properly implemented
        let error = task.failedErrors.first as? TinyRouterError
        XCTAssertNotEqual(error, .unsupportedScheme(expected: ReaderModeSchemeHandler.scheme, found: "readermode"))
        XCTAssertNotEqual(error, .unsupportedHost(expected: ReaderModeSchemeHandler.host, found: "app"))
        XCTAssertNotEqual(error, .badURL)
    }

    // MARK: - ReaderFileRoute allowlist

    func test_readerFileRoute_allowedFiles_serveSuccessfully() throws {
        let route = ReaderFileRoute()
        let allowedPaths = [
            "reader-mode/styles/Reader.css",
            "reader-mode/fonts/NewYorkMedium-Regular.otf",
            "reader-mode/fonts/NewYorkMedium-Bold.otf",
            "reader-mode/fonts/NewYorkMedium-RegularItalic.otf",
            "reader-mode/fonts/NewYorkMedium-BoldItalic.otf",
        ]

        for path in allowedPaths {
            let url = URL(string: "readermode://app/\(path)")!
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
            let reply = try route.handle(url: url, components: components)
            let unwrapped = try XCTUnwrap(reply, "Expected a reply for \(path)")
            XCTAssertFalse(unwrapped.body.isEmpty, "Expected non-empty body for \(path)")
        }
    }

    // MARK: - Helpers

    private func makeWebView() -> WKWebView {
        WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    }
}
