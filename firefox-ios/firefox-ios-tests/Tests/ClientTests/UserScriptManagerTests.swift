// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import WebKit
@testable import Client

@MainActor
final class UserScriptManagerTests: XCTestCase {
    private var originalIsProxyEnabled: (() -> Bool)!

    override func setUp() async throws {
        try await super.setUp()
        originalIsProxyEnabled = UserScriptManager.shared.isProxyEnabled
    }

    override func tearDown() async throws {
        UserScriptManager.shared.isProxyEnabled = originalIsProxyEnabled
        originalIsProxyEnabled = nil
        try await super.tearDown()
    }

    func testInjectUserScripts_whenProxyEnabled_addsProxyHardeningScript() {
        let subject = createSubject(isProxyEnabled: true)
        let webView = WKWebView()

        injectUserScripts(using: subject, into: webView)

        XCTAssertTrue(webView.configuration.userContentController.userScripts.contains(subject.proxyHardeningUserScript))
    }

    func testInjectUserScripts_whenProxyDisabled_doesNotAddProxyHardeningScript() {
        let subject = createSubject(isProxyEnabled: false)
        let webView = WKWebView()

        injectUserScripts(using: subject, into: webView)

        XCTAssertFalse(webView.configuration.userContentController.userScripts.contains(subject.proxyHardeningUserScript))
    }

    func testInjectUserScripts_whenProxyTurnedOff_removesProxyHardeningScript() {
        let subject = createSubject(isProxyEnabled: true)
        let webView = WKWebView()
        injectUserScripts(using: subject, into: webView)

        subject.isProxyEnabled = { false }
        injectUserScripts(using: subject, into: webView)

        XCTAssertFalse(webView.configuration.userContentController.userScripts.contains(subject.proxyHardeningUserScript))
    }

    private func createSubject(isProxyEnabled: Bool) -> UserScriptManager {
        let subject = UserScriptManager.shared
        subject.isProxyEnabled = { isProxyEnabled }
        return subject
    }

    private func injectUserScripts(using subject: UserScriptManager, into webView: WKWebView) {
        subject.injectUserScriptsIntoWebView(webView, nightMode: false, noImageMode: false, backgroundAudio: false)
    }
}
