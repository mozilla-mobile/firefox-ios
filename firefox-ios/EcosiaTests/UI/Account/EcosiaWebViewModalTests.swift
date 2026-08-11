// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import Client
@testable import Ecosia
// swiftlint:disable implicitly_unwrapped_optional

@available(iOS 16.0, *)
@MainActor
final class EcosiaWebViewModalTests: XCTestCase, @unchecked Sendable {

    private var coordinator: EcosiaWebViewMockCoordinator!
    private var mockWebView: MockWKWebView!
    private var mockParent: MockWebViewRepresentable!

    override func setUp() {
        super.setUp()
        mockWebView = MockWKWebView()
        mockParent = MockWebViewRepresentable()
        coordinator = EcosiaWebViewMockCoordinator(parent: mockParent)
    }

    override func tearDown() {
        coordinator = nil
        mockWebView = nil
        mockParent = nil
        super.tearDown()
    }

    // MARK: - WKUIDelegate Tests

    func testCreateWebViewWith_targetBlankLink_loadsInModal() {
        // Given
        let blankURL = URL(string: "https://example.com/blank-page")!
        let currentURL = URL(string: "https://example.com/origin")!
        mockWebView.mockURL = currentURL

        let navigationAction = EcosiaWebViewMockNavigationAction(
            request: URLRequest(url: blankURL),
            targetFrame: nil
        )

        // When
        let result = coordinator.webView(
            mockWebView,
            createWebViewWith: WKWebViewConfiguration(),
            for: navigationAction,
            windowFeatures: WKWindowFeatures()
        )

        // Then
        XCTAssertNil(result, "Should return nil to prevent new window creation")
        XCTAssertEqual(mockWebView.loadedRequests.count, 1)
        XCTAssertEqual(mockWebView.loadedRequests.first?.url, blankURL)
        XCTAssertTrue(coordinator.blankTargetURLs.contains(currentURL.absoluteString))
    }

    func testCreateWebViewWith_noTargetFrame_recordsOriginURL() {
        // Given
        let originURL = URL(string: "https://example.com/page1")!
        mockWebView.mockURL = originURL

        let blankURL = URL(string: "https://example.com/blank")!
        let navigationAction = EcosiaWebViewMockNavigationAction(
            request: URLRequest(url: blankURL),
            targetFrame: nil
        )

        // When
        _ = coordinator.webView(
            mockWebView,
            createWebViewWith: WKWebViewConfiguration(),
            for: navigationAction,
            windowFeatures: WKWindowFeatures()
        )

        // Then
        XCTAssertTrue(coordinator.blankTargetURLs.contains(originURL.absoluteString))
    }

    func testCreateWebViewWith_noURL_returnsNil() {
        // Given
        let navigationAction = EcosiaWebViewMockNavigationAction(
            request: URLRequest(url: URL(string: "about:blank")!),
            targetFrame: nil
        )
        navigationAction.mockRequestURL = nil

        // When
        let result = coordinator.webView(
            mockWebView,
            createWebViewWith: WKWebViewConfiguration(),
            for: navigationAction,
            windowFeatures: WKWindowFeatures()
        )

        // Then
        XCTAssertNil(result)
        XCTAssertEqual(mockWebView.loadedRequests.count, 0)
    }

    // MARK: - Back Navigation Prevention Tests

