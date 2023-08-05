// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import Shared
import XCTest
import WebKit

class TabWebViewTests: XCTestCaseRootViewController, UIGestureRecognizerDelegate {
    private var configuration: WKWebViewConfiguration!
    private var navigationDelegate: MockNavigationDelegate!
    private var tabWebViewDelegate: MockTabWebViewDelegate!
    private let sleepTime: UInt64 = 1 * NSEC_PER_SEC

    override func setUp() {
        super.setUp()
        configuration = WKWebViewConfiguration()
        navigationDelegate = MockNavigationDelegate()
        tabWebViewDelegate = MockTabWebViewDelegate()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: MockProfile())
    }

    override func tearDown() {
        super.tearDown()
        configuration = nil
        navigationDelegate = nil
        tabWebViewDelegate = nil
        DependencyHelperMock().reset()
    }

    func testBasicTabWebView_doesntLeak() async throws {
        _ = try await createSubject(configuration: configuration)
    }

    func testSavedCardsClosure_doesntLeak() async throws {
        let subject = try await createSubject(configuration: configuration)
        subject.accessoryView.savedCardsClosure = {}
    }

    func testTabWebView_doesntLeak() {
        let tab = Tab(profile: MockProfile(), configuration: configuration)
        tab.createWebview()

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_load_doesntLeak() {
        let tab = Tab(profile: MockProfile(), configuration: configuration)
        tab.createWebview()
        tab.loadRequest(URLRequest(url: URL(string: "https://www.mozilla.com")!))

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_withLegacySessionData_doesntLeak() {
        let tab = Tab(profile: MockProfile(), configuration: configuration)
        tab.url = URL(string: "http://yahoo.com/")!
        let sessionData = LegacySessionData(currentPage: 0, urls: [tab.url!], lastUsedTime: Date.now())
        tab.sessionData = sessionData
        tab.createWebview()

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_withSessionData_doesntLeak() {
        let tab = Tab(profile: MockProfile(), configuration: configuration)
        tab.createWebview(with: Data())

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_withURL_doesntLeak() {
        let tab = Tab(profile: MockProfile(), configuration: configuration)
        tab.url = URL(string: "https://www.mozilla.com")!
        tab.createWebview()

        trackForMemoryLeaks(tab)
    }

    // MARK: - Helper methods

    func createSubject(configuration: WKWebViewConfiguration,
                       file: StaticString = #file,
                       line: UInt = #line) async throws -> TabWebView {
        let subject = TabWebView(frame: .zero, configuration: configuration)
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
}

// MARK: - MockNavigationDelegate
class MockNavigationDelegate: NSObject, WKNavigationDelegate {}
