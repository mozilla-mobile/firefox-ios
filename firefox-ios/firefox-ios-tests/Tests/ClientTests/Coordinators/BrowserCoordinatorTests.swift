// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ComponentLibrary
import MozillaAppServices
import WebKit
import XCTest
import GCDWebServers
import SummarizeKit

@testable import Client

@MainActor
final class BrowserCoordinatorTests: XCTestCase, FeatureFlaggable {
    private var mockRouter: MockRouter!
    private var profile: MockProfile!
    private var overlayModeManager: MockOverlayModeManager!
    private var screenshotService: ScreenshotService!
    private var tabManager: MockTabManager!
    private var applicationHelper: MockApplicationHelper!
    private var glean: MockGleanWrapper!
    private var scrollDelegate: MockStatusBarScrollDelegate!
    private var browserViewController: MockBrowserViewController!
    let windowUUID: WindowUUID = .XCTestDefaultUUID

    override func setUp() async throws {
        try await super.setUp()
        let mockTabManager = MockTabManager()
        self.tabManager = mockTabManager
        profile = MockProfile()
        DependencyHelperMock().bootstrapDependencies(injectedTabManager: mockTabManager)
        LegacyFeatureFlagsManager.shared.initializeDeveloperFeatures(with: profile)
        setIsAppleSummarizerEnabled(false)
        setIsHostedSummarizerEnabled(false)
        setIsDeeplinkOptimizationRefactorEnabled(false)
        mockRouter = MockRouter(navigationController: MockNavigationController())
        overlayModeManager = MockOverlayModeManager()
        screenshotService = ScreenshotService()
        applicationHelper = MockApplicationHelper()
        glean = MockGleanWrapper()
        scrollDelegate = MockStatusBarScrollDelegate()
        browserViewController = MockBrowserViewController(profile: profile, tabManager: tabManager)
    }

    override func tearDown() async throws {
        profile.shutdown()
        mockRouter = nil
        profile = nil
        overlayModeManager = nil
        screenshotService = nil
        tabManager = nil
        applicationHelper = nil
        glean = nil
        scrollDelegate = nil
        browserViewController = nil
        DependencyHelperMock().reset()
        try await super.tearDown()
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
        // TODO: FXIOS-12947 - Add tests for ToU Feature implementation
        if !featureFlags.isFeatureEnabled(.touFeature, checking: .buildOnly) {
            XCTAssertNotNil(mockRouter.rootViewController as? BrowserViewController)
            XCTAssertEqual(mockRouter.setRootViewControllerCalled, 1)
            XCTAssertTrue(subject.childCoordinators.isEmpty)
        }
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

    // MARK: - Show homepage

    func testShowHomepage_addsOneHomepageOnly() {
        let subject = createSubject()
        subject.showHomepage(overlayManager: overlayModeManager,
                             isZeroSearch: true,
                             statusBarScrollDelegate: scrollDelegate,
                             toastContainer: UIView())

        let secondHomepage = HomepageViewController(windowUUID: windowUUID,
                                                    tabManager: MockTabManager(),
                                                    overlayManager: overlayModeManager,
                                                    toastContainer: UIView())
        XCTAssertFalse(subject.browserViewController.contentContainer.canAdd(content: secondHomepage))
        XCTAssertNotNil(subject.homepageViewController)
        XCTAssertNil(subject.webviewController)
    }

    func testShowHomepage_reuseExistingHomepage() {
        let subject = createSubject()
        subject.showHomepage(overlayManager: overlayModeManager,
                             isZeroSearch: true,
                             statusBarScrollDelegate: scrollDelegate,
                             toastContainer: UIView())
        let firstHomepage = subject.homepageViewController
        XCTAssertNotNil(subject.homepageViewController)

        subject.showHomepage(overlayManager: overlayModeManager,
                             isZeroSearch: true,
                             statusBarScrollDelegate: scrollDelegate,
                             toastContainer: UIView())
        let secondHomepage = subject.homepageViewController
        XCTAssertEqual(firstHomepage, secondHomepage)
    }

    // MARK: - Show new homepage

    func testShowNewHomepage_setsProperViewController() {
        let subject = createSubject()
        subject.showHomepage(
            overlayManager: overlayModeManager,
            isZeroSearch: false,
            statusBarScrollDelegate: scrollDelegate,
            toastContainer: UIView()
        )

        XCTAssertNotNil(subject.homepageViewController)
        XCTAssertNil(subject.webviewController)
    }

    func testShowNewHomepage_hasSameInstance() {
        let subject = createSubject()
        subject.showHomepage(
            overlayManager: overlayModeManager,
            isZeroSearch: false,
            statusBarScrollDelegate: scrollDelegate,
            toastContainer: UIView()
        )
        let firstHomepage = subject.homepageViewController
        XCTAssertNotNil(subject.homepageViewController)

        subject.showHomepage(
            overlayManager: overlayModeManager,
            isZeroSearch: false,
            statusBarScrollDelegate: scrollDelegate,
            toastContainer: UIView()
        )
        let secondHomepage = subject.homepageViewController
        XCTAssertEqual(firstHomepage, secondHomepage)
    }

    // MARK: - Show webview

    func testShowWebview_embedNewWebview() {
        let webview = WKWebView()
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.show(webView: webview)

        XCTAssertNotNil(subject.webviewController)
        XCTAssertEqual(browserViewController.embedContentCalled, 1)
        XCTAssertEqual(browserViewController.saveEmbeddedContent?.contentType, .webview)
    }

    func testShowWebview_reuseExistingWebview() {
        let webview = WKWebView()
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.show(webView: webview)
        let firstWebview = subject.webviewController
        XCTAssertNotNil(firstWebview)

        subject.show(webView: webview)
        let secondWebview = subject.webviewController

        XCTAssertEqual(firstWebview, secondWebview)
        XCTAssertEqual(browserViewController.embedContentCalled, 1)
        XCTAssertEqual(browserViewController.frontEmbeddedContentCalled, 1)
        XCTAssertEqual(browserViewController.saveEmbeddedContent?.contentType, .webview)
    }

    func testShowWebview_setsScreenshotService() {
        let webview = WKWebView()
        let subject = createSubject()
        subject.show(webView: webview)

        XCTAssertNotNil(screenshotService.screenshotableView)
    }

    func testShowWebview_popsShortcutLibrary() {
        let webview = WKWebView()
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.showShortcutsLibrary()

        subject.show(webView: webview)

        XCTAssertEqual(mockRouter.popViewControllerCalled, 1)
    }

    // MARK: - BrowserNavigationHandler

    func testShowSettings() throws {
        let subject = createSubject()
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

        if featureFlags.isFeatureEnabled(.trackingProtectionRefactor, checking: .buildOnly) {
            XCTAssertTrue(mockRouter.presentedViewController is UINavigationController)
        } else {
            XCTAssertTrue(mockRouter.presentedViewController is EnhancedTrackingProtectionMenuVC)
        }
    }

    func testStartShareSheetCoordinator_addsShareSheetCoordinator() {
        let subject = createSubject()

        let exp = expectation(description: "present called")
        mockRouter.onPresent = { exp.fulfill() }

        subject.startShareSheetCoordinator(
            shareType: .site(url: URL(string: "https://www.google.com")!),
            shareMessage: ShareMessage(message: "Test Message", subtitle: "Test Subtitle"),
            sourceView: UIView(),
            sourceRect: .zero,
            toastContainer: UIView(),
            popoverArrowDirection: .up
        )

        wait(for: [exp], timeout: 5)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is ShareSheetCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is UIActivityViewController)
    }

