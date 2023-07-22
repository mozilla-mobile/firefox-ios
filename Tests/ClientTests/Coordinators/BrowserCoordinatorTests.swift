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
    private var screenshotService: ScreenshotService!
    private var routeBuilder: RouteBuilder!
    private var tabManager: MockTabManager!
    private var applicationHelper: MockApplicationHelper!
    private var glean: MockGleanWrapper!
    private var wallpaperManager: WallpaperManagerMock!
    private var scrollDelegate: MockStatusBarScrollDelegate!

    override func setUp() {
        super.setUp()
        DependencyHelperMock().bootstrapDependencies()
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: AppContainer.shared.resolve())
        self.mockRouter = MockRouter(navigationController: MockNavigationController())
        self.profile = MockProfile()
        self.routeBuilder = RouteBuilder()
        self.overlayModeManager = MockOverlayModeManager()
        self.screenshotService = ScreenshotService()
        self.tabManager = MockTabManager()
        self.applicationHelper = MockApplicationHelper()
        self.glean = MockGleanWrapper()
        self.wallpaperManager = WallpaperManagerMock()
        self.scrollDelegate = MockStatusBarScrollDelegate()
    }

    override func tearDown() {
        super.tearDown()
        self.routeBuilder = nil
        self.mockRouter = nil
        self.profile = nil
        self.overlayModeManager = nil
        self.screenshotService = nil
        self.tabManager = nil
        self.applicationHelper = nil
        self.glean = nil
        self.wallpaperManager = nil
        self.scrollDelegate = nil
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

        XCTAssertNotNil(mockRouter.pushedViewController as? BrowserViewController)
        XCTAssertEqual(mockRouter.pushCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testWithLaunchType_startsLaunchCoordinator() {
        let subject = createSubject()
        subject.start(with: .defaultBrowser)

        XCTAssertNotNil(mockRouter.pushedViewController as? BrowserViewController)
        XCTAssertEqual(mockRouter.pushCalled, 1)
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

    // MARK: - Show homepage

    func testShowHomepage_addsOneHomepageOnly() {
        let subject = createSubject()
        subject.showHomepage(inline: true,
                             toastContainer: UIView(),
                             homepanelDelegate: subject.browserViewController,
                             libraryPanelDelegate: subject.browserViewController,
                             sendToDeviceDelegate: subject.browserViewController,
                             statusBarScrollDelegate: scrollDelegate,
                             overlayManager: overlayModeManager)

        let secondHomepage = HomepageViewController(profile: profile, toastContainer: UIView(), overlayManager: overlayModeManager)
        XCTAssertFalse(subject.browserViewController.contentContainer.canAdd(content: secondHomepage))
        XCTAssertNotNil(subject.homepageViewController)
        XCTAssertNil(subject.webviewController)
    }

    func testShowHomepage_reuseExistingHomepage() {
        let subject = createSubject()
        subject.showHomepage(inline: true,
                             toastContainer: UIView(),
                             homepanelDelegate: subject.browserViewController,
                             libraryPanelDelegate: subject.browserViewController,
                             sendToDeviceDelegate: subject.browserViewController,
                             statusBarScrollDelegate: scrollDelegate,
                             overlayManager: overlayModeManager)
        let firstHomepage = subject.homepageViewController
        XCTAssertNotNil(subject.homepageViewController)

        subject.showHomepage(inline: true,
                             toastContainer: UIView(),
                             homepanelDelegate: subject.browserViewController,
                             libraryPanelDelegate: subject.browserViewController,
                             sendToDeviceDelegate: subject.browserViewController,
                             statusBarScrollDelegate: scrollDelegate,
                             overlayManager: overlayModeManager)
        let secondHomepage = subject.homepageViewController
        XCTAssertEqual(firstHomepage, secondHomepage)
    }

    // MARK: - Show webview

    func testShowWebview_embedNewWebview() {
        let webview = WKWebView()
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.show(webView: webview)

        XCTAssertNil(subject.homepageViewController)
        XCTAssertNotNil(subject.webviewController)
        XCTAssertEqual(mbvc.embedContentCalled, 1)
        XCTAssertEqual(mbvc.saveEmbeddedContent?.contentType, .webview)
    }

    func testShowWebview_reuseExistingWebview() {
        let webview = WKWebView()
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.show(webView: webview)
        let firstWebview = subject.webviewController
        XCTAssertNotNil(firstWebview)

        subject.show(webView: webview)
        let secondWebview = subject.webviewController

        XCTAssertEqual(firstWebview, secondWebview)
        XCTAssertEqual(mbvc.embedContentCalled, 1)
        XCTAssertEqual(mbvc.frontEmbeddedContentCalled, 1)
        XCTAssertEqual(mbvc.saveEmbeddedContent?.contentType, .webview)
    }

    func testShowWebview_setsScreenshotService() {
        let webview = WKWebView()
        let subject = createSubject()
        subject.show(webView: webview)

        XCTAssertNotNil(screenshotService.screenshotableView)
    }

    // MARK: - BrowserNavigationHandler

    func testShowSettings() throws {
        let subject = createSubject(isSettingsCoordinatorEnabled: true)
        subject.show(settings: .general)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? SettingsCoordinator)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? ThemedNavigationController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is AppSettingsTableViewController)
    }

    func testShowLibrary() throws {
        let subject = createSubject()
        subject.show(homepanelSection: .bookmarks)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? LibraryCoordinator)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? DismissableNavigationViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is LibraryViewController)
    }

    func testShowEnhancedTrackingProtection() throws {
        let subject = createSubject()
        subject.showEnhancedTrackingProtection(sourceView: UIView())

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? EnhancedTrackingProtectionCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is EnhancedTrackingProtectionMenuVC)
    }

    func testShowShareExtension() {
        let subject = createSubject()

        subject.showShareExtension(url: URL(string: "https://www.google.com")!, sourceView: UIView(), toastContainer: UIView())

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is ShareExtensionCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is UIActivityViewController)
    }

    // MARK: - ParentCoordinatorDelegate

    func testRemoveChildCoordinator_whenDidFinishCalled() {
        let subject = createSubject()
        let childCoordinator = ShareExtensionCoordinator(
            alertContainer: UIView(),
            router: mockRouter,
            profile: profile)

        subject.add(child: childCoordinator)
        subject.didFinish(from: childCoordinator)

        XCTAssertEqual(subject.childCoordinators.count, 0)
    }

    // MARK: - Search route

    func testHandleSearchQuery_returnsTrue() {
        let query = "test query"
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = subject.handle(route: .searchQuery(query: query))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.handleQueryCalled)
        XCTAssertEqual(mbvc.handleQuery, query)
        XCTAssertEqual(mbvc.handleQueryCount, 1)
    }

    func testHandleSearch_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = subject.handle(route: .search(url: URL(string: "https://example.com")!,
                                                   isPrivate: false,
                                                   options: nil))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.switchToTabForURLOrOpenCalled)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenURL, URL(string: "https://example.com")!)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenCount, 1)
    }

    func testHandleSearchWithNormalMode_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = subject.handle(route: .search(url: URL(string: "https://example.com")!,
                                                   isPrivate: false,
                                                   options: [.switchToNormalMode]))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.switchToPrivacyModeCalled)
        XCTAssertFalse(mbvc.switchToPrivacyModeIsPrivate)
        XCTAssertTrue(mbvc.switchToTabForURLOrOpenCalled)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenURL, URL(string: "https://example.com")!)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenCount, 1)
    }

    func testHandleSearchWithNilURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = subject.handle(route: .search(url: nil, isPrivate: false))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.openBlankNewTabCalled)
        XCTAssertFalse(mbvc.openBlankNewTabIsPrivate)
        XCTAssertEqual(mbvc.openBlankNewTabCount, 1)
    }

    func testHandleSearchURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = subject.handle(route: .searchURL(url: URL(string: "https://example.com")!, tabId: "1234"))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.switchToTabForURLOrOpenCalled)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenURL, URL(string: "https://example.com")!)
        XCTAssertEqual(mbvc.switchToTabForURLOrOpenCount, 1)
    }

    func testHandleNilSearchURL_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let result = subject.handle(route: .searchURL(url: nil, tabId: "1234"))

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.openBlankNewTabCalled)
        XCTAssertFalse(mbvc.openBlankNewTabIsPrivate)
        XCTAssertEqual(mbvc.openBlankNewTabCount, 1)
    }

    // MARK: - Homepanel route

    func testHandleHomepanelBookmarks_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let route = routeBuilder.makeRoute(url: URL(string: "firefox://deep-link?url=/homepanel/bookmarks")!)
        let result = subject.handle(route: route!)

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.showLibraryCalled)
        XCTAssertEqual(mbvc.showLibraryPanel, .bookmarks)
        XCTAssertEqual(mbvc.showLibraryCount, 1)
    }

    func testHandleHomepanelHistory_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let route = routeBuilder.makeRoute(url: URL(string: "firefox://deep-link?url=/homepanel/history")!)
        let result = subject.handle(route: route!)

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.showLibraryCalled)
        XCTAssertEqual(mbvc.showLibraryPanel, .history)
        XCTAssertEqual(mbvc.showLibraryCount, 1)
    }

    func testHandleHomepanelReadingList_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let route = routeBuilder.makeRoute(url: URL(string: "firefox://deep-link?url=/homepanel/reading-list")!)
        let result = subject.handle(route: route!)

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.showLibraryCalled)
        XCTAssertEqual(mbvc.showLibraryPanel, .readingList)
        XCTAssertEqual(mbvc.showLibraryCount, 1)
    }

    func testHandleHomepanelDownloads_returnsTrue() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        let route = routeBuilder.makeRoute(url: URL(string: "firefox://deep-link?url=/homepanel/downloads")!)
        let result = subject.handle(route: route!)

        XCTAssertTrue(result)
        XCTAssertTrue(mbvc.showLibraryCalled)
        XCTAssertEqual(mbvc.showLibraryPanel, .downloads)
        XCTAssertEqual(mbvc.showLibraryCount, 1)
    }

    func testHandleHomepanelTopSites_returnsTrue() {
        // Given
        let topSitesURL = URL(string: "firefox://deep-link?url=/homepanel/top-sites")!
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let route = routeBuilder.makeRoute(url: topSitesURL)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mbvc.openURLInNewTabCount, 1)
        XCTAssertEqual(mbvc.openURLInNewTabURL, HomePanelType.topSites.internalUrl)
        XCTAssertEqual(mbvc.openURLInNewTabIsPrivate, false)
    }

    func testHandleNewPrivateTab_returnsTrue() {
        // Given
        let newPrivateTabURL = URL(string: "firefox://deep-link?url=/homepanel/new-private-tab")!
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let route = routeBuilder.makeRoute(url: newPrivateTabURL)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mbvc.openBlankNewTabCount, 1)
        XCTAssertFalse(mbvc.openBlankNewTabFocusLocationField)
        XCTAssertEqual(mbvc.openBlankNewTabIsPrivate, true)
    }

    func testHandleHomepanelNewTab_returnsTrue() {
        // Given
        let newTabURL = URL(string: "firefox://deep-link?url=/homepanel/new-tab")!
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let route = routeBuilder.makeRoute(url: newTabURL)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mbvc.openBlankNewTabCount, 1)
        XCTAssertFalse(mbvc.openBlankNewTabFocusLocationField)
        XCTAssertEqual(mbvc.openBlankNewTabIsPrivate, false)
    }

    // MARK: - Default browser route

    func testDefaultBrowser_systemSettings_handlesRoute() {
        let route = Route.defaultBrowser(section: .systemSettings)
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = subject.handle(route: route)

        XCTAssertTrue(result)
        XCTAssertEqual(applicationHelper.openSettingsCalled, 1)
    }

    func testDefaultBrowser_tutorial_handlesRoute() {
        let route = Route.defaultBrowser(section: .tutorial)
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = subject.handle(route: route)

        XCTAssertTrue(result)
        XCTAssertNotNil(mockRouter.presentedViewController as? DefaultBrowserOnboardingViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? LaunchCoordinator)
    }

    // MARK: - Glean route

    func testGleanRoute_handlesRoute() {
        let expectedURL = URL(string: "www.example.com")!
        let route = Route.glean(url: expectedURL)
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = subject.handle(route: route)

        XCTAssertTrue(result)
        XCTAssertEqual(glean.handleDeeplinkUrlCalled, 1)
        XCTAssertEqual(glean.savedHandleDeeplinkUrl, expectedURL)
    }

    // MARK: - Settings route

    func testGeneralSettingsRoute_showsGeneralSettingsPage() throws {
        let route = Route.settings(section: .general)
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = subject.handle(route: route)

        XCTAssertTrue(result)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? ThemedNavigationController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is AppSettingsTableViewController)
    }

    func testNewTabSettingsRoute_returnsNewTabSettingsPage() throws {
        let route = Route.SettingsSection.newTab
        let subject = createSubject()

        subject.legacyGetSettingsViewController(settingsSection: route) { result in
            XCTAssertTrue(result is NewTabContentSettingsViewController)
        }
    }

    func testHomepageSettingsRoute_returnsHomepageSettingsPage() throws {
        let route = Route.SettingsSection.homePage
        let subject = createSubject()

        subject.legacyGetSettingsViewController(settingsSection: route) { result in
            XCTAssertTrue(result is HomePageSettingViewController)
        }
    }

    func testMailtoSettingsRoute_returnsMailtoSettingsPage() throws {
        let route = Route.SettingsSection.mailto
        let subject = createSubject()

        subject.legacyGetSettingsViewController(settingsSection: route) { result in
            XCTAssertTrue(result is OpenWithSettingsViewController)
        }
    }

    func testSearchSettingsRoute_returnsSearchSettingsPage() throws {
        let route = Route.SettingsSection.search
        let subject = createSubject()

        subject.legacyGetSettingsViewController(settingsSection: route) { result in
            XCTAssertTrue(result is SearchSettingsTableViewController)
        }
    }

    func testClearPrivateDataSettingsRoute_returnsClearPrivateDataSettingsPage() throws {
        let route = Route.SettingsSection.clearPrivateData
        let subject = createSubject()

        subject.legacyGetSettingsViewController(settingsSection: route) { result in
            XCTAssertTrue(result is ClearPrivateDataTableViewController)
        }
    }

    func testFxaSettingsRoute_returnsFxaSettingsPage() throws {
        let route = Route.SettingsSection.fxa
        let subject = createSubject()

        subject.legacyGetSettingsViewController(settingsSection: route) { result in
            XCTAssertTrue(result is SyncContentSettingsViewController)
        }
    }

    func testThemeSettingsRoute_returnsThemeSettingsPage() throws {
        let route = Route.SettingsSection.theme
        let subject = createSubject()

        subject.legacyGetSettingsViewController(settingsSection: route) { result in
            XCTAssertTrue(result is ThemeSettingsController)
        }
    }

    func testWallpaperSettingsRoute_canShow_returnsWallpaperSettingsPage() throws {
        wallpaperManager.canSettingsBeShown = true
        let route = Route.SettingsSection.wallpaper
        let subject = createSubject()

        subject.legacyGetSettingsViewController(settingsSection: route) { result in
            XCTAssertTrue(result is WallpaperSettingsViewController)
        }
    }

    func testWallpaperSettingsRoute_cannotShow_returnsWallpaperSettingsPage() throws {
        wallpaperManager.canSettingsBeShown = false
        let route = Route.SettingsSection.wallpaper
        let subject = createSubject()

        subject.legacyGetSettingsViewController(settingsSection: route) { result in
            XCTAssertNil(result)
        }
    }

    func testSettingsRoute_addSettingsCoordinator() {
        let subject = createSubject(isSettingsCoordinatorEnabled: true)
        subject.browserHasLoaded()

        let result = subject.handle(route: .settings(section: .general))

        XCTAssertTrue(result)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? SettingsCoordinator)
    }

    func testSettingsRoute_addSettingsCoordinatorOnlyOnce() {
        let subject = createSubject(isSettingsCoordinatorEnabled: true)
        subject.browserHasLoaded()

        let result1 = subject.handle(route: .settings(section: .general))
        let result2 = subject.handle(route: .settings(section: .general))

        XCTAssertTrue(result1)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? SettingsCoordinator)
        XCTAssertFalse(result2)
    }

    func testPresentedCompletion_callsDidFinishSettings_removesChild() {
        let subject = createSubject(isSettingsCoordinatorEnabled: true)
        subject.browserHasLoaded()

        let result = subject.handle(route: .settings(section: .general))
        mockRouter.savedCompletion?()

        XCTAssertTrue(result)
        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testSettingsCoordinatorDelegate_openURLinNewTab() {
        let expectedURL = URL(string: "www.mozilla.com")!
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc

        subject.openURLinNewTab(expectedURL)

        XCTAssertEqual(mbvc.openURLInNewTabCount, 1)
        XCTAssertEqual(mbvc.openURLInNewTabURL, expectedURL)
    }

    func testSettingsCoordinatorDelegate_didFinishSettings_removesChild() {
        let subject = createSubject(isSettingsCoordinatorEnabled: true)
        subject.browserHasLoaded()

        let result = subject.handle(route: .settings(section: .general))
        let settingsCoordinator = subject.childCoordinators[0] as! SettingsCoordinator
        subject.didFinishSettings(from: settingsCoordinator)

        XCTAssertTrue(result)
        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testETPCoordinatorDelegate_settingsOpenPage() {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc

        subject.settingsOpenPage(settings: .contentBlocker)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? SettingsCoordinator)
    }

    func testEnhancedTrackingProtectionCoordinatorDelegate_didFinishETP_removesChild() {
        let subject = createSubject(isSettingsCoordinatorEnabled: true)
        subject.browserHasLoaded()

        subject.showEnhancedTrackingProtection(sourceView: UIView())
        let etpCoordinator = subject.childCoordinators[0] as! EnhancedTrackingProtectionCoordinator
        subject.didFinishEnhancedTrackingProtection(from: etpCoordinator)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    // MARK: - Sign in route

    func testHandleFxaSignIn_returnsTrue() {
        // Given
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let route = routeBuilder.makeRoute(url: URL(string: "firefox://fxa-signin?signin=coolcodes&user=foo&email=bar")!)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mbvc.presentSignInCount, 1)
        XCTAssertEqual(mbvc.presentSignInFlowType, .emailLoginFlow)
        XCTAssertEqual(mbvc.presentSignInFxaOptions, FxALaunchParams(entrypoint: .fxaDeepLinkNavigation, query: ["signin": "coolcodes", "user": "foo", "email": "bar"]))
        XCTAssertEqual(mbvc.presentSignInReferringPage, ReferringPage.none)
    }

    // MARK: - App action route

    func testHandleHandleQRCode_returnsTrue() {
        // Given
        let shortcutItem = UIApplicationShortcutItem(type: "com.example.app.QRCode", localizedTitle: "QR Code")
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let route = routeBuilder.makeRoute(shortcutItem: shortcutItem, tabSetting: .blankPage)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mbvc.qrCodeCount, 1)
    }

    func testHandleClosePrivateTabs_returnsTrue() {
        // Given
        let url = URL(string: "firefox://widget-small-quicklink-close-private-tabs")!
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc
        subject.browserHasLoaded()

        // When
        let route = routeBuilder.makeRoute(url: url)
        let result = subject.handle(route: route!)

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mbvc.closePrivateTabsCount, 1)
    }

    func testHandleShowOnboarding_returnsTrueAndShowsOnboarding() {
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = subject.handle(route: .action(action: .showIntroOnboarding))

        XCTAssertTrue(result)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? LaunchCoordinator)
    }

    // MARK: - Saved route

    func testSavesRoute_whenLaunchFinished() throws {
        let subject = createSubject()
        subject.findAndHandle(route: .defaultBrowser(section: .tutorial))
        subject.start(with: nil)

        subject.didFinishLaunch(from: LaunchCoordinator(router: mockRouter))

        XCTAssertNotNil(subject.savedRoute)
    }

    func testSavedRouteCalled_whenBrowserHasLoaded() throws {
        let subject = createSubject()
        subject.findAndHandle(route: .defaultBrowser(section: .tutorial))
        subject.start(with: nil)

        subject.browserHasLoaded()

        XCTAssertNotNil(mockRouter.presentedViewController as? DefaultBrowserOnboardingViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
    }

    func testSavesRoute_whenBrowserNotLoaded() {
        let subject = createSubject()

        let coordinator = subject.findAndHandle(route: .defaultBrowser(section: .tutorial))

        XCTAssertNotNil(subject.savedRoute)
        XCTAssertNil(coordinator)
    }

    func testOneLibraryCoordinatorInstanceExists_whenPresetingMultipleLibraryTabs() {
        let subject = createSubject()

        // When the coordinator is created, there should no instance of LibraryCoordinator
        XCTAssertFalse(subject.childCoordinators.contains { $0 is LibraryCoordinator })

        // We show the library with bookmarks tab
        subject.show(homepanelSection: .bookmarks)

        // Checking to see if there's one library coordinator instance presented
        XCTAssertEqual(subject.childCoordinators.filter { $0 is LibraryCoordinator }.count, 1)

        // We try to show the library again on downloads tab (notice for now the Done button is not connected and will not remove the coordinator). Showing the library again should use the existing instance of the LibraryCoordinator
        subject.show(homepanelSection: .downloads)

        // Checking to see if there's only one library coordinator instance presented
        XCTAssertEqual(subject.childCoordinators.filter { $0 is LibraryCoordinator }.count, 1)
    }

    func testTappingOpenUrl_CallsTheDidSelectUrlOnBrowserViewController() throws {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc

        // We show the library with bookmarks tab
        subject.show(homepanelSection: .bookmarks)

        let coordinator = try XCTUnwrap(subject.childCoordinators.first { $0 is LibraryCoordinator } as? LibraryCoordinator)
        let url = URL(string: "http://google.com")!
        coordinator.libraryPanel(didSelectURL: url, visitType: .bookmark)

        XCTAssertTrue(mbvc.didSelectURLCalled)
        XCTAssertEqual(mbvc.lastOpenedURL, url)
        XCTAssertEqual(mbvc.lastVisitType, .bookmark)
    }

    func testTappingOpenUrlInNewTab_CallsTheDidSelectUrlInNewTapOnBrowserViewController() throws {
        let subject = createSubject()
        let mbvc = MockBrowserViewController(profile: profile, tabManager: tabManager)
        subject.browserViewController = mbvc

        // We show the library with bookmarks tab
        subject.show(homepanelSection: .bookmarks)

        let coordinator = try XCTUnwrap(subject.childCoordinators.first { $0 is LibraryCoordinator } as? LibraryCoordinator)
        let url = URL(string: "http://google.com")!
        coordinator.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: true)

        XCTAssertTrue(mbvc.didRequestToOpenInNewTabCalled)
        XCTAssertEqual(mbvc.lastOpenedURL, url)
        XCTAssertTrue(mbvc.isPrivate)
    }

    // MARK: - Helpers
    private func createSubject(isSettingsCoordinatorEnabled: Bool = false,
                               file: StaticString = #file,
                               line: UInt = #line) -> BrowserCoordinator {
        routeBuilder.configure(isPrivate: false, prefs: profile.prefs)
        let subject = BrowserCoordinator(router: mockRouter,
                                         screenshotService: screenshotService,
                                         profile: profile,
                                         glean: glean,
                                         applicationHelper: applicationHelper,
                                         wallpaperManager: wallpaperManager,
                                         isSettingsCoordinatorEnabled: isSettingsCoordinatorEnabled)

        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }
}
