// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine
import WebKit

final class WKEngineWebViewTests: XCTestCase {
    private var delegate: MockWKEngineWebViewDelegate!

    override func setUp() {
        super.setUp()
        delegate = MockWKEngineWebViewDelegate()
    }

    override func tearDown() {
        delegate = nil
        super.tearDown()
    }

    func testNoLeaks() {
        let subject = createSubject()
        subject.close()

        // Wait for Webview to fully deallocate
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func testLoad_callsObservers() {
        let subject = createSubject()
        let testURL = URL(string: "https://www.example.com/")!
        let loadingExpectation = expectation(that: \WKWebView.isLoading, on: subject) { _, change in
            guard change.newValue != nil else { return false }
            return true
        }
        let titleExpectation = expectation(that: \WKWebView.title, on: subject)
        let urlExpectation = expectation(that: \WKWebView.url, on: subject) { _, change in
            guard let url = change.newValue as? URL else { return false }
            XCTAssertEqual(url, testURL)
            return true
        }
        let progressExpectation = expectation(that: \WKWebView.estimatedProgress, on: subject) { _, change in
            guard let progress = change.newValue else { return false }
            XCTAssertGreaterThanOrEqual(progress, 0)
            XCTAssertLessThanOrEqual(progress, 1)
            return progress == 1
        }
        let canGoBackExpectation = expectation(that: \WKWebView.canGoBack, on: subject)
        let canGoForwardExpectation = expectation(that: \WKWebView.canGoForward, on: subject)
        let contentSizeExpectation = expectation(that: \UIScrollView.contentSize, on: subject.scrollView) { _, change in
            guard let size = change.newValue else { return false }
            return size != .zero
        }
        let hasOnlySecureContentExpectation = expectation(that: \WKWebView.hasOnlySecureContent, on: subject)

        subject.load(URLRequest(url: testURL))

        wait(
            for: [
                loadingExpectation,
                titleExpectation,
                urlExpectation,
                progressExpectation,
                canGoBackExpectation,
                canGoForwardExpectation,
                contentSizeExpectation,
                hasOnlySecureContentExpectation
            ]
        )

        if #available(iOS 16.0, *) {
            let fullscreenExpectation = expectation(that: \WKWebView.fullscreenState, on: subject)
            wait(
                for: [
                    fullscreenExpectation
                ]
            )
        }

        XCTAssertGreaterThan(delegate.webViewPropertyChangedCalled, 0)
        XCTAssertNotNil(delegate.lastWebViewPropertyChanged)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    func createSubject(file: StaticString = #file,
                       line: UInt = #line) -> DefaultWKEngineWebView {
        let parameters = WKWebviewParameters(blockPopups: true, isPrivate: false)
        let configuration = DefaultWKEngineConfigurationProvider(parameters: parameters)
        let subject = DefaultWKEngineWebView(frame: .zero,
                                             configurationProvider: configuration)!
        subject.delegate = delegate
        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }
}
