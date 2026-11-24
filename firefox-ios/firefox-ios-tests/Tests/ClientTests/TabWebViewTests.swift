// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

import Common
import XCTest
import WebKit

class TabWebViewTests: XCTestCaseRootViewController, UIGestureRecognizerDelegate {
    private var configuration = WKWebViewConfiguration()
    private var navigationDelegate: MockNavigationDelegate!
    private var tabWebViewDelegate: MockTabWebViewDelegate!
    private let sleepTime: UInt64 = 1 * NSEC_PER_SEC
    private let inputViewsReloadWaitTime: UInt64 = 300 * NSEC_PER_MSEC
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        navigationDelegate = MockNavigationDelegate()
        tabWebViewDelegate = MockTabWebViewDelegate()
        DependencyHelperMock().bootstrapDependencies()
    }

    override func tearDown() async throws {
        navigationDelegate = nil
        tabWebViewDelegate = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testBasicTabWebView_doesntLeak() async throws {
        _ = try await createSubject()
    }

    func testSavedCardsClosure_doesntLeak() async throws {
        let subject = try await createSubject()
        subject.accessoryView.savedCardsClosure = {}
    }

    func testAddPullRefresh() async throws {
        let subject = try await createSubject()
        subject.addPullRefresh {}

        XCTAssertNotNil(subject.scrollView.subviews.first(where: { $0 is PullRefreshView }))
    }

    func testRemovePullRefresh() async throws {
        let subject = try await createSubject()

        subject.addPullRefresh {}
        subject.removePullRefresh()

        XCTAssertNil(subject.subviews.first(where: { $0 is PullRefreshView }))
    }

    func testTabWebView_doesntLeak() {
        let tab = Tab(profile: makeProfile(), windowUUID: windowUUID)
        tab.createWebview(configuration: configuration)

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_load_doesntLeak() {
        let tab = Tab(profile: makeProfile(), windowUUID: windowUUID)
        tab.createWebview(configuration: configuration)
        tab.loadRequest(URLRequest(url: URL(string: "https://www.mozilla.com")!))

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_withLegacySessionData_doesntLeak() {
        let tab = Tab(profile: makeProfile(), windowUUID: windowUUID)
        tab.url = URL(string: "http://yahoo.com/")!
        tab.createWebview(configuration: configuration)

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_withSessionData_doesntLeak() {
        let tab = Tab(profile: makeProfile(), windowUUID: windowUUID)
        tab.createWebview(with: Data(), configuration: configuration)

        trackForMemoryLeaks(tab)
    }

    func testTabWebView_withURL_doesntLeak() {
        let tab = Tab(profile: makeProfile(), windowUUID: windowUUID)
        tab.url = URL(string: "https://www.mozilla.com")!
        tab.createWebview(configuration: configuration)

        trackForMemoryLeaks(tab)
    }

    func testHasOnlySecureContent_returnsTrue_ForLocalPDFFile() throws {
        let tab = Tab(profile: makeProfile(), windowUUID: windowUUID)
        tab.url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("test.pdf")
        tab.createWebview(configuration: configuration)

        let tabWebView = try XCTUnwrap(tab.webView)

        XCTAssertTrue(tabWebView.hasOnlySecureContent)
    }

    func testInputAccessoryView_onPadWithoutAutofillItem_isNil() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Only iOS 26+ drops the iPad navigation buttons") }
        let accessoryView = AccessoryViewProvider(windowUUID: windowUUID, userInterfaceIdiom: .pad)
        let subject = try await createSubject(accessoryView: accessoryView)

        subject.accessoryView.reloadViewFor(.standard)

        XCTAssertNil(subject.inputAccessoryView)
    }

    func testInputAccessoryView_onPadWithAutofillItem_isAccessoryView() async throws {
        let accessoryView = AccessoryViewProvider(windowUUID: windowUUID, userInterfaceIdiom: .pad)
        let subject = try await createSubject(accessoryView: accessoryView)

        subject.accessoryView.reloadViewFor(.login)

        XCTAssertIdentical(subject.inputAccessoryView, accessoryView)
    }

    func testInputAccessoryView_onPhoneWithoutAutofillItem_isAccessoryView() async throws {
        let accessoryView = AccessoryViewProvider(windowUUID: windowUUID, userInterfaceIdiom: .phone)
        let subject = try await createSubject(accessoryView: accessoryView)

        subject.accessoryView.reloadViewFor(.standard)

        XCTAssertIdentical(subject.inputAccessoryView, accessoryView)
    }

    func testContentAvailabilityChange_onPad_reloadsInputViewsOnFirstResponder() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Only iOS 26+ drops the iPad navigation buttons") }
        let accessoryView = AccessoryViewProvider(windowUUID: windowUUID, userInterfaceIdiom: .pad)
        let subject = try await createSubject(accessoryView: accessoryView)
        let contentView = FirstResponderSpyView()
        subject.scrollView.addSubview(contentView)

        subject.accessoryView.reloadViewFor(.login)
        try await Task.sleep(nanoseconds: inputViewsReloadWaitTime)

        XCTAssertEqual(contentView.reloadInputViewsCallCount, 1)
    }

    func testContentAvailabilityChange_onPad_backToBackChangesReloadOnce() async throws {
        guard #available(iOS 26.0, *) else { throw XCTSkip("Only iOS 26+ drops the iPad navigation buttons") }
        let accessoryView = AccessoryViewProvider(windowUUID: windowUUID, userInterfaceIdiom: .pad)
        let subject = try await createSubject(accessoryView: accessoryView)
        subject.accessoryView.reloadViewFor(.passwordGenerator)
        try await Task.sleep(nanoseconds: inputViewsReloadWaitTime)
        let contentView = FirstResponderSpyView()
        subject.scrollView.addSubview(contentView)

        subject.accessoryView.reloadViewFor(.standard)
        subject.accessoryView.reloadViewFor(.passwordGenerator)
        try await Task.sleep(nanoseconds: inputViewsReloadWaitTime)

        XCTAssertEqual(contentView.reloadInputViewsCallCount, 1)
    }

    // MARK: - Helper methods

    func createSubject(accessoryView: AccessoryViewProvider? = nil,
                       file: StaticString = #filePath,
                       line: UInt = #line) async throws -> TabWebView {
        let subject = TabWebView(frame: CGRect(origin: .zero, size: CGSize(width: 100, height: 100)),
                                 configuration: .init(),
                                 windowUUID: windowUUID,
                                 certStore: makeProfile().certStore)
        if let accessoryView { subject.accessoryView = accessoryView }
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

// MARK: - FirstResponderSpyView
class FirstResponderSpyView: UIView {
    var reloadInputViewsCallCount = 0

    override var isFirstResponder: Bool { true }

    override func reloadInputViews() {
        reloadInputViewsCallCount += 1
    }
}
