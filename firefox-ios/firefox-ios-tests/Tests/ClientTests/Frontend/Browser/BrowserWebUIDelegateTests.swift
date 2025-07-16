// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebEngine
import WebKit
@testable import Client

final class BrowserWebUIDelegateTests: XCTestCase {
    private var mockLegacyResponder: MockLegacyResponder!
    private var engineResponder: MockWKUIHandler!
    private var webView: WKWebView {
        return MockTabWebView(
            tab: MockTab(
                profile: MockProfile(),
                windowUUID: .XCTestDefaultUUID
            )
        )
    }

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        let profile = MockProfile()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        engineResponder = MockWKUIHandler()
        mockLegacyResponder = MockLegacyResponder()
    }

    override func tearDown() {
        DependencyHelperMock().reset()
        engineResponder = nil
        mockLegacyResponder = nil
        super.tearDown()
    }

    func testCreateWebView_respondsToEngineResponder() {
        let subject = createSubject()

        _ = subject.webView(
            webView,
            createWebViewWith: WKWebViewConfiguration(),
            for: MockNavigationAction(url: URL(string: "https://www.google.com")!),
            windowFeatures: .init()
        )
        XCTAssertEqual(engineResponder.createWebViewCalled, 1)
        XCTAssertEqual(mockLegacyResponder.createWebViewCalled, 0)
    }

    func testRunJavascriptAlertPanel_respondsToBrowserViewController() {
        let subject = createSubject()

        subject.webView(webView, runJavaScriptAlertPanelWithMessage: "", initiatedByFrame: .init()) {}

        XCTAssertEqual(engineResponder.runJavaScriptAlertPanelCalled, 0)
        XCTAssertEqual(mockLegacyResponder.runJavaScriptAlertPanelCalled, 1)
    }

    func testRunJavascriptConfirmPanel_respondsToBrowserViewController() {
        let subject = createSubject()

        subject.webView(webView, runJavaScriptConfirmPanelWithMessage: "", initiatedByFrame: .init()) { _ in }

        XCTAssertEqual(engineResponder.runJavaScriptConfirmPanelCalled, 0)
        XCTAssertEqual(mockLegacyResponder.runJavaScriptConfirmPanelCalled, 1)
    }

    func testRunJavascriptTextInputPanel_respondsToBrowserViewController() {
        let subject = createSubject()

        subject.webView(
            webView,
            runJavaScriptTextInputPanelWithPrompt: "",
            defaultText: nil,
            initiatedByFrame: .init()
        ) { _ in }

        XCTAssertEqual(engineResponder.runJavaScriptTextInputPanelCalled, 0)
        XCTAssertEqual(mockLegacyResponder.runJavaScriptTextInputPanelCalled, 1)
    }

    func testWebViewDidClose_respondsToBrowserViewController() {
        let subject = createSubject()

        subject.webViewDidClose(webView)

        XCTAssertEqual(engineResponder.webViewDidCloseCalled, 0)
        XCTAssertEqual(mockLegacyResponder.webViewDidCloseCalled, 1)
    }

    func testRequestMediaCapturePermission_respondsToBrowserViewController() {
        let subject = createSubject()

        subject.webView(
            webView,
            requestMediaCapturePermissionFor: WKSecurityOriginMock.new(URL(string: "https://www.example.com")),
            initiatedByFrame: .init(),
            type: .camera
        ) { _ in }

        XCTAssertEqual(engineResponder.requestMediaCapturePermissionCalled, 0)
        XCTAssertEqual(mockLegacyResponder.requestMediaCapturePermissionCalled, 1)
    }

    private func createSubject() -> BrowserWebUIDelegate {
        let subject = BrowserWebUIDelegate(engineResponder: engineResponder, legacyResponder: mockLegacyResponder)
        trackForMemoryLeaks(subject)
        return subject
    }
}

class MockLegacyResponder: NSObject, WKUIDelegate {
    var createWebViewCalled = 0
    var runJavaScriptAlertPanelCalled = 0
    var runJavaScriptConfirmPanelCalled = 0
    var runJavaScriptTextInputPanelCalled = 0
    var webViewDidCloseCalled = 0
    var contextMenuConfigurationCalled = 0
    var requestMediaCapturePermissionCalled = 0
    var contextMenuDidEndForElementCalled = 0

    // MARK: - WKUIDelegate

    func webView(
        _ webView: WKWebView,
        createWebViewWith configuration: WKWebViewConfiguration,
        for navigationAction: WKNavigationAction,
        windowFeatures: WKWindowFeatures
    ) -> WKWebView? {
        createWebViewCalled += 1
        return nil
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptAlertPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor () -> Void
    ) {
        runJavaScriptAlertPanelCalled += 1
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptConfirmPanelWithMessage message: String,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (Bool) -> Void
    ) {
        runJavaScriptConfirmPanelCalled += 1
    }

    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping @MainActor (String?) -> Void
    ) {
        runJavaScriptTextInputPanelCalled += 1
    }

    func webViewDidClose(_ webView: WKWebView) {
        webViewDidCloseCalled += 1
    }

    func webView(
        _ webView: WKWebView,
        contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo,
        completionHandler: @escaping @MainActor (UIContextMenuConfiguration?) -> Void
    ) {
        contextMenuConfigurationCalled += 1
    }

    func webView(
        _ webView: WKWebView,
        requestMediaCapturePermissionFor origin: WKSecurityOrigin,
        initiatedByFrame frame: WKFrameInfo,
        type: WKMediaCaptureType,
        decisionHandler: @escaping @MainActor (WKPermissionDecision) -> Void
    ) {
        requestMediaCapturePermissionCalled += 1
    }

    func webView(_ webView: WKWebView,
                 contextMenuDidEndForElement elementInfo: WKContextMenuElementInfo) {
        contextMenuDidEndForElementCalled += 1
    }
}
