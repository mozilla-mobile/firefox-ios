// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
@testable import WebEngine
import WebKit

final class WKEngineWebViewTests: XCTestCase {
    private var delegate: MockWKEngineWebViewDelegate!
    private let testURL = URL(string: "https://www.example.com/")!

    override func setUp() {
        super.setUp()
        delegate = MockWKEngineWebViewDelegate()
    }

    override func tearDown() {
        delegate = nil
        super.tearDown()
    }

    @MainActor
    func testNoLeaks() {
        let subject = createSubject()
        subject.close()

        // Wait for Webview to fully deallocate
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    @MainActor
    func testLoad_callsObservers() {
        let subject = createSubject()
        let loadingExpectation = expectation(that: \WKWebView.isLoading, on: subject) { _, change in
            guard change.newValue != nil else { return false }
            return true
        }
        let titleExpectation = expectation(that: \WKWebView.title, on: subject)
        let urlExpectation = expectation(that: \WKWebView.url, on: subject) { [weak self] _, change in
            guard let url = change.newValue as? URL else { return false }
            XCTAssertEqual(url, self?.testURL)
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

    @MainActor
    func testLoad_callsBeginRefreshing_onUIRefreshControl() throws {
        let subject = createSubject(pullRefreshViewType: MockUIRefreshControl.self)
        let pullRefresh = try XCTUnwrap(subject.scrollView.refreshControl as? MockUIRefreshControl)

        subject.load(URLRequest(url: testURL))

        XCTAssertEqual(pullRefresh.beginRefreshingCalled, 1)
        XCTAssertEqual(pullRefresh.endRefreshingCalled, 0)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    @MainActor
    func testInit_setupsPullRefresh() throws {
        let subject = createSubject()

        let pullRefresh = try XCTUnwrap(subject.scrollView.subviews.first {
            $0 is EnginePullRefreshView
        }) as? MockEnginePullRefreshView

        XCTAssertNotNil(pullRefresh)
        XCTAssertNil(subject.scrollView.refreshControl)
        XCTAssertEqual(pullRefresh?.configureCalled, 1)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    @MainActor
    func testInit_withUIRefreshControl_setupsCorrectlyPullRefresh() {
        let subject = createSubject(pullRefreshViewType: UIRefreshControl.self)

        XCTAssertNotNil(subject.scrollView.refreshControl)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    @MainActor
    func testScrollWillBeginZooming_removesPullRefresh() {
        let subject = createSubject()

        subject.scrollViewWillBeginZooming(UIScrollView(), with: nil)

        let pullRefresh = subject.scrollView.subviews.first { $0 is EnginePullRefreshView }
        XCTAssertNil(pullRefresh)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    @MainActor
    func testScrollDidEndZooming_setupsPullRefresh() {
        let subject = createSubject()

        subject.scrollViewWillBeginZooming(UIScrollView(), with: nil)
        subject.scrollViewDidEndZooming(UIScrollView(), with: nil, atScale: 1.0)

        let pullRefresh = subject.scrollView.subviews.first { $0 is EnginePullRefreshView }
        XCTAssertNotNil(pullRefresh)
        XCTAssertNil(subject.scrollView.refreshControl)
        XCTAssertEqual((pullRefresh as? MockEnginePullRefreshView)?.configureCalled, 1)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    @MainActor
    func testScrollDidEndZooming_doesntSetupPullRefreshAgain() {
        let subject = createSubject()

        subject.scrollViewDidEndZooming(UIScrollView(), with: nil, atScale: 1.0)

        let pullRefresh = subject.scrollView.subviews.first { $0 is EnginePullRefreshView }
        XCTAssertNotNil(pullRefresh)
        XCTAssertNil(subject.scrollView.refreshControl)
        XCTAssertEqual((pullRefresh as? MockEnginePullRefreshView)?.configureCalled, 1)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    @MainActor
    func testTriggerPullRefresh_callsDelegate() throws {
        let subject = createSubject()
        let pullRefresh = try XCTUnwrap(subject.scrollView.subviews.first { $0 is EnginePullRefreshView }
                                        as? MockEnginePullRefreshView)

        pullRefresh.onRefresh?()

        XCTAssertEqual(delegate.webViewNeedsReloadCalled, 1)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
    }

    @MainActor
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

    @MainActor
    func createSubject(pullRefreshViewType: EnginePullRefreshViewType = MockEnginePullRefreshView.self,
                       file: StaticString = #file,
                       line: UInt = #line) -> DefaultWKEngineWebView {
        let parameters = WKWebViewParameters(blockPopups: true,
                                             isPrivate: false,
                                             autoPlay: .all,
                                             schemeHandler: WKInternalSchemeHandler(),
                                             pullRefreshType: pullRefreshViewType)
        let configuration = DefaultWKEngineConfigurationProvider()
        let subject = DefaultWKEngineWebView(frame: .zero,
                                             configurationProvider: configuration,
                                             parameters: parameters)!
        subject.delegate = delegate
        trackForMemoryLeaks(subject, file: file, line: line)

        return subject
    }
}
