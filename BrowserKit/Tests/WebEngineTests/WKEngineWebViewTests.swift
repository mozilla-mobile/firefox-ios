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

    func testCurrentHistoryItemSetAfterVisitingPage() {
        let subject = createSubject()
        let testURL = URL(string: "https://www.example.com/")!

        let expectation = expectation(description: "Wait for the decision handler to be called")

        XCTAssertNil(subject.currentBackForwardListItem())
        delegate.webViewPropertyChangedCallback = { webEngineViewProperty in
            guard webEngineViewProperty == .loading(false) else {return}
            XCTAssertNotNil(subject.currentBackForwardListItem())
            self.delegate.webViewPropertyChangedCallback = nil
            expectation.fulfill()
        }

        subject.load(URLRequest(url: testURL))

        wait(for: [expectation], timeout: 10)
    }

    func testGetBackHistoryList() {
        let subject = createSubject()

        XCTAssertEqual(subject.backList().count, 0)

        createBackList(subject: subject)

        XCTAssertEqual(subject.backList().count, 2)
    }

    func testGetForwardHistoryList() {
        let subject = createSubject()

        let expectation1 = expectation(description: "Wait for the decision handler to be called")
        let expectation2 = expectation(description: "Wait for the decision handler to be called twice")

        createBackList(subject: subject)

        XCTAssertEqual(subject.forwardList().count, 0)

        delegate.webViewPropertyChangedCallback = { webEngineViewProperty in
            guard webEngineViewProperty == .loading(false) else {return}
            expectation1.fulfill()
        }
        subject.goBack()
        wait(for: [expectation1], timeout: 10)

        delegate.webViewPropertyChangedCallback = { webEngineViewProperty in
            guard webEngineViewProperty == .loading(false) else {return}
            XCTAssertEqual(subject.forwardList().count, 2)
            self.delegate.webViewPropertyChangedCallback = nil
            expectation2.fulfill()
        }
        subject.goBack()
        wait(for: [expectation2], timeout: 10)
    }

    func createBackList(subject: DefaultWKEngineWebView) {
        let testURL1 = URL(string: "https://www.example.com/")!
        let testURL2 = URL(string: "https://www.youtube.com/")!
        let currentURL = URL(string: "https://www.google.com/")!

        let expectation1 = expectation(description: "Wait for the decision handler to be called once")

        let expectation2 = expectation(description: "Wait for the decision handler to be called twice")

        let expectation3 = expectation(description: "Wait for the decision handler to be called three times")

        delegate.webViewPropertyChangedCallback = { webEngineViewProperty in
            guard webEngineViewProperty == .loading(false) else {return}
            expectation1.fulfill()
        }
        subject.load(URLRequest(url: testURL1))
        wait(for: [expectation1], timeout: 10)

        delegate.webViewPropertyChangedCallback = { webEngineViewProperty in
            guard webEngineViewProperty == .loading(false) else {return}
            expectation2.fulfill()
        }
        subject.load(URLRequest(url: testURL2))
        wait(for: [expectation2], timeout: 10)

        delegate.webViewPropertyChangedCallback = { webEngineViewProperty in
            guard webEngineViewProperty == .loading(false) else {return}
            self.delegate.webViewPropertyChangedCallback = nil
            expectation3.fulfill()
        }
        subject.load(URLRequest(url: currentURL))
        wait(for: [expectation3], timeout: 10)
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