    func testDecidePolicyFor_backToBlankTargetOrigin_preventsNavigation() {
        // Given
        let originURL = URL(string: "https://example.com/origin")!
        coordinator.blankTargetURLs.insert(originURL.absoluteString)

        let navigationAction = EcosiaWebViewMockNavigationAction(
            request: URLRequest(url: originURL),
            navigationType: .backForward
        )

        let expectation = XCTestExpectation(description: "Decision handler called")
        var capturedPolicy: WKNavigationActionPolicy?

        // When
        coordinator.webView(mockWebView, decidePolicyFor: navigationAction) { policy in
            capturedPolicy = policy
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(capturedPolicy, .cancel)
        XCTAssertEqual(mockWebView.goBackCallCount, 1)
    }

    func testDecidePolicyFor_backToBlankTargetOrigin_cannotGoBack_reloadsInitialURL() {
        // Given
        let originURL = URL(string: "https://example.com/origin")!
        let initialURL = URL(string: "https://example.com/initial")!
        mockParent.mockURL = initialURL
        mockWebView.mockCanGoBack = false
        coordinator.blankTargetURLs.insert(originURL.absoluteString)

        let navigationAction = EcosiaWebViewMockNavigationAction(
            request: URLRequest(url: originURL),
            navigationType: .backForward
        )

        let expectation = XCTestExpectation(description: "Decision handler called")

        // When
        coordinator.webView(mockWebView, decidePolicyFor: navigationAction) { _ in
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(mockWebView.loadedRequests.count, 1)
        XCTAssertEqual(mockWebView.loadedRequests.first?.url, initialURL)
        XCTAssertTrue(coordinator.blankTargetURLs.isEmpty, "Should clear tracked URLs")
    }

    func testDecidePolicyFor_normalBackNavigation_allowsNavigation() {
        // Given
        let url = URL(string: "https://example.com/page")!
        let navigationAction = EcosiaWebViewMockNavigationAction(
            request: URLRequest(url: url),
            navigationType: .backForward
        )

        let expectation = XCTestExpectation(description: "Decision handler called")
        var capturedPolicy: WKNavigationActionPolicy?

        // When
        coordinator.webView(mockWebView, decidePolicyFor: navigationAction) { policy in
            capturedPolicy = policy
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(capturedPolicy, .allow)
        XCTAssertEqual(mockWebView.goBackCallCount, 0)
    }

    func testDecidePolicyFor_nonBackForwardNavigation_allowsNavigation() {
        // Given
        let originURL = URL(string: "https://example.com/origin")!
        coordinator.blankTargetURLs.insert(originURL.absoluteString)

        let navigationAction = EcosiaWebViewMockNavigationAction(
            request: URLRequest(url: originURL),
            navigationType: .linkActivated
        )

        let expectation = XCTestExpectation(description: "Decision handler called")
        var capturedPolicy: WKNavigationActionPolicy?

        // When
        coordinator.webView(mockWebView, decidePolicyFor: navigationAction) { policy in
            capturedPolicy = policy
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(capturedPolicy, .allow)
    }

    // MARK: - Multiple Blank Target URLs Tests

    func testMultipleBlankTargetURLs_tracksAll() {
        // Given
        let url1 = URL(string: "https://example.com/page1")!
        let url2 = URL(string: "https://example.com/page2")!
        let url3 = URL(string: "https://example.com/page3")!

        mockWebView.mockURL = url1
        let action1 = EcosiaWebViewMockNavigationAction(
            request: URLRequest(url: URL(string: "https://example.com/blank1")!),
            targetFrame: nil
        )
        _ = coordinator.webView(mockWebView, createWebViewWith: WKWebViewConfiguration(), for: action1, windowFeatures: WKWindowFeatures())

        mockWebView.mockURL = url2
        let action2 = EcosiaWebViewMockNavigationAction(
            request: URLRequest(url: URL(string: "https://example.com/blank2")!),
            targetFrame: nil
        )
        _ = coordinator.webView(mockWebView, createWebViewWith: WKWebViewConfiguration(), for: action2, windowFeatures: WKWindowFeatures())

        mockWebView.mockURL = url3
        let action3 = EcosiaWebViewMockNavigationAction(
            request: URLRequest(url: URL(string: "https://example.com/blank3")!),
            targetFrame: nil
        )
        _ = coordinator.webView(mockWebView, createWebViewWith: WKWebViewConfiguration(), for: action3, windowFeatures: WKWindowFeatures())

        // Then
        XCTAssertEqual(coordinator.blankTargetURLs.count, 3)
        XCTAssertTrue(coordinator.blankTargetURLs.contains(url1.absoluteString))
        XCTAssertTrue(coordinator.blankTargetURLs.contains(url2.absoluteString))
        XCTAssertTrue(coordinator.blankTargetURLs.contains(url3.absoluteString))
    }

    func testBlankTargetURLs_clearedWhenReloadingInitial() {
        // Given
        let originURL = URL(string: "https://example.com/origin")!
        coordinator.blankTargetURLs.insert(originURL.absoluteString)
        coordinator.blankTargetURLs.insert("https://example.com/other")
        mockWebView.mockCanGoBack = false
        mockParent.mockURL = URL(string: "https://example.com/initial")!

        let navigationAction = EcosiaWebViewMockNavigationAction(
            request: URLRequest(url: originURL),
            navigationType: .backForward
        )

        let expectation = XCTestExpectation(description: "Decision handler called")

        // When
        coordinator.webView(mockWebView, decidePolicyFor: navigationAction) { _ in
            expectation.fulfill()
        }

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(coordinator.blankTargetURLs.isEmpty)
    }

    // MARK: - User Agent Tests

    func testInit_storesProvidedUserAgent() {
        // Given
        let expectedUserAgent = "Mozilla/5.0 (Ecosia ios@test)"

        // When
        let modal = EcosiaWebViewModal(
            url: URL(string: "https://example.com/profile")!,
            windowUUID: .XCTestDefaultUUID,
            userAgent: expectedUserAgent
        )

        // Then
        XCTAssertEqual(
            mirrorString(from: modal, label: "userAgent"),
            expectedUserAgent
        )
    }

    func testInit_storesInAppMobileUserAgent() {
        // Given / When
        let modal = EcosiaWebViewModal(
            url: EcosiaEnvironment.current.urlProvider.profileURL,
            windowUUID: .XCTestDefaultUUID,
            userAgent: EcosiaInAppWebViewUserAgent.mobileUserAgent()
        )

        // Then
        XCTAssertEqual(
            mirrorString(from: modal, label: "userAgent"),
            EcosiaInAppWebViewUserAgent.mobileUserAgent()
        )
    }

    private func mirrorString(from object: Any, label: String) -> String? {
        Mirror(reflecting: object).children.first { $0.label == label }?.value as? String
    }
}

// MARK: - Mock Classes

@available(iOS 16.0, *)
private class EcosiaWebViewMockCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
    let parent: MockWebViewRepresentable
    var blankTargetURLs: Set<String> = []

    init(parent: MockWebViewRepresentable) {
        self.parent = parent
    }

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        guard navigationAction.targetFrame == nil,
              let url = navigationAction.request.url else {
            return nil
        }

        if let currentURL = webView.url {
            blankTargetURLs.insert(currentURL.absoluteString)
        }

        webView.load(URLRequest(url: url))
        return nil
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }

        if navigationAction.navigationType == .backForward,
           blankTargetURLs.contains(url.absoluteString) {
            decisionHandler(.cancel)

            if webView.canGoBack {
                webView.goBack()
            } else {
                webView.load(URLRequest(url: parent.mockURL))
                blankTargetURLs.removeAll()
            }
            return
        }

        decisionHandler(.allow)
    }
}

@available(iOS 16.0, *)
private class MockWebViewRepresentable {
    var mockURL = URL(string: "https://example.com")!
}

@available(iOS 16.0, *)
private class MockWKWebView: WKWebView {
    var mockURL: URL?
    var mockCanGoBack = true
    var loadedRequests: [URLRequest] = []
    var goBackCallCount = 0