    func testStartShareSheetCoordinator_isSharingTabWithTemporaryDocument_upgradesTabShareToFileShare() throws {
        let testWebURL = URL(string: "https://mozilla.org")!
        let testFileURL = URL(string: "file://some/file/url")!
        let testWebpageDisplayTitle = "Mozilla"
        let testShareMessage = ShareMessage(message: "Test Message", subtitle: "Test Subtitle")
        let mockTemporaryDocument = MockTemporaryDocument(withFileURL: testFileURL)
        let testTab = MockShareTab(
            title: testWebpageDisplayTitle,
            url: testWebURL,
            canonicalURL: testWebURL,
            withTemporaryDocument: mockTemporaryDocument
        )

        let mockServerURL = try startMockServer()

        let subject = createSubject()

        subject.startShareSheetCoordinator(
            shareType: .tab(url: mockServerURL, tab: testTab),
            shareMessage: testShareMessage,
            sourceView: UIView(),
            sourceRect: CGRect(),
            toastContainer: UIView(),
            popoverArrowDirection: .up
        )

        let exp = expectation(description: "present called")
        mockRouter.onPresent = { exp.fulfill() }

        wait(for: [exp], timeout: 5.0)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is ShareSheetCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is UIActivityViewController)
        // Right now we have no interface to check the ShareType passed in to ShareSheetCoordinator's start() call, but this
        // can tell us that there was an attempt to download a TemporaryDocument for a tab type share, which is sufficient.
        XCTAssertEqual(mockTemporaryDocument.downloadAsyncCalled, 1)
    }

    func testShowCreditCardAutofill_addsCredentialAutofillCoordinator() {
        let subject = createSubject()

        subject.showCreditCardAutofill(
            creditCard: nil,
            decryptedCard: nil,
            viewType: .save,
            frame: nil,
            alertContainer: UIView()
        )

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is CredentialAutofillCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is BottomSheetViewController)
    }

    func testShowSavedLoginAutofill_addsCredentialAutofillCoordinator() {
        let subject = createSubject()
        let testURL = URL(string: "https://example.com")!
        let currentRequestId = "testRequestID"
        let field = FocusFieldType.password
        subject.showSavedLoginAutofill(tabURL: testURL, currentRequestId: currentRequestId, field: field)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is CredentialAutofillCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is BottomSheetViewController)
    }

    func testShowRequiredPassCode_addsCredentialAutofillCoordinator() {
        let subject = createSubject()

        subject.showRequiredPassCode()

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is CredentialAutofillCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is DevicePasscodeRequiredViewController)
    }

    func testShowQRCode_addsQRCodeCoordinator() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()
        subject.showQRCode(delegate: delegate)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is QRCodeCoordinator)
    }

    func testShowQRCode_presentsQRCodeNavigationController() {
        let subject = createSubject()
        let delegate = MockQRCodeViewControllerDelegate()
        subject.showQRCode(delegate: delegate)

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is QRCodeNavigationController)
    }

    func testShowBackForwardList_presentsBackForwardListViewController() {
        let mockTab = Tab(profile: profile, windowUUID: windowUUID)
        mockTab.url = URL(string: "https://www.google.com")
        mockTab.createWebview(configuration: .init())
        tabManager.selectedTab = mockTab

        let subject = createSubject()
        subject.showBackForwardList()

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is BackForwardListViewController)
    }

    func testShowTabTray() throws {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        let subject = createSubject()
        subject.showTabTray(selectedPanel: .tabs)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? TabTrayCoordinator)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? DismissableNavigationViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is TabTrayViewController)
    }

    func testShowTabTray_withExperiment() throws {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: true)
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.showTabTray(selectedPanel: .tabs)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? TabTrayCoordinator)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? DismissableNavigationViewController)
        XCTAssertEqual(mockRouter.presentCalledWithAnimation, 1)
        XCTAssertTrue(presentedVC.topViewController is TabTrayViewController)
    }

    func testShowTabTray_withPrivateTabs_withoutExperiment_showDefaultPresentation() throws {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        let subject = createSubject()
        subject.showTabTray(selectedPanel: .privateTabs)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? TabTrayCoordinator)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? DismissableNavigationViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is TabTrayViewController)
    }

    func testShowTabTray_withPrivateTabs_withExperiment_showAnimatedPresentation() throws {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: true)
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.showTabTray(selectedPanel: .privateTabs)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? TabTrayCoordinator)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? DismissableNavigationViewController)
        XCTAssertEqual(mockRouter.presentCalledWithAnimation, 1)
        XCTAssertTrue(presentedVC.topViewController is TabTrayViewController)
    }

    func testShowTabTray_withSyncedTabs_withoutExperiment_showDefaultPresentation() throws {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: false)
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.showTabTray(selectedPanel: .syncedTabs)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? TabTrayCoordinator)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? DismissableNavigationViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is TabTrayViewController)
    }

    func testShowTabTray_withSyncedTabs_withExperiment_showDefaultPresentation() throws {
        setupNimbusTabTrayUIExperimentTesting(isEnabled: true)
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.showTabTray(selectedPanel: .syncedTabs)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? TabTrayCoordinator)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? DismissableNavigationViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is TabTrayViewController)
    }

    func testDismissTabTray_removesChild() throws {
        let subject = createSubject()
        subject.showTabTray(selectedPanel: .tabs)
        guard let tabTrayCoordinator = subject.childCoordinators[0] as? TabTrayCoordinator else {
            XCTFail("Tab tray coordinator was expected to be resolved")
            return
        }

        subject.didDismissTabTray(from: tabTrayCoordinator)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testShowPasswordGenerator_presentsPasswordGeneratorBottomSheet() {
        let subject = createSubject()
        let mockTab = Tab(profile: profile, windowUUID: windowUUID)
        let mockEvaluator = MockPasswordGeneratorScriptEvaluator()
        let frameContext = PasswordGeneratorFrameContext(origin: "https://foo.com",
                                                         host: "foo.com",
                                                         scriptEvaluator: mockEvaluator,
                                                         frameInfo: nil)
        subject.showPasswordGenerator(tab: mockTab, frameContext: frameContext)

        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is BottomSheetViewController)
    }

    func testShowContextMenu_addsContextMenuCoordinator() {
        let subject = createSubject()
        let config = ContextMenuConfiguration(site: nil, menuType: nil, sourceView: nil, toastContainer: UIView())
        subject.showContextMenu(for: config)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is ContextMenuCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is PhotonActionSheet)
    }

    func testShowLoadingDocument() {
        let subject = createSubject()
        subject.browserViewController = browserViewController

        subject.showDocumentLoading()

        XCTAssertEqual(browserViewController.removeDocumentLoadingViewCalled, 0)
        XCTAssertEqual(browserViewController.showDocumentLoadingViewCalled, 1)
    }

    func testRemoveDocumentLoading() {
        let subject = createSubject()
        subject.browserViewController = browserViewController

        subject.removeDocumentLoading()

        XCTAssertEqual(browserViewController.showDocumentLoadingViewCalled, 0)
        XCTAssertEqual(browserViewController.removeDocumentLoadingViewCalled, 1)
    }

    // MARK: - Summarize Panel

    func testShowSummarizePanel_whenSummarizeFeatureEnabled_showsPanel() async {
        setIsHostedSummarizerEnabled(true)
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: windowUUID)
        tab.webView = MockTabWebView(tab: tab)
        tabManager.selectedTab = tab
        subject.browserViewController = browserViewController

        subject.showSummarizePanel(.mainMenu, config: SummarizerConfig(instructions: "Test instructions", options: [:]))

        let childCoordinator = subject.childCoordinators.first
        XCTAssertTrue(childCoordinator is SummarizeCoordinator)

        /// Yield the main actor for one run loop, ensuring the animations on the mock BVC's `view.snapshot` can complete.
        /// See PR #31137 for more details.
        await Task.yield()
    }

    func testShowSummarizePanel_whenSelectedTabIsHomePage_doesntShowPanel() {
        setIsHostedSummarizerEnabled(true)
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: windowUUID, isHomePage: true)
        tab.webView = MockTabWebView(tab: tab)
        tabManager.selectedTab = tab
        subject.browserViewController = browserViewController

        subject.showSummarizePanel(.mainMenu, config: SummarizerConfig(instructions: "Test instructions", options: [:]))

        XCTAssertNil(subject.childCoordinators.first(where: {
            $0 is SummarizeCoordinator
        }))
    }

    func testShowSummarizePanel_whenSummarizeFeatureIsDisabled_doesntShowPanel() {
        let subject = createSubject()
        subject.browserViewController = browserViewController

        subject.showSummarizePanel(.mainMenu, config: SummarizerConfig(instructions: "Test instructions", options: [:]))
        XCTAssertNil(subject.childCoordinators.first(where: {
            $0 is SummarizeCoordinator
        }))
    }

    func testShowSummarizePanel_whenSummarizeCoordinatorAlreadyPresent_doesntAddNewOne() async {
        setIsHostedSummarizerEnabled(true)
        let subject = createSubject()
        let tab = MockTab(profile: profile, windowUUID: windowUUID)
        tab.webView = MockTabWebView(tab: tab)
        tabManager.selectedTab = tab
        subject.browserViewController = browserViewController

        // Calling twice showSummarizePanel has to add just once the SummarizeCoordinator.
        subject.showSummarizePanel(.mainMenu, config: SummarizerConfig(instructions: "instructions", options: [:]))
        subject.showSummarizePanel(.mainMenu, config: SummarizerConfig(instructions: "instructions", options: [:]))

        let numberOfSummarizeCoordinators = subject.childCoordinators.count {
            $0 is SummarizeCoordinator
        }
        XCTAssertEqual(numberOfSummarizeCoordinators, 1)

        /// Yield the main actor for one run loop, ensuring the animations on the mock BVC's `view.snapshot` can complete.
        /// See PR #31137 for more details.
        await Task.yield()
    }

    // MARK: - Shortcuts Library

    func testShowShortcutsLibrary_showsShortcutsLibrary() throws {
        let subject = createSubject()

        subject.showShortcutsLibrary()

        XCTAssertNotNil(mockRouter.pushedViewController as? ShortcutsLibraryViewController)
        XCTAssertEqual(mockRouter.pushCalled, 1)
    }

    // MARK: - Stories Feed

    func testShowStoriesFeed_showsStoriesFeed() throws {
        let subject = createSubject()

        subject.showStoriesFeed()

        XCTAssertNotNil(mockRouter.pushedViewController as? StoriesFeedViewController)
        XCTAssertEqual(mockRouter.pushCalled, 1)
    }

    func testShowStoriesWebview_showsStoriesWebview() throws {
        let subject = createSubject()

        subject.showStoriesWebView(url: URL(string: "https://www.mozilla.com"))

        XCTAssertNotNil(mockRouter.pushedViewController as? StoriesWebviewViewController)
        XCTAssertEqual(mockRouter.pushCalled, 1)
    }

    func testShowPrivacyNoticeLink_showsStoriesWebview() throws {
        let subject = createSubject()

        guard let url = URL(string: "https://www.mozilla.com") else { return }

        subject.showPrivacyNoticeLink(url: url)

        XCTAssertNotNil(mockRouter.presentedViewController as? TermsOfUseLinkViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
    }

    func testPopToBVC_popsViewControllers() {
        let subject = createSubject()

        mockRouter.push(browserViewController, animated: false)
        (0...1).forEach { _ in
            mockRouter.push(UIViewController(), animated: false)
        }

        subject.popToBVC()

        XCTAssertEqual(mockRouter.popToViewControllerCalled, 1)
    }

    func testShouldShowNewTabToast_returnsTrue() throws {
        let subject = createSubject()

        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let shouldShowNewTabToast = subject.shouldShowNewTabToast(tab: tab)

        XCTAssertTrue(shouldShowNewTabToast)
    }

    func testShouldShowNewTabToast_returnsFalse() throws {
        let subject = createSubject()

        subject.showShortcutsLibrary()
        let tab = Tab(profile: profile, windowUUID: .XCTestDefaultUUID)
        let shouldShowNewTabToast = subject.shouldShowNewTabToast(tab: tab)

        XCTAssertFalse(shouldShowNewTabToast)
    }

    // MARK: - ParentCoordinatorDelegate

    func testRemoveChildCoordinator_whenDidFinishCalled() {
        let subject = createSubject()
        let childCoordinator = ShareSheetCoordinator(
            alertContainer: UIView(),
            router: mockRouter,
            profile: profile,
            tabManager: tabManager)

        subject.add(child: childCoordinator)
        subject.didFinish(from: childCoordinator)

        XCTAssertEqual(subject.childCoordinators.count, 0)
    }

    // MARK: - Search route

    func testHandleSearchQuery_returnsTrue() {
        let query = "test query"
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .searchQuery(query: query, isPrivate: false))

        XCTAssertTrue(result)
        XCTAssertTrue(browserViewController.handleQueryCalled)
        XCTAssertEqual(browserViewController.handleQuery, query)
        XCTAssertEqual(browserViewController.handleQueryCount, 1)
    }

    func testHandleSearch_returnsTrue() {
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .search(url: URL(string: "https://example.com")!,
                                                                    isPrivate: false,
                                                                    options: nil))

        XCTAssertTrue(result)
        XCTAssertTrue(browserViewController.switchToTabForURLOrOpenCalled)
        XCTAssertEqual(browserViewController.switchToTabForURLOrOpenURL, URL(string: "https://example.com")!)
        XCTAssertEqual(browserViewController.switchToTabForURLOrOpenCount, 1)
    }

    func testHandleSearchWithNormalMode_returnsTrue() {
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .search(url: URL(string: "https://example.com")!,
                                                                    isPrivate: false))

        XCTAssertTrue(result)
        XCTAssertTrue(browserViewController.switchToTabForURLOrOpenCalled)
        XCTAssertEqual(browserViewController.switchToTabForURLOrOpenURL, URL(string: "https://example.com")!)
        XCTAssertEqual(browserViewController.switchToTabForURLOrOpenCount, 1)
    }

    func testHandleSearchWithNilURL_returnsTrue() {
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .search(url: nil, isPrivate: false))

        XCTAssertTrue(result)
        XCTAssertFalse(browserViewController.openBlankNewTabCalled)
        XCTAssertFalse(browserViewController.openBlankNewTabIsPrivate)
        XCTAssertEqual(browserViewController.openBlankNewTabCount, 0)
    }

    func testHandleSearchURL_returnsTrue() {
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(
            subject,
            route: .searchURL(
                url: URL(string: "https://example.com")!,
                tabId: "1234"
            )
        )

        XCTAssertTrue(result)
        XCTAssertTrue(browserViewController.switchToTabForURLOrOpenCalled)
        XCTAssertEqual(browserViewController.switchToTabForURLOrOpenURL, URL(string: "https://example.com")!)
        XCTAssertEqual(browserViewController.switchToTabForURLOrOpenCount, 1)
    }

    func testHandleNilSearchURL_returnsTrue() {
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .searchURL(url: nil, tabId: "1234"))

        XCTAssertTrue(result)
        XCTAssertTrue(browserViewController.openBlankNewTabCalled)
        XCTAssertFalse(browserViewController.openBlankNewTabIsPrivate)
        XCTAssertEqual(browserViewController.openBlankNewTabCount, 1)
    }

    // MARK: - Homepanel route

    func testHandleHomepanelBookmarks_returnsTrue() {
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .homepanel(section: .bookmarks))

        XCTAssertTrue(result)
        XCTAssertTrue(browserViewController.showLibraryCalled)
        XCTAssertEqual(browserViewController.showLibraryPanel, .bookmarks)
        XCTAssertEqual(browserViewController.showLibraryCount, 1)
    }

    func testHandleHomepanelHistory_returnsTrue() {
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .homepanel(section: .history))

        XCTAssertTrue(result)
        XCTAssertTrue(browserViewController.showLibraryCalled)
        XCTAssertEqual(browserViewController.showLibraryPanel, .history)
        XCTAssertEqual(browserViewController.showLibraryCount, 1)
    }

    func testHandleHomepanelReadingList_returnsTrue() {
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .homepanel(section: .readingList))

        XCTAssertTrue(result)
        XCTAssertTrue(browserViewController.showLibraryCalled)
        XCTAssertEqual(browserViewController.showLibraryPanel, .readingList)
        XCTAssertEqual(browserViewController.showLibraryCount, 1)
    }

    func testHandleHomepanelDownloads_returnsTrue() {
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .homepanel(section: .downloads))

        XCTAssertTrue(result)
        XCTAssertTrue(browserViewController.showLibraryCalled)
        XCTAssertEqual(browserViewController.showLibraryPanel, .downloads)
        XCTAssertEqual(browserViewController.showLibraryCount, 1)
    }

    func testHandleHomepanelTopSites_returnsTrue() {
        // Given
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        // When
        let result = testCanHandleAndHandle(subject, route: .homepanel(section: .topSites))

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(browserViewController.openURLInNewTabCount, 1)
        XCTAssertEqual(browserViewController.openURLInNewTabURL, HomePanelType.topSites.internalUrl)
        XCTAssertEqual(browserViewController.openURLInNewTabIsPrivate, false)
    }

    func testHandleNewPrivateTab_returnsTrue() {
        // Given
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        // When
        let result = testCanHandleAndHandle(subject, route: .search(url: nil, isPrivate: true))

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(browserViewController.openBlankNewTabCount, 0)
        XCTAssertFalse(browserViewController.openBlankNewTabFocusLocationField)
        XCTAssertEqual(browserViewController.openBlankNewTabIsPrivate, false)
    }

    func testHandleHomepanelNewTab_returnsTrue() {
        // Given
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        // When
        let result = testCanHandleAndHandle(subject, route: .search(url: nil, isPrivate: false))

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(browserViewController.openBlankNewTabCount, 0)
        XCTAssertFalse(browserViewController.openBlankNewTabFocusLocationField)
        XCTAssertEqual(browserViewController.openBlankNewTabIsPrivate, false)
    }

    // MARK: - Default browser route

    func testDefaultBrowser_systemSettings_handlesRoute() {
        let route = Route.defaultBrowser(section: .systemSettings)
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: route)

        XCTAssertTrue(result)
        XCTAssertEqual(applicationHelper.openSettingsCalled, 1)
    }

    func testDefaultBrowser_tutorial_handlesRoute() {
        let route = Route.defaultBrowser(section: .tutorial)
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: route)

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

        let result = testCanHandleAndHandle(subject, route: route)

        XCTAssertTrue(result)
        XCTAssertEqual(glean.handleDeeplinkUrlCalled, 1)
        XCTAssertEqual(glean.savedHandleDeeplinkUrl, expectedURL)
    }

    // MARK: - Settings route

    func testGeneralSettingsRoute_showsGeneralSettingsPage() throws {
        let route = Route.settings(section: .general)
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: route)

        XCTAssertTrue(result)
        let presentedVC = try XCTUnwrap(mockRouter.presentedViewController as? ThemedNavigationController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(presentedVC.topViewController is AppSettingsTableViewController)
    }

    func testSettingsRoute_addSettingsCoordinator() {
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .settings(section: .general))

        XCTAssertTrue(result)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? SettingsCoordinator)
    }

    func testSettingsRoute_addSettingsCoordinatorOnlyOnce() {
        let subject = createSubject()
        subject.browserHasLoaded()

        let result1 = testCanHandleAndHandle(subject, route: .settings(section: .general))
        let result2 = testCanHandleAndHandle(subject, route: .settings(section: .general))

        XCTAssertTrue(result1)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? SettingsCoordinator)
        XCTAssertFalse(result2)
    }

    func testPresentedCompletion_callsDidFinishSettings_removesChild() {
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .settings(section: .general))
        mockRouter.savedCompletion?()

        XCTAssertTrue(result)
    }

    func testSettingsCoordinatorDelegate_openURLinNewTab() {
        let expectedURL = URL(string: "www.mozilla.com")!
        let subject = createSubject()
        subject.browserViewController = browserViewController

        subject.openURLinNewTab(expectedURL)

        XCTAssertEqual(browserViewController.openURLInNewTabCount, 1)
        XCTAssertEqual(browserViewController.openURLInNewTabURL, expectedURL)
    }

    func testSettingsCoordinatorDelegate_didFinishSettings_removesChild() {
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .settings(section: .general))
        guard let settingsCoordinator = subject.childCoordinators[0] as? SettingsCoordinator else {
            return XCTFail("settingsCoordinator was not found")
        }
        subject.didFinishSettings(from: settingsCoordinator)

        XCTAssertTrue(result)
        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    func testETPCoordinatorDelegate_settingsOpenPage() {
        let subject = createSubject()
        subject.browserViewController = browserViewController

        subject.settingsOpenPage(settings: .contentBlocker)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? SettingsCoordinator)
    }

    func testEnhancedTrackingProtectionCoordinatorDelegate_didFinishETP_removesChild() {
        let subject = createSubject()
        subject.browserHasLoaded()

        subject.showEnhancedTrackingProtection(sourceView: UIView())
        guard let etpCoordinator = subject.childCoordinators[0] as? EnhancedTrackingProtectionCoordinator else {
            return XCTFail("etpCoordinator was not found")
        }
        subject.didFinishEnhancedTrackingProtection(from: etpCoordinator)

        XCTAssertEqual(mockRouter.dismissCalled, 1)
        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    // MARK: - Sign in route

    func testHandleFxaSignIn_returnsTrue() {
        // Given
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        // When
        let params = FxALaunchParams(entrypoint: .fxaDeepLinkNavigation,
                                     query: ["signin": "coolcodes", "user": "foo", "email": "bar"])
        let result = testCanHandleAndHandle(subject, route: .fxaSignIn(params: params))

        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(browserViewController.presentSignInCount, 1)
        XCTAssertEqual(browserViewController.presentSignInFlowType, .emailLoginFlow)
        XCTAssertEqual(browserViewController.presentSignInFxaOptions, params)
        XCTAssertEqual(browserViewController.presentSignInReferringPage, ReferringPage.none)
    }

    // MARK: - App action route

    func testHandleClosePrivateTabs_returnsTrue() {
        // Given
        let subject = createSubject()
        subject.browserViewController = browserViewController
        subject.browserHasLoaded()

        // When
        let result = testCanHandleAndHandle(subject, route: .action(action: .closePrivateTabs))

        // Then
        XCTAssertTrue(result)
        guard let windowManager = (AppContainer.shared.resolve() as WindowManager) as? MockWindowManager else {
            return XCTFail("windowManager was not found")
        }
        XCTAssertEqual(windowManager.closePrivateTabsMultiActionCalled, 1)
    }

    func testHandleShowOnboarding_returnsTrueAndShowsOnboarding() {
        let subject = createSubject()
        subject.browserHasLoaded()

        let result = testCanHandleAndHandle(subject, route: .action(action: .showIntroOnboarding))

        XCTAssertTrue(result)
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertNotNil(subject.childCoordinators[0] as? LaunchCoordinator)
    }

    // MARK: - Saved route

    func testSavesRoute_whenLaunchFinished() throws {
        let subject = createSubject()
        subject.findAndHandle(route: .defaultBrowser(section: .tutorial))
        subject.start(with: nil)

        subject.didFinishLaunch(
            from: LaunchCoordinator(
                router: mockRouter,
                windowUUID: .XCTestDefaultUUID
            )
        )

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

    func testSavesRoute_whenTabManagerIsRestoring() {
        tabManager.isRestoringTabs = true
        let subject = createSubject()
        subject.browserHasLoaded()

        let coordinator = subject.findAndHandle(route: .defaultBrowser(section: .tutorial))

        XCTAssertNotNil(subject.savedRoute)
        XCTAssertNil(coordinator)
    }

    func testSavedRouteCalled_whenRestoredTabsIsCalled() {
        tabManager.isRestoringTabs = true
        let subject = createSubject()
        subject.browserHasLoaded()
        subject.findAndHandle(route: .defaultBrowser(section: .tutorial))

        tabManager.isRestoringTabs = false
        subject.tabManagerDidRestoreTabs(tabManager)

        XCTAssertNotNil(mockRouter.presentedViewController as? DefaultBrowserOnboardingViewController)
        XCTAssertEqual(mockRouter.presentCalled, 1)
    }

    // MARK: - Library

    func testOneLibraryCoordinatorInstanceExists_whenPresetingMultipleLibraryTabs() {
        let subject = createSubject()

        // When the coordinator is created, there should no instance of LibraryCoordinator
        XCTAssertFalse(subject.childCoordinators.contains { $0 is LibraryCoordinator })

        // We show the library with bookmarks tab
        subject.show(homepanelSection: .bookmarks)

        // Checking to see if there's one library coordinator instance presented
        XCTAssertEqual(subject.childCoordinators.filter { $0 is LibraryCoordinator }.count, 1)

        // We try to show the library again on downloads tab (notice for now the Done
        // button is not connected and will not remove the coordinator). Showing the
        // library again should use the existing instance of the LibraryCoordinator
        subject.show(homepanelSection: .downloads)

        // Checking to see if there's only one library coordinator instance presented
        XCTAssertEqual(subject.childCoordinators.filter { $0 is LibraryCoordinator }.count, 1)
    }

    func testTappingOpenUrl_CallsTheDidSelectUrlOnBrowserViewController() throws {
        let subject = createSubject()
        subject.browserViewController = browserViewController

        // We show the library with bookmarks tab
        subject.show(homepanelSection: .bookmarks)

        let coordinator = try XCTUnwrap(
            subject.childCoordinators.first { $0 is LibraryCoordinator } as? LibraryCoordinator)
        let url = URL(string: "http://google.com")!
        coordinator.libraryPanel(didSelectURL: url, visitType: .bookmark)

        XCTAssertTrue(browserViewController.didSelectURLCalled)
        XCTAssertEqual(browserViewController.lastOpenedURL, url)
        XCTAssertEqual(browserViewController.lastVisitType, .bookmark)
    }

    func testTappingOpenUrlInNewTab_CallsTheDidSelectUrlInNewTapOnBrowserViewController() throws {
        let subject = createSubject()
        subject.browserViewController = browserViewController

        // We show the library with bookmarks tab
        subject.show(homepanelSection: .bookmarks)

        let coordinator = try XCTUnwrap(
            subject.childCoordinators.first { $0 is LibraryCoordinator } as? LibraryCoordinator)
        let url = URL(string: "http://google.com")!
        coordinator.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: true)

        XCTAssertTrue(browserViewController.didRequestToOpenInNewTabCalled)
        XCTAssertEqual(browserViewController.lastOpenedURL, url)
        XCTAssertTrue(browserViewController.isPrivate)
    }

    func testOpenRecentlyClosedSiteInNewTab_addsOneTabToTabManager() {
        let subject = createSubject()

        subject.openRecentlyClosedSiteInNewTab(URL(string: "https://www.google.com")!, isPrivate: false)

        XCTAssertEqual(tabManager.lastSelectedTabs.count, 1)
    }

    func testShowAddressAutofill_addsAddressAutofillCoordinator() {
        // Arrange
        let subject = createSubject()

        // Act
        subject.showAddressAutofill(frame: nil)
        // Assert
        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is AddressAutofillCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is BottomSheetViewController)
    }

    // MARK: - Menu
    func testShowMainMenu_addsMainMenuCoordinator() {
        let subject = createSubject()
        XCTAssertTrue(subject.childCoordinators.isEmpty)

        subject.showMainMenu()

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is MainMenuCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        if !featureFlags.isFeatureEnabled(.menuRefactor, checking: .buildOnly) {
            XCTAssertTrue(mockRouter.presentedViewController is DismissableNavigationViewController)
        }
        XCTAssertTrue(mockRouter.presentedViewController?.children.first is MainMenuViewController)
    }

    func testMainMenuCoordinatorDelegate_didDidDismiss_removesChild() {
        let subject = createSubject()
        subject.browserHasLoaded()

        subject.showMainMenu()
        guard let menuCoordinator = subject.childCoordinators[0] as? MainMenuCoordinator else {
            XCTFail("Main menu coordinator was expected to be resolved")
            return
        }

        menuCoordinator.dismissMenuModal(animated: false)

        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    // MARK: - Search Engine Selection
    func testShowSearchEngineSelection_addsSearchEngineSelectionCoordinator() {
        let subject = createSubject()
        XCTAssertTrue(subject.childCoordinators.isEmpty)

        subject.showSearchEngineSelection(forSourceView: UIView())

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is SearchEngineSelectionCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is DismissableNavigationViewController)
        XCTAssertTrue(mockRouter.presentedViewController?.children.first is SearchEngineSelectionViewController)
    }

    func testSearchEngineSelectionCoordinatorDelegate_navigatesToSettings() {
        let subject = createSubject()
        subject.browserHasLoaded()

        subject.showSearchEngineSelection(forSourceView: UIView())
        guard let searchEngineSelectionCoordinator = subject.childCoordinators[0] as? SearchEngineSelectionCoordinator else {
            XCTFail("Search engine selection coordinator was expected to be resolved")
            return
        }

        searchEngineSelectionCoordinator.navigateToSearchSettings(animated: false)

        XCTAssertTrue(subject.childCoordinators[0] is SettingsCoordinator)
        XCTAssertTrue(mockRouter.presentedViewController?.children.first is AppSettingsTableViewController)
    }

    // MARK: - Microsurvey
    func testShowMicrosurvey_addsMicrosurveyCoordinator() {
        let subject = createSubject()

        subject.showMicrosurvey(model: MicrosurveyMock.model)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is MicrosurveyCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is DismissableNavigationViewController)
        XCTAssertTrue(mockRouter.presentedViewController?.children.first is MicrosurveyViewController)
    }

    // MARK: - Edit Bookmark Controller
    func testShowEditBookmarks_addBookmarksCoordinator() {
        let subject = createSubject()

        let folder = MockFxBookmarkNode(type: .folder,
                                        guid: "0",
                                        position: 0,
                                        isRoot: false,
                                        title: "TestFolder")
        let bookmark = MockFxBookmarkNode(type: .bookmark,
                                          guid: "1",
                                          position: 0,
                                          isRoot: false,
                                          title: "TestBookmark")

        subject.showEditBookmark(parentFolder: folder, bookmark: bookmark)

        XCTAssertEqual(subject.childCoordinators.count, 1)
        XCTAssertTrue(subject.childCoordinators.first is BookmarksCoordinator)
        XCTAssertEqual(mockRouter.presentCalled, 1)
        XCTAssertTrue(mockRouter.presentedViewController is DismissableNavigationViewController)
        XCTAssertTrue(mockRouter.presentedViewController?.children.first is EditBookmarkViewController)
    }

    func testShowEditBookmarks_didDidDismiss_removesChild() {
        let subject = createSubject()

        let folder = MockFxBookmarkNode(type: .folder,
                                        guid: "0",
                                        position: 0,
                                        isRoot: false,
                                        title: "TestFolder")
        let bookmark = MockFxBookmarkNode(type: .bookmark,
                                          guid: "1",
                                          position: 0,
                                          isRoot: false,
                                          title: "TestBookmark")

        subject.showEditBookmark(parentFolder: folder, bookmark: bookmark)
        guard let bookmarksCoordinator = subject.childCoordinators[0] as? BookmarksCoordinator else {
            XCTFail("Bookmarks coordinator was expected to be resolved")
            return
        }

        subject.didFinish(from: bookmarksCoordinator)

        XCTAssertTrue(subject.childCoordinators.isEmpty)
    }

    // MARK: - Helpers
    private func createSubject(file: StaticString = #filePath,
                               line: UInt = #line) -> BrowserCoordinator {
        let subject = BrowserCoordinator(router: mockRouter,
                                         screenshotService: screenshotService,
                                         tabManager: tabManager,
                                         profile: profile,
                                         glean: glean,
                                         applicationHelper: applicationHelper)
        trackForMemoryLeaks(subject, file: file, line: line)
        return subject
    }

    private func testCanHandleAndHandle(_ subject: Coordinator, route: Route) -> Bool {
        let result = subject.canHandle(route: route)
        subject.handle(route: route)
        return result
    }

    private func setIsDeeplinkOptimizationRefactorEnabled(_ enabled: Bool) {
        FxNimbus.shared.features.deeplinkOptimizationRefactorFeature.with { _, _ in
            return DeeplinkOptimizationRefactorFeature(enabled: enabled)
        }
    }

    private func setIsAppleSummarizerEnabled(_ isEnabled: Bool) {
        FxNimbus.shared.features.appleSummarizerFeature.with { _, _ in
            return AppleSummarizerFeature(enabled: isEnabled)
        }
    }

    private func setIsHostedSummarizerEnabled(_ isEnabled: Bool) {
        FxNimbus.shared.features.hostedSummarizerFeature.with { _, _ in
            return HostedSummarizerFeature(enabled: isEnabled)
        }
    }

    private func setupNimbusTabTrayUIExperimentTesting(isEnabled: Bool) {
        FxNimbus.shared.features.tabTrayUiExperiments.with { _, _ in
            return TabTrayUiExperiments(
                enabled: isEnabled
            )
        }
    }

    // MARK: - Mock Server

    func startMockServer() throws -> URL {
        let webServer = GCDWebServer()

        webServer.addHandler(forMethod: "GET",
                             path: "/",
                             request: GCDWebServerRequest.self) { (request) -> GCDWebServerResponse? in
            return GCDWebServerDataResponse()
        }

        if !webServer.start(withPort: 0, bonjourName: nil) {
            XCTFail("Can't start the GCDWebServer")
        }

        return URL(string: "http://localhost:\(webServer.port)")!
    }
}
