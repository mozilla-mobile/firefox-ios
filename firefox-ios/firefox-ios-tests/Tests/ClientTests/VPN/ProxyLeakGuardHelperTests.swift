// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit
import XCTest
@testable import Client

@MainActor
final class ProxyLeakGuardHelperTests: XCTestCase {
    private var validBody: [String: Any] { body("WebAuthnRelatedOrigin", "get") }
    private var connectionBody: [String: Any] { body("DirectConnection", "RTCPeerConnection") }
    private var tab: Tab?

    override func setUp() async throws {
        try await super.setUp()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        await tab?.close()
        tab = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func test_handle_validGetAndCreate_reportOrigin() {
        let (subject, reported) = makeSubject()

        subject.handle(body: validBody, origin: "https://a.example")
        subject.handle(body: body("WebAuthnRelatedOrigin", "create"), origin: "https://b.example")

        XCTAssertEqual(reported.values, [
            .init(api: .webAuthnRelatedOrigin, origin: "https://a.example"),
            .init(api: .webAuthnRelatedOrigin, origin: "https://b.example")
        ])
    }

    func test_handle_validDirectConnectionKinds_reportOrigin() {
        let (subject, reported) = makeSubject()

        subject.handle(body: connectionBody, origin: "https://a.example")
        subject.handle(body: body("DirectConnection", "webkitRTCPeerConnection"), origin: "https://b.example")

        XCTAssertEqual(reported.values, [
            .init(api: .directConnection, origin: "https://a.example"),
            .init(api: .directConnection, origin: "https://b.example")
        ])
    }

    func test_handle_untrustedBodies_areIgnored() {
        let (subject, reported) = makeSubject()

        subject.handle(body: body("RTCPeerConnection", "get"), origin: "https://a.example")
        subject.handle(body: body("DirectConnection", "get"), origin: "https://a.example")
        subject.handle(body: body("DirectConnection", "WebTransport"), origin: "https://a.example")
        subject.handle(body: body("WebAuthnRelatedOrigin", "RTCPeerConnection"), origin: "https://a.example")
        subject.handle(body: body("WebRTC", "RTCPeerConnection"), origin: "https://a.example")
        subject.handle(body: body("WebAuthnRelatedOrigin", "delete"), origin: "https://a.example")
        var missingKind = validBody
        missingKind["kind"] = nil
        subject.handle(body: missingKind, origin: "https://a.example")
        subject.handle(body: body(1, "get"), origin: "https://a.example")
        subject.handle(body: "WebAuthnRelatedOrigin", origin: "https://a.example")

        XCTAssertTrue(reported.values.isEmpty)
    }

    func test_handle_missingOrWrongToken_isIgnored() {
        let (subject, reported) = makeSubject()

        subject.handle(body: ["api": "WebAuthnRelatedOrigin", "kind": "get"], origin: "https://a.example")
        subject.handle(body: ["api": "WebAuthnRelatedOrigin", "kind": "get", "token": "guess"], origin: "https://a.example")
        subject.handle(body: ["api": "WebAuthnRelatedOrigin", "kind": "get", "token": 1], origin: "https://a.example")

        XCTAssertTrue(reported.values.isEmpty)
    }

    func test_handle_sameOriginTwice_reportsOnce() {
        let (subject, reported) = makeSubject()

        subject.handle(body: validBody, origin: "https://a.example")
        subject.handle(body: body("WebAuthnRelatedOrigin", "create"), origin: "https://a.example")

        XCTAssertEqual(reported.values, [.init(api: .webAuthnRelatedOrigin, origin: "https://a.example")])
    }

    func test_handle_differentAPIsOnSameOrigin_reportEach() {
        let (subject, reported) = makeSubject()

        subject.handle(body: connectionBody, origin: "https://a.example")
        subject.handle(body: validBody, origin: "https://a.example")
        subject.handle(body: body("DirectConnection", "webkitRTCPeerConnection"), origin: "https://a.example")

        XCTAssertEqual(reported.values, [
            .init(api: .directConnection, origin: "https://a.example"),
            .init(api: .webAuthnRelatedOrigin, origin: "https://a.example")
        ])
    }

    func test_handle_originInBody_isIgnored() {
        let (subject, reported) = makeSubject()
        var body = validBody
        body["origin"] = "https://spoofed.example"

        subject.handle(body: body, origin: "https://frame.example")

        XCTAssertEqual(reported.values, [.init(api: .webAuthnRelatedOrigin, origin: "https://frame.example")])
    }

    func test_inject_withProxyOff_doesNotAddGuardScript() {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())

        inject(into: webView, isProxyEnabled: false)

        XCTAssertNil(guardScript(webView))
    }

    func test_inject_withProxyOn_addsGuardScriptToAllFramesAtDocumentStart() throws {
        let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())

        inject(into: webView, isProxyEnabled: true)

