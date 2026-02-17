// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit
import XCTest
@testable import Client

@MainActor
final class ContentContainerTests: XCTestCase {
    private var profile: MockProfile!
    private var overlayModeManager: MockOverlayModeManager!
    private var tabManager: MockTabManager!

    override func setUp() async throws {
        try await super.setUp()
        self.profile = MockProfile()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        self.overlayModeManager = MockOverlayModeManager()
        self.tabManager = MockTabManager()
    }

    override func tearDown() async throws {
        self.profile = nil
        self.overlayModeManager = nil
        self.tabManager = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    // MARK: - canAddHomepage

    func testCanAddHomepage() {
        let subject = createSubject()
        let homepage = createHomepage()

        XCTAssertTrue(subject.canAdd(content: homepage))
    }

    func testCanAddHomepageOnceOnly() {
        let subject = createSubject()
        let homepage = createHomepage()

        subject.add(content: homepage)
        XCTAssertFalse(subject.canAdd(content: homepage))
    }

    // MARK: - canAddNewHomepage

    func testCanAddNewHomepage() {
        let subject = createSubject()
        let homepage = HomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            tabManager: tabManager,
            overlayManager: overlayModeManager,
            toastContainer: UIView()
        )

        XCTAssertTrue(subject.canAdd(content: homepage))
    }

    func testCanAddNewHomepageOnceOnly() {
        let subject = createSubject()
        let homepage = HomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            tabManager: tabManager,
            overlayManager: overlayModeManager,
            toastContainer: UIView()
        )

