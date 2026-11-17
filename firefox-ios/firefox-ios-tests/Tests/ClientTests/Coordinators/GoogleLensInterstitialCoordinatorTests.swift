// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebKit
import XCTest

@testable import Client

@MainActor
final class GoogleLensInterstitialCoordinatorTests: XCTestCase {
    private var router: MockRouter!
    private var navigationController: MockNavigationController!
    private var parentCoordinator: MockParentCoordinator!
    private var profile: MockProfile!
    private var tab: MockTab!
    private var webView: MockTabWebView!

    override func setUp() async throws {
        try await super.setUp()
        profile = makeProfile()
        DependencyHelperMock().bootstrapDependencies(injectedProfile: profile)
        navigationController = MockNavigationController()
        router = MockRouter(navigationController: navigationController)
        router.onPresent = { [weak router = router, weak navigationController = navigationController] in
            navigationController?.presentedViewController = router?.presentedViewController
        }
        parentCoordinator = MockParentCoordinator()
        tab = MockTab(profile: profile, windowUUID: .XCTestDefaultUUID)
        webView = MockTabWebView(tab: tab)
        tab.webView = webView
    }

    override func tearDown() async throws {
        router = nil
        navigationController = nil
        parentCoordinator = nil
        webView = nil
        tab = nil
        profile = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
    }

    func testStart_presentsBackdropWithoutStartingRequest() {
        let subject = createSubject()
        subject.start()
        defer { subject.stop() }

        XCTAssertEqual(router.presentCalled, 1)
        XCTAssertTrue(router.presentedViewController is GoogleLensInterstitialViewController)
        XCTAssertEqual(webView.loadCalled, 0)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 0)
    }

    func testLoadingEnded_dismissesBackdropAndFinishesOnce() {
        let subject = createSubject()
        subject.start()
        webView.mockIsLoading = true
        XCTAssertEqual(parentCoordinator.didFinishCalled, 0)

        webView.mockIsLoading = false
        subject.stop()

        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func testStop_invalidatesLoadingObservation() {
        let subject = createSubject()
        subject.start()
        webView.mockIsLoading = true

        subject.stop()
        webView.mockIsLoading = false
        webView.mockIsLoading = true
        webView.mockIsLoading = false

        XCTAssertEqual(router.dismissCalled, 1)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func testStart_withoutWebView_finishesWithoutPresenting() {
        tab.webView = nil
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 0)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func testStart_withAnotherModal_doesNotReplaceOrDismissIt() {
        let otherController = UIViewController()
        navigationController.presentedViewController = otherController
        let subject = createSubject()

        subject.start()

        XCTAssertEqual(router.presentCalled, 0)
        XCTAssertEqual(router.dismissCalled, 0)
        XCTAssertTrue(navigationController.presentedViewController === otherController)
        XCTAssertEqual(parentCoordinator.didFinishCalled, 1)
    }

    func testStart_preservesWebViewNavigationDelegate() {
        let delegate = MockLensNavigationDelegate()
        webView.navigationDelegate = delegate
        let subject = createSubject()

        subject.start()
        subject.stop()

        XCTAssertTrue(webView.navigationDelegate === delegate)
    }

    private func createSubject() -> GoogleLensInterstitialCoordinator {
        return GoogleLensInterstitialCoordinator(parentCoordinatorDelegate: parentCoordinator,
                                                 router: router,
                                                 tab: tab,
                                                 themeManager: MockThemeManager())
    }
}

private final class MockLensNavigationDelegate: NSObject, WKNavigationDelegate {}
