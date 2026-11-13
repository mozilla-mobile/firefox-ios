// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import WebKit
import XCTest

@testable import Client

@MainActor
final class FoxDashViewControllerTests: XCTestCase {
    private var themeProvider: MockFoxDashThemeProvider!
    private var themeManager: MockThemeManager!
    private var closeCallCount = 0

    override func setUp() async throws {
        try await super.setUp()
        themeProvider = MockFoxDashThemeProvider(themeID: "christmas")
        themeManager = MockThemeManager()
        closeCallCount = 0
    }

    override func tearDown() async throws {
        themeProvider = nil
        themeManager = nil
        try await super.tearDown()
    }

    func test_viewDidLoad_addsWebViewAndSingleCloseButton() throws {
        let subject = createSubject()

        subject.loadViewIfNeeded()

        XCTAssertEqual(subject.view.subviews.compactMap { $0 as? WKWebView }.count, 1)
        XCTAssertEqual(subject.view.subviews.compactMap { $0 as? UIButton }.count, 1)
        XCTAssertNotNil(closeButton(in: subject))
    }

    func test_viewDidLoad_injectsThemeScriptAtDocumentStart() throws {
        let subject = createSubject()

        subject.loadViewIfNeeded()

        let webView = try XCTUnwrap(subject.view.subviews.compactMap { $0 as? WKWebView }.first)
        let script = try XCTUnwrap(webView.configuration.userContentController.userScripts.first)
        XCTAssertEqual(script.injectionTime, .atDocumentStart)
        XCTAssertTrue(script.source.contains("christmas"))
    }

    func test_viewDidLoad_usesNonPersistentDataStore() throws {
        let subject = createSubject()

        subject.loadViewIfNeeded()

        let webView = try XCTUnwrap(subject.view.subviews.compactMap { $0 as? WKWebView }.first)
        XCTAssertFalse(webView.configuration.websiteDataStore.isPersistent)
    }

    func test_closeButton_tapped_callsOnClose() throws {
        let subject = createSubject()
        subject.loadViewIfNeeded()

        try XCTUnwrap(closeButton(in: subject)).sendActions(for: .touchUpInside)

        XCTAssertEqual(closeCallCount, 1)
    }

    func test_viewDidLoad_indexMissing_callsOnClose() {
        let subject = createSubject(bundle: Bundle(for: FoxDashViewControllerTests.self))

        subject.loadViewIfNeeded()

        XCTAssertEqual(closeCallCount, 1)
    }

    func test_bundle_containsFoxDashIndex() {
        XCTAssertNotNil(Bundle.main.url(forResource: "index", withExtension: "html", subdirectory: "FoxDash"))
    }

    private func createSubject(bundle: Bundle = .main) -> FoxDashViewController {
        let subject = FoxDashViewController(
            windowUUID: .XCTestDefaultUUID,
            themeProvider: themeProvider,
            themeManager: themeManager,
            bundle: bundle
        ) { [weak self] in
            self?.closeCallCount += 1
        }
        return subject
    }

    private func closeButton(in subject: FoxDashViewController) -> UIButton? {
        return subject.view.subviews.compactMap { $0 as? UIButton }.first
    }
}

private struct MockFoxDashThemeProvider: FoxDashThemeProviding {
    let themeID: String
}