    override var url: URL? {
        return mockURL
    }

    override var canGoBack: Bool {
        return mockCanGoBack
    }

    override func load(_ request: URLRequest) -> WKNavigation? {
        loadedRequests.append(request)
        return nil
    }

    override func goBack() -> WKNavigation? {
        goBackCallCount += 1
        return nil
    }
}

@available(iOS 16.0, *)
private class EcosiaWebViewMockNavigationAction: WKNavigationAction {
    private let mockRequest: URLRequest
    private let mockTargetFrame: WKFrameInfo?
    private let mockNavigationType: WKNavigationType
    private var shouldOverrideURL = false
    var mockRequestURL: URL? {
        didSet {
            shouldOverrideURL = true
        }
    }

    init(request: URLRequest, targetFrame: WKFrameInfo? = nil, navigationType: WKNavigationType = .other) {
        self.mockRequest = request
        self.mockTargetFrame = targetFrame
        self.mockNavigationType = navigationType
        self.mockRequestURL = request.url
    }

    override var request: URLRequest {
        guard shouldOverrideURL else {
            return mockRequest
        }
        var modifiedRequest = mockRequest
        modifiedRequest.url = mockRequestURL
        return modifiedRequest
    }

    override var targetFrame: WKFrameInfo? {
        return mockTargetFrame
    }

    override var navigationType: WKNavigationType {
        return mockNavigationType
    }
}

@available(iOS 16.0, *)
private class EcosiaWebViewMockFrameInfo: WKFrameInfo {
    override var isMainFrame: Bool {
        return true
    }
}
// swiftlint:enable implicitly_unwrapped_optional