        let script = try XCTUnwrap(guardScript(webView))
        XCTAssertEqual(script.injectionTime, .atDocumentStart)
        XCTAssertFalse(script.isForMainFrameOnly)
    }

    func test_page_crossSiteRpId_isRejectedAndReportedWithFrameOrigin() async throws {
        let (webView, reported) = try await makeLoadedTabWebView()
        let fired = expectation(description: "handler fired")
        reported.onReport = { fired.fulfill() }

        let result = try await credentialsGet(rpId: "other.example", in: webView)

        XCTAssertEqual(result, "NotAllowedError:Not allowed")
        await fulfillment(of: [fired], timeout: 2)
        XCTAssertEqual(reported.values, [.init(api: .webAuthnRelatedOrigin, origin: "https://example.com")])
    }

    func test_page_sameHostRpId_isNotBlockedByShim() async throws {
        let (webView, reported) = try await makeLoadedTabWebView()
        let fired = expectation(description: "handler fired")
        fired.isInverted = true
        reported.onReport = { fired.fulfill() }

        let result = try await credentialsGet(rpId: "example.com", in: webView)

        XCTAssertNotEqual(result, "NotAllowedError:Not allowed")
        await fulfillment(of: [fired], timeout: 0.5)
    }

    func test_page_webRTCRead_isHiddenAndReportedOnce() async throws {
        let (webView, reported) = try await makeLoadedTabWebView()
        let fired = expectation(description: "handler fired")
        reported.onReport = { fired.fulfill() }

        let result = try await webView.callAsyncJavaScript(
            """
            RTCPeerConnection = function () {};
            return [typeof RTCPeerConnection, typeof window.RTCPeerConnection].join(',');
            """,
            contentWorld: .page
        ) as? String

        XCTAssertEqual(result, "undefined,undefined")
        await fulfillment(of: [fired], timeout: 2)
        XCTAssertEqual(reported.values, [.init(api: .directConnection, origin: "https://example.com")])
    }

    func test_page_directPostMessage_isIgnored() async throws {
        let (webView, reported) = try await makeLoadedTabWebView()
        let fired = expectation(description: "handler fired")
        fired.isInverted = true
        reported.onReport = { fired.fulfill() }

        _ = try await webView.callAsyncJavaScript(
            """
            window.webkit.messageHandlers.\(ProxyLeakGuardHelper.handlerName).postMessage(
              { api: "DirectConnection", kind: "RTCPeerConnection" }
            );
            """,
            contentWorld: .page
        )

        await fulfillment(of: [fired], timeout: 0.5)
        XCTAssertTrue(reported.values.isEmpty)
    }

    private func body(_ api: Any, _ kind: Any) -> [String: Any] {
        return ["api": api, "kind": kind, "token": UserScriptManager.appIdToken]
    }

    private func makeSubject() -> (ProxyLeakGuardHelper, ReportedOrigins) {
        let subject = ProxyLeakGuardHelper()
        let reported = ReportedOrigins()
        subject.onBlockedRequest = { reported.record(.init(api: $0, origin: $1)) }
        return (subject, reported)
    }

    private func inject(into webView: WKWebView, isProxyEnabled: Bool) {
        UserScriptManager.shared.injectUserScriptsIntoWebView(webView,
                                                              nightMode: false,
                                                              noImageMode: false,
                                                              backgroundAudio: false,
                                                              isProxyEnabled: isProxyEnabled)
    }

    private func guardScript(_ webView: WKWebView) -> WKUserScript? {
        return webView.configuration.userContentController.userScripts.first {
            $0.source.contains("messageHandlers?.\(ProxyLeakGuardHelper.handlerName)")
        }
    }

    private func makeLoadedTabWebView() async throws -> (WKWebView, ReportedOrigins) {
        let tab = Tab(profile: makeProfile(), windowUUID: .XCTestDefaultUUID)
        tab.createWebview(configuration: WKWebViewConfiguration())
        let webView = try XCTUnwrap(tab.webView)
        let (helper, reported) = makeSubject()
        tab.addContentScriptToPage(helper, name: ProxyLeakGuardHelper.name())
        inject(into: webView, isProxyEnabled: true)
        self.tab = tab

        let delegate = LoadFinishedDelegate()
        let loaded = expectation(description: "page loaded")
        delegate.onFinish = { loaded.fulfill() }
        webView.navigationDelegate = delegate
        webView.loadHTMLString("<html><body></body></html>", baseURL: URL(string: "https://example.com"))
        await fulfillment(of: [loaded], timeout: 5)
        webView.navigationDelegate = nil
        return (webView, reported)
    }

    /// Uses a pre-aborted signal so a call the shim lets through settles immediately instead of
    /// showing system sign-in UI.
    private func credentialsGet(rpId: String, in webView: WKWebView) async throws -> String? {
        return try await webView.callAsyncJavaScript(
            """
            try {
              await navigator.credentials.get({
                publicKey: { rpId, challenge: new Uint8Array(32) },
                signal: AbortSignal.abort()
              });
              return 'resolved';
            } catch (e) {
              return e.name + ':' + e.message;
            }
            """,
            arguments: ["rpId": rpId],
            contentWorld: .page
        ) as? String
    }
}

@MainActor
private final class ReportedOrigins {
    struct Report: Equatable {
        let api: ProxyLeakGuardHelper.BlockedAPI
        let origin: String
    }

    private(set) var values: [Report] = []
    var onReport: (() -> Void)?

    func record(_ report: Report) {
        values.append(report)
        onReport?()
    }
}

@MainActor
private final class LoadFinishedDelegate: NSObject, WKNavigationDelegate {
    var onFinish: (() -> Void)?

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        onFinish?()
    }
}
