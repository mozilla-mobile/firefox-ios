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
    private var routeBuilder: RouteBuilder!
    private var tabManager: MockTabManager!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        FeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())
        self.routeBuilder = RouteBuilder { false }
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
        self.profile = MockProfile()
        self.overlayModeManager = MockOverlayModeManager()
        self.logger = MockLogger()
        self.screenshotService = ScreenshotService()
        self.tabManager = MockTabManager()
    }

    override func tearDown() {
        super.tearDown()
        self.routeBuilder = nil
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
        let expectation = XCTestExpectation(description: "Handle search query")
        mbvc.switchToTabForURLOrOpenCalled = { isCalled in
            XCTAssertTrue(isCalled)
            expectation.fulfill()
        }
        mbvc.handleQueryCalled = { queryCalled in
            XCTAssertEqual(query, queryCalled)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .searchQuery(query: query))
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1)
    }

    func testHandleSearch_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        let expectation = XCTestExpectation(description: "Handle search")
        mbvc.switchToTabForURLOrOpenCalled = { isCalled in
            XCTAssertTrue(isCalled)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .search(url: URL(string: "https://example.com")!, isPrivate: false, options: nil))
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1)
    }

    func testHandleSearchWithNormalMode_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        let expectation = XCTestExpectation(description: "Handle search with normal mode")
        mbvc.switchToPrivacyModeCalled = { isCalled in
            XCTAssertTrue(isCalled)
            expectation.fulfill()
        }
        mbvc.switchToTabForURLOrOpenCalled = { isCalled in
            XCTAssertTrue(isCalled)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .search(url: URL(string: "https://example.com")!, isPrivate: false, options: [.switchToNormalMode]))
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1)
    }

    func testHandleSearchWithNilURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        let expectation = XCTestExpectation(description: "Handle search with nil URL")
        mbvc.openBlankNewTabCalled = { isPrivate in
            XCTAssertFalse(isPrivate)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .search(url: nil, isPrivate: false))
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1)
    }

    func testHandleSearchURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        let expectation = XCTestExpectation(description: "Handle search URL")
        mbvc.switchToTabForURLOrOpenCalled = { isCalled in
            XCTAssertTrue(isCalled)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .searchURL(url: URL(string: "https://example.com")!, tabId: "1234"))
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1)
    }

    func testHandleNilSearchURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        let expectation = XCTestExpectation(description: "Handle nil search URL")
        mbvc.openBlankNewTabCalled = { isPrivate in
            XCTAssertFalse(isPrivate)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc
        let result = subject.handle(route: .searchURL(url: nil, tabId: "1234"))
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1)
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

    func testHandleHomepanelBookmarks_returnsTrue() {
        // Given
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        let expectation = XCTestExpectation(description: "Show bookmarks panel")
        mbvc.showLibraryCalled = { panel in
            XCTAssertEqual(panel, .bookmarks)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc

        // When
        let route = routeBuilder.makeRoute(url: URL(string: "firefox://deep-link?url=/homepanel/bookmarks")!)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1)
    }

    func testHandleHomepanelHistory_returnsTrue() {
        // Given
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        let expectation = XCTestExpectation(description: "Show history panel")
        mbvc.showLibraryCalled = { panel in
            XCTAssertEqual(panel, .history)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc

        // When
        let route = routeBuilder.makeRoute(url: URL(string: "firefox://deep-link?url=/homepanel/history")!)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1)
    }

    func testHandleHomepanelReadingList_returnsTrue() {
        // Given
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        let expectation = XCTestExpectation(description: "Show reading list panel")
        mbvc.showLibraryCalled = { panel in
            XCTAssertEqual(panel, .readingList)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc

        // When
        let route = routeBuilder.makeRoute(url: URL(string: "firefox://deep-link?url=/homepanel/reading-list")!)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1)
    }

    func testHandleHomepanelDownloads_returnsTrue() {
        // Given
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        let expectation = XCTestExpectation(description: "Show downloads panel")
        mbvc.showLibraryCalled = { panel in
            XCTAssertEqual(panel, .downloads)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc

        // When
        let route = routeBuilder.makeRoute(url: URL(string: "firefox://deep-link?url=/homepanel/downloads")!)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 1)
    }

    func testHandleHomepanelTopSites_returnsTrue() {
        // Given
        let topSitesURL = URL(string: "firefox://deep-link?url=/homepanel/top-sites")!
        let expectation = XCTestExpectation(description: "openURLInNewTab is called")
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        mbvc.openURLInNewTabCalled = { url, isPrivate in
            XCTAssertEqual(HomePanelType.topSites.internalUrl, url)
            XCTAssertEqual(isPrivate, false)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc

        // When
        let route = routeBuilder.makeRoute(url: topSitesURL)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 0.1)
    }

    func testHandleNewPrivateTab_returnsTrue() {
        // Given
        let newPrivateTabURL = URL(string: "firefox://deep-link?url=/homepanel/new-private-tab")!
        let expectation = XCTestExpectation(description: "openBlankNewTab is called")
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        mbvc.openBlankNewTabCalled = { isPrivate in
            XCTAssertEqual(isPrivate, true)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc

        // When
        let route = routeBuilder.makeRoute(url: newPrivateTabURL)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 0.1)
    }

    func testHandleHomepanelNewTab_returnsTrue() {
        // Given
        let newTabURL = URL(string: "firefox://deep-link?url=/homepanel/new-tab")!
        let expectation = XCTestExpectation(description: "openBlankNewTab is called")
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        mbvc.openBlankNewTabCalled = { isPrivate in
            XCTAssertEqual(isPrivate, false)
            expectation.fulfill()
        }
        subject.browserViewController = mbvc

        // When
        let route = routeBuilder.makeRoute(url: newTabURL)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        wait(for: [expectation], timeout: 0.1)
    }
}
