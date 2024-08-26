// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import Shared
import XCTest
import WebKit

class TabWebViewTests: XCTestCaseRootViewController, UIGestureRecognizerDelegate {
    private var configuration = WKWebViewConfiguration()
    private var navigationDelegate: MockNavigationDelegate!
    private var tabWebViewDelegate: MockTabWebViewDelegate!
    private let sleepTime: UInt64 = 1 * NSEC_PER_SEC
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() {
        super.setUp()
        navigationDelegate = MockNavigationDelegate()
        tabWebViewDelegate = MockTabWebViewDelegate()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    override func tearDown() {
        super.tearDown()
        navigationDelegate = nil
        tabWebViewDelegate = nil
        DependencyHelperMock().reset()
    }

    func testBasicTabWebView_doesntLeak() async throws {
        _ = try await createSubject()
    }

    func testSavedCardsClosure_doesntLeak() async throws {
        let subject = try await createSubject()
        subject.accessoryView.savedCardsClosure = {}
    }

    func testTabWebView_doesntLeak() {
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID)
        tab.createWebview(configuration: configuration)

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_load_doesntLeak() {
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID)
        tab.createWebview(configuration: configuration)
        tab.loadRequest(URLRequest(url: URL(string: "https://www.mozilla.com")!))

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_withLegacySessionData_doesntLeak() {
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID)
        tab.url = URL(string: "http://yahoo.com/")!
        tab.createWebview(configuration: configuration)

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_withSessionData_doesntLeak() {
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID)
        tab.createWebview(with: Data(), configuration: configuration)

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_withURL_doesntLeak() {
        let tab = Tab(profile: MockProfile(), windowUUID: windowUUID)
        tab.url = URL(string: "https://www.mozilla.com")!
        tab.createWebview(configuration: configuration)

        trackForMemoryLeaks(tab)
    }

    // MARK: - Helper methods

    func createSubject(file: StaticString = #file,
                       line: UInt = #line) async throws -> TabWebView {
        let subject = TabWebView(frame: .zero, configuration: .init(), windowUUID: windowUUID)
        try await Task.sleep(nanoseconds: sleepTime)
        subject.configure(delegate: tabWebViewDelegate, navigationDelegate: navigationDelegate)
        trackForMemoryLeaks(subject)
        return subject
    }
}

// MARK: - MockTabWebViewDelegate
class MockTabWebViewDelegate: TabWebViewDelegate {
    func tabWebView(_ tabWebView: TabWebView,
                    didSelectFindInPageForSelection selection: String) {}

    func tabWebViewSearchWithFirefox(_ tabWebViewSearchWithFirefox: TabWebView,
                                     didSelectSearchWithFirefoxForSelection selection: String) {}

    func tabWebViewShouldShowAccessoryView(_ tabWebView: TabWebView) -> Bool {
        return true
    }
}

// MARK: - MockNavigationDelegate
class MockNavigationDelegate: NSObject, WKNavigationDelegate {}