        subject.add(content: homepage)
        XCTAssertFalse(subject.canAdd(content: homepage))
    }

    // MARK: - canAddPrivateHomepage

    func testCanAddPrivateHomepage() {
        let subject = createSubject()
        let privateHomepage = PrivateHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: overlayModeManager
        )

        XCTAssertTrue(subject.canAdd(content: privateHomepage))
    }

    func testCanAddPrivateHomepageOnceOnly() {
        let subject = createSubject()
        let privateHomepage = PrivateHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: overlayModeManager
        )

        subject.add(content: privateHomepage)
        XCTAssertFalse(subject.canAdd(content: privateHomepage))
    }

    // MARK: - Webview

    func testCanAddWebview() {
        let subject = createSubject()
        let webview = WebviewViewController(webView: WKWebView())

        XCTAssertTrue(subject.canAdd(content: webview))
    }

    func testCanAddWebviewOnceOnly() {
        let subject = createSubject()
        let webview = WebviewViewController(webView: WKWebView())

        subject.add(content: webview)
        XCTAssertFalse(subject.canAdd(content: webview))
    }

    func testHasHomepage_falseWhenWebview() {
        let subject = createSubject()
        let webview = WebviewViewController(webView: WKWebView())
        subject.add(content: webview)

        XCTAssertFalse(subject.hasHomepage)
    }

    // MARK: - hasHomepage

    func testHasNewHomepage_returnsTrueWhenAdded() {
        let subject = createSubject()
        let homepage = HomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            tabManager: tabManager,
            overlayManager: overlayModeManager,
            toastContainer: UIView()
        )
        subject.add(content: homepage)

        XCTAssertTrue(subject.hasHomepage)
    }

    func testHasNewHomepage_returnsFalseWhenNil() {
        let subject = createSubject()
        XCTAssertFalse(subject.hasHomepage)
    }

    func testHasNewHomepage_returnsFalseWhenWebview() {
        let subject = createSubject()
        let webview = WebviewViewController(webView: WKWebView())
        subject.add(content: webview)

        XCTAssertFalse(subject.hasHomepage)
    }

    // MARK: - hasPrivateHomepage

    func testHasPrivateHomepage_returnsTrueWhenAdded() {
        let subject = createSubject()
        let privateHomepage = PrivateHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: overlayModeManager
        )
        subject.add(content: privateHomepage)

        XCTAssertTrue(subject.hasPrivateHomepage)
    }

    func testHasPrivateHomepage_returnsFalseWhenNil() {
        let subject = createSubject()
        XCTAssertFalse(subject.hasPrivateHomepage)
    }

    func testHasPrivateHomepage_returnsFalseWhenWebview() {
        let subject = createSubject()
        let webview = WebviewViewController(webView: WKWebView())
        subject.add(content: webview)

        XCTAssertFalse(subject.hasPrivateHomepage)
    }

    // MARK: - hasAnyHomepage

    func testHasAnyHomepage_returnsTrueWhenAddedNewHomepage() {
        let subject = createSubject()
        let homepage = HomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            tabManager: tabManager,
            overlayManager: overlayModeManager,
            toastContainer: UIView()
        )
        subject.add(content: homepage)

        XCTAssertTrue(subject.hasAnyHomepage)
    }

    func testHasAnyHomepage_returnsTrueWhenAddedPrivate() {
        let subject = createSubject()
        let privateHomepage = PrivateHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: overlayModeManager
        )
        subject.add(content: privateHomepage)

        XCTAssertTrue(subject.hasAnyHomepage)
    }

    func testHasAnyHomepage_returnsFalseWhenNil() {
        let subject = createSubject()
        XCTAssertFalse(subject.hasAnyHomepage)
    }

    // MARK: - contentView

    func testContentView_notContent_viewIsNil() {
        let subject = createSubject()
        XCTAssertNil(subject.contentView)
    }

    func testContentView_hasContentHomepage_viewIsNotNil() {
        let subject = createSubject()
        let homepage = createHomepage()
        subject.add(content: homepage)
        XCTAssertNotNil(subject.contentView)
    }

    func testContentView_hasContentNewHomepage_viewIsNotNil() {
        let subject = createSubject()
        let homepage = HomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            tabManager: tabManager,
            overlayManager: overlayModeManager,
            toastContainer: UIView()
        )
        subject.add(content: homepage)
        XCTAssertNotNil(subject.contentView)
    }

    func testContentView_hasContentPrivateHomepage_viewIsNotNil() {
        let subject = createSubject()
        let privateHomepage = PrivateHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: overlayModeManager
        )
        subject.add(content: privateHomepage)
        XCTAssertNotNil(subject.contentView)
    }

    // MARK: update method

    func test_update_hasNewHomepage_returnsTrue() {
        let subject = createSubject()
        let homepage = HomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            tabManager: tabManager,
            overlayManager: overlayModeManager,
            toastContainer: UIView()
        )
        subject.update(content: homepage)
        XCTAssertTrue(subject.hasHomepage)
        XCTAssertFalse(subject.hasPrivateHomepage)
        XCTAssertFalse(subject.hasWebView)
    }

    func test_update_hasNewPrivateHomepage_returnsTrue() {
        let subject = createSubject()
        let privateHomepage = PrivateHomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            overlayManager: overlayModeManager
        )
        subject.update(content: privateHomepage)
        XCTAssertTrue(subject.hasPrivateHomepage)
        XCTAssertFalse(subject.hasHomepage)
        XCTAssertFalse(subject.hasWebView)
    }

    func test_update_hasWebView_returnsTrue() {
        let subject = createSubject()
        let webview = WebviewViewController(webView: WKWebView())
        subject.update(content: webview)
        XCTAssertTrue(subject.hasWebView)
        XCTAssertFalse(subject.hasHomepage)
        XCTAssertFalse(subject.hasPrivateHomepage)
    }

    func testAdd_doesNotRemoveWebView() {
        let subject = createSubject()

        let webView = WebviewViewController(webView: WKWebView())
        subject.add(content: webView)
        subject.add(content: createHomepage())

        XCTAssertNotNil(webView.view.superview)
    }

    func testAdd_doesRemoveHomepage() {
        let subject = createSubject()

        let homepage = HomepageViewController(
            windowUUID: .XCTestDefaultUUID,
            tabManager: tabManager,
            overlayManager: overlayModeManager,
            toastContainer: UIView()
        )
        subject.add(content: homepage)
        subject.add(content: WebviewViewController(webView: WKWebView()))

        XCTAssertNil(homepage.view.superview)
    }

    private func createSubject() -> ContentContainer {
        let subject = ContentContainer()
        trackForMemoryLeaks(subject)
        return subject
    }

    private func createHomepage() -> HomepageViewController {
        return HomepageViewController(
            windowUUID: WindowUUID.XCTestDefaultUUID,
            tabManager: tabManager,
            overlayManager: overlayModeManager,
            toastContainer: UIView()
        )
    }
}
