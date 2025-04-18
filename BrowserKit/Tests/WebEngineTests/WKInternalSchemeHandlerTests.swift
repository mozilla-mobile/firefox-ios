// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import WebEngine

final class WKInternalSchemeHandlerTests: XCTestCase {
    func testSchemeStartIsCalledNonPrivilegedURL() throws {
        let subject = createSubject()
        let webview = WKWebView(frame: .zero)
        let url = URL(string: "www.example.com")!
        let request = URLRequest(url: url)
        let task = WKURLSchemeTaskMock(mockRequest: request)

        subject.webView(webview, start: task)

        XCTAssertEqual(task.didFailCalled, 1)
        let error = try XCTUnwrap(task.didFailedWithError as? WKInternalPageSchemeHandlerError)
        XCTAssertEqual(error, WKInternalPageSchemeHandlerError.notAuthorized)
    }

    func testSchemeStartIsCalledWithPrivilegedURLNoResponder() throws {
        let subject = createSubject()
        let webview = WKWebView(frame: .zero)
        let url = URL(string: "internal://local/about/somethingElse")!
        let privilegedURL = WKInternalURL(url)!
        privilegedURL.authorize()
        let request = URLRequest(url: privilegedURL.url)
        let task = WKURLSchemeTaskMock(mockRequest: request)

        subject.webView(webview, start: task)

        XCTAssertEqual(task.didFailCalled, 1)
        let error = try XCTUnwrap(task.didFailedWithError as? WKInternalPageSchemeHandlerError)
        XCTAssertEqual(error, WKInternalPageSchemeHandlerError.noResponder)
    }

    @MainActor
    func testSchemeStartIsCalledWithPrivilegedURLWithWrongResponder() throws {
        InternalUtil().setUpInternalHandlers()
        let subject = createSubject()
        let webview = WKWebView(frame: .zero)
        let url = URL(string: "internal://local/about/somethingElse")!
        let privilegedURL = WKInternalURL(url)!
        privilegedURL.authorize()
        let request = URLRequest(url: privilegedURL.url)
        let task = WKURLSchemeTaskMock(mockRequest: request)

        subject.webView(webview, start: task)

        XCTAssertEqual(task.didFailCalled, 1)
        let error = try XCTUnwrap(task.didFailedWithError as? WKInternalPageSchemeHandlerError)
        XCTAssertEqual(error, WKInternalPageSchemeHandlerError.noResponder)
    }

    func testSchemeStartIsCalledWithPrivilegedURLWithCorrectResponder() throws {
        setupFakeInternalHandlers()
        let subject = createSubject()
        let webview = WKWebView(frame: .zero)
        let url = URL(string: "internal://local/about/test")!
        let privilegedURL = WKInternalURL(url)!
        privilegedURL.authorize()
        let request = URLRequest(url: privilegedURL.url)
        let task = WKURLSchemeTaskMock(mockRequest: request)

        subject.webView(webview, start: task)

        XCTAssertEqual(task.didFailCalled, 1)
        let error = try XCTUnwrap(task.didFailedWithError as? WKInternalPageSchemeHandlerError)
        XCTAssertEqual(error, WKInternalPageSchemeHandlerError.responderUnableToHandle)
    }

    // MARK: Helper

    func createSubject() -> WKInternalSchemeHandler {
        let subject = WKInternalSchemeHandler()
        trackForMemoryLeaks(subject)
        return subject
    }

    func setupFakeInternalHandlers() {
        let responders: [(String, WKInternalSchemeResponse)] = [(MockSchemeHandler.path, MockSchemeHandler())]
        responders.forEach { (path, responder) in
            WKInternalSchemeHandler.responders[path] = responder
        }
    }
}
