// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import WebKit

@MainActor
final class TranslationsSchemeHandlerTests: XCTestCase {
    func test_start_validModelsRequest_sendsResponseAndFinishes() {
        let subject = createSubject()
        let url = URL(string: "translations://app/translator")!
        let task = MockWKURLSchemeTask(request: URLRequest(url: url))
        let webView = makeWebView()

        let finishExpectation = expectation(description: "onFinish completion called")
        let responseExpectation = expectation(description: "onResponse completion called")
        let bodyExpectation = expectation(description: "onBody completion called")

        task.onFinish = {
            finishExpectation.fulfill()
        }

        task.onResponse = {
            responseExpectation.fulfill()
        }

        task.onBody = {
            bodyExpectation.fulfill()
        }

        subject.webView(webView, start: task)

        wait(for: [finishExpectation, responseExpectation, bodyExpectation], timeout: 1.0)

        XCTAssertTrue(task.failedErrors.isEmpty)
        XCTAssertEqual(task.receivedResponses.count, 1)
        XCTAssertEqual(task.receivedBodies.count, 1)
        XCTAssertEqual(task.finishCallCount, 1)

        let http = task.receivedResponses.first as? HTTPURLResponse
        XCTAssertNotNil(http)
        XCTAssertEqual(http?.statusCode, 200)

        XCTAssertEqual(task.receivedBodies.first, Data([1, 2, 3]))
    }

    func test_start_wrongScheme_failsWithUnsupportedScheme() {
        let subject = createSubject()
        let url = URL(string: "http://app/models")!
        let task = MockWKURLSchemeTask(request: URLRequest(url: url))
        let webView = makeWebView()

        let expectation = expectation(description: "onFail completion called")

        task.onFail = {
            expectation.fulfill()
        }

        subject.webView(webView, start: task)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(task.receivedResponses.isEmpty)
        XCTAssertTrue(task.receivedBodies.isEmpty)
        XCTAssertEqual(task.finishCallCount, 0)
        XCTAssertEqual(task.failedErrors.count, 1)

        let error = task.failedErrors.first as? TinyRouterError
        XCTAssertEqual(
            error,
            .unsupportedScheme(
                expected: TranslationsSchemeHandler.scheme,
                found: "http"
            )
        )
    }

    func test_start_wrongHost_failsWithUnsupportedHost() {
        let subject = createSubject()
        let url = URL(string: "translations://other/models")!
        let task = MockWKURLSchemeTask(request: URLRequest(url: url))
        let webView = makeWebView()

        let expectation = expectation(description: "onFail completion called")

        task.onFail = {
            expectation.fulfill()
        }

        subject.webView(webView, start: task)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(task.receivedResponses.isEmpty)
        XCTAssertTrue(task.receivedBodies.isEmpty)
        XCTAssertEqual(task.finishCallCount, 0)
        XCTAssertEqual(task.failedErrors.count, 1)

        let error = task.failedErrors.first as? TinyRouterError
        XCTAssertEqual(
            error,
            .unsupportedHost(
                expected: TranslationsSchemeHandler.host,
                found: "other"
            )
        )
    }

    func test_start_badURL_failsWithBadURL() {
        let subject = createSubject()
        let webView = makeWebView()

        // Start from a valid request, then nuke the URL.
        var request = URLRequest(url: URL(string: "translations://app/translator")!)
        request.url = nil

        let task = MockWKURLSchemeTask(request: request)

        let expectation = expectation(description: "onFail completion called")

        task.onFail = {
            expectation.fulfill()
        }

        subject.webView(webView, start: task)

        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(task.receivedResponses.isEmpty)
        XCTAssertTrue(task.receivedBodies.isEmpty)
        XCTAssertEqual(task.finishCallCount, 0)
        XCTAssertEqual(task.failedErrors.count, 1)

        let error = task.failedErrors.first as? TinyRouterError
        XCTAssertEqual(error, .badURL)
    }

    private func createSubject() -> TranslationsSchemeHandler {
        let fetcher = MockTranslationModelsFetcher()
        fetcher.translatorWASMResult = Data([1, 2, 3])
        let router = TinyRouter()
            .register("models-buffer", ModelsBufferRoute(fetcher: fetcher))
            .register("models", ModelsRoute(fetcher: fetcher))
            .register("translator", TranslatorRoute(fetcher: fetcher))
            .setDefault(StaticFileRoute())
        return TranslationsSchemeHandler(router: router)
    }

    private func makeWebView() -> WKWebView {
        WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    }
}
