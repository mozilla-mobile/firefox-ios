// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import XCTest
import WebKit
@testable import Client

final class BrowserCoordinatorTests: XCTestCase {
    private var mockRouter: MockRouter!
    private var profile: MockProfile!
    private var overlayModeManager: MockOverlayModeManager!
    private var logger: MockLogger!
    private var screenshotService: ScreenshotService!
    private var tabManager: MockTabManager!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
        self.profile = MockProfile()
        self.overlayModeManager = MockOverlayModeManager()
        self.logger = MockLogger()
        self.screenshotService = ScreenshotService()
        self.tabManager = MockTabManager()
    }

    override func tearDown() {
        super.tearDown()
        self.mockRouter = nil
        self.profile = nil
        self.overlayModeManager = nil
        self.logger = nil
        self.screenshotService = nil
        self.tabManager = nil
        AppContainer.shared.reset()
    }

    func testInitialState() {
        let subject = createSubject()

        XCTAssertNotNil(subject.browserViewController)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 0)
    }

    func testWithoutLaunchType_startsBrowserOnly() {
        let subject = createSubject()
        subject.start(with: nil)

        XCTAssertNotNil(mockRouter.rootViewController as? BrowserViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testWithLaunchType_startsLaunchCoordinator() {
        let subject = createSubject()
        subject.start(with: .defaultBrowser)

        XCTAssertNotNil(mockRouter.rootViewController as? BrowserViewController)
        XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? LaunchCoordinator)
    }

    func testChildLaunchCoordinatorIsDone_deallocatesAndDismiss() throws {
        let subject = createSubject()
        subject.start(with: .defaultBrowser)

        let childLaunchCoordinator = try XCTUnwrap(subject.childCoordinators[0] as? LaunchCoordinator)
        subject.didFinishLaunch(from: childLaunchCoordinator)

        XCTAssertTrue(subject.childCoordinators.isEmpty)
        XCTAssertEqual(mockRouter.dismissCalled, 1)
    }

    func testShowHomepage_addsOneHomepageOnly() {
        let subject = createSubject()
        subject.showHomepage(inline: true,
                             homepanelDelegate: subject.browserViewController,
                             libraryPanelDelegate: subject.browserViewController,
                             sendToDeviceDelegate: subject.browserViewController,
                             overlayManager: overlayModeManager)

        let secondHomepage = HomepageViewController(profile: profile, overlayManager: overlayModeManager)
        XCTAssertFalse(subject.browserViewController.contentContainer.canAdd(content: secondHomepage))
        XCTAssertNotNil(subject.homepageViewController)
        XCTAssertNil(subject.webviewController)
    }

    func testShowHomepage_reuseExistingHomepage() {
        let subject = createSubject()
        subject.showHomepage(inline: true,
                             homepanelDelegate: subject.browserViewController,
                             libraryPanelDelegate: subject.browserViewController,
                             sendToDeviceDelegate: subject.browserViewController,
                             overlayManager: overlayModeManager)
        let firstHomepage = subject.homepageViewController
        XCTAssertNotNil(subject.homepageViewController)

        subject.showHomepage(inline: true,
                             homepanelDelegate: subject.browserViewController,
                             libraryPanelDelegate: subject.browserViewController,
                             sendToDeviceDelegate: subject.browserViewController,
                             overlayManager: overlayModeManager)
        let secondHomepage = subject.homepageViewController
        XCTAssertEqual(firstHomepage, secondHomepage)
    }

    func testShowWebview_withoutPreviousSendsFatal() {
        let subject = createSubject()
        subject.show(webView: nil)
        XCTAssertEqual(logger.savedMessage, "Webview controller couldn't be shown, this shouldn't happen.")
        XCTAssertEqual(logger.savedLevel, .fatal)

        XCTAssertNil(subject.homepageViewController)
        XCTAssertNil(subject.webviewController)
    }

    func testShowWebview_embedNewWebview() {
        let webview = WKWebView()
        let subject = createSubject()
        subject.show(webView: webview)

        XCTAssertNil(subject.homepageViewController)
        XCTAssertNotNil(subject.webviewController)
    }

    func testShowWebview_reuseExistingWebview() {
        let webview = WKWebView()
        let subject = createSubject()
        subject.show(webView: webview)
        let firstWebview = subject.webviewController
        XCTAssertNotNil(firstWebview)

        subject.show(webView: nil)
        let secondWebview = subject.webviewController
        XCTAssertEqual(firstWebview, secondWebview)
    }

    func testShowWebview_setsScreenshotService() {
        let webview = WKWebView()
        let subject = createSubject()
        subject.show(webView: webview)

        XCTAssertNotNil(screenshotService.screenshotableView)
    }

    func testHandleSearchQuery_returnsTrue() {
        let query = "test query"
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        mbvc.switchToTabForURLOrOpenCalled = { isCalled in
            XCTAssertTrue(isCalled)
        }
        mbvc.handleQueryCalled = { queryCalled in
            XCTAssertEqual(query, queryCalled)
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .searchQuery(query: query))
        XCTAssertTrue(result)
    }

    func testHandleSearch_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        mbvc.switchToTabForURLOrOpenCalled = { isCalled in
            XCTAssertTrue(isCalled)
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .search(url: URL(string: "https://example.com")!, isPrivate: false, options: nil))
        XCTAssertTrue(result)
    }

    func testHandleSearchWithNormalMode_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        mbvc.switchToPrivacyModeCalled = { isCalled in
            XCTAssertTrue(isCalled)
        }
        mbvc.switchToTabForURLOrOpenCalled = { isCalled in
            XCTAssertTrue(isCalled)
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .search(url: URL(string: "https://example.com")!, isPrivate: false, options: [.switchToNormalMode]))
        XCTAssertTrue(result)
    }

    func testHandleSearchWithNilURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        mbvc.openBlankNewTabCalled = { isCalled in
            XCTAssertTrue(isCalled)
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .search(url: nil, isPrivate: false))
        XCTAssertTrue(result)
    }

    func testHandleSearchURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        mbvc.switchToTabForURLOrOpenCalled = { isCalled in
            XCTAssertTrue(isCalled)
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .searchURL(url: URL(string: "https://example.com")!, tabId: "1234"))
        XCTAssertTrue(result)
    }

    func testHandleNilSearchURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        mbvc.openBlankNewTabCalled = { isCalled in
            XCTAssertTrue(isCalled)
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .searchURL(url: nil, tabId: "1234"))
        XCTAssertTrue(result)
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #file,
                               line: UInt = #line) -> BrowserCoordinator {
        let subject = BrowserCoordinator(router: mockRouter,
                                         screenshotService: screenshotService,
                                         profile: profile,
                                         logger: logger)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
