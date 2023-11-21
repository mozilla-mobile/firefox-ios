// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import WebKit
import XCTest
@testable import Client

final class ContentContainerTests: XCTestCase {
    private var profile: MockProfile!
    private var overlayModeManager: MockOverlayModeManager!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())
        self.profile = MockProfile()
        self.overlayModeManager = MockOverlayModeManager()
    }

    override func tearDown() {
        super.tearDown()
        self.profile = nil
        self.overlayModeManager = nil
        AppContainer.shared.reset()
    }

    // MARK: - canAddHomepage

    func testCanAddHomepage() {
        let subject = ContentContainer(frame: .zero)
        let homepage = createHomepage()

        XCTAssertTrue(subject.canAdd(content: homepage))
    }

    func testCanAddHomepageOnceOnly() {
        let subject = ContentContainer(frame: .zero)
        let homepage = createHomepage()

        subject.add(content: homepage)
        XCTAssertFalse(subject.canAdd(content: homepage))
    }

    func testCanAddWebview() {
        let subject = ContentContainer(frame: .zero)
        let webview = WebviewViewController(webView: WKWebView())

        XCTAssertTrue(subject.canAdd(content: webview))
    }

    func testCanAddWebviewOnceOnly() {
        let subject = ContentContainer(frame: .zero)
        let webview = WebviewViewController(webView: WKWebView())

        subject.add(content: webview)
        XCTAssertFalse(subject.canAdd(content: webview))
    }

    // MARK: - hasHomepage

    func testHasHomepage_trueWhenHomepage() {
        let subject = ContentContainer(frame: .zero)
        let homepage = createHomepage()
        subject.add(content: homepage)

        XCTAssertTrue(subject.hasHomepage)
    }

    func testHasHomepage_falseWhenNil() {
        let subject = ContentContainer(frame: .zero)
        XCTAssertFalse(subject.hasHomepage)
    }

    func testHasHomepage_falseWhenWebview() {
        let subject = ContentContainer(frame: .zero)
        let webview = WebviewViewController(webView: WKWebView())
        subject.add(content: webview)

        XCTAssertFalse(subject.hasHomepage)
    }

    // MARK: - contentView

    func testContentView_notContent_viewIsNil() {
        let subject = ContentContainer(frame: .zero)
        XCTAssertNil(subject.contentView)
    }

    func testContentView_hasContentHomepage_viewIsNotNil() {
        let subject = ContentContainer(frame: .zero)
        let homepage = createHomepage()
        subject.add(content: homepage)
        XCTAssertNotNil(subject.contentView)
    }

    private func createHomepage() -> HomepageViewController {
        return HomepageViewController(profile: profile, toastContainer: UIView(), overlayManager: overlayModeManager)
    }
}
