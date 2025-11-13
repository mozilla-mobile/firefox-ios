// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import Client
import WebKit

final class TranslationsSchemeHandlerTests: XCTestCase {
    func test_start_validModelsRequest_sendsResponseAndFinishes() {
        let subject = createSubject()
        let url = URL(string: "translations://app/translator")!
        let task = WKURLSchemeTaskMock(url: url)
        let webView = makeWebView()

        subject.webView(webView, start: task)

        XCTAssertTrue(task.failedErrors.isEmpty)
        XCTAssertEqual(task.receivedResponses.count, 1)
        XCTAssertEqual(task.receivedBodies.count, 1)
        XCTAssertEqual(task.finishCallCount, 1)

        let http = task.receivedResponses.first as? HTTPURLResponse
        XCTAssertNotNil(http)
        XCTAssertEqual(http?.statusCode, 200)

        let bodyString = String(data: task.receivedBodies.first ?? Data(), encoding: .utf8)
        XCTAssertNotNil(bodyString)
    }

    func test_start_wrongScheme_failsWithUnsupportedScheme() {
        let subject = createSubject()
        let url = URL(string: "http://app/models")!
        let task = WKURLSchemeTaskMock(url: url)
        let webView = makeWebView()

        subject.webView(webView, start: task)

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
        let task = WKURLSchemeTaskMock(url: url)
        let webView = makeWebView()

        subject.webView(webView, start: task)

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

    private func createSubject() -> TranslationsSchemeHandler {
        TranslationsSchemeHandler()
    }

    private func makeWebView() -> WKWebView {
        WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
    }
}
