// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import Shared
import Storage
import Redux
import PDFKit

import enum MozillaAppServices.VisitType
import struct MozillaAppServices.CreditCard
import ComponentLibrary

class BrowserCoordinator: BaseCoordinator,
                          LaunchCoordinatorDelegate,
                          BrowserDelegate,
                          SettingsCoordinatorDelegate,
                          BrowserNavigationHandler,
                          LibraryCoordinatorDelegate,
                          EnhancedTrackingProtectionCoordinatorDelegate,
                          FakespotCoordinatorDelegate,
                          ParentCoordinatorDelegate,
                          TabManagerDelegate,
                          TabTrayCoordinatorDelegate,
                          PrivateHomepageDelegate,
                          WindowEventCoordinator,
                          MainMenuCoordinatorDelegate,
                          ETPCoordinatorSSLStatusDelegate,
                          SearchEngineSelectionCoordinatorDelegate,
                          BookmarksRefactorFeatureFlagProvider,
                          FeatureFlaggable {
    private struct UX {
        static let searchEnginePopoverSize = CGSize(width: 250, height: 536)
    }

    var browserViewController: BrowserViewController
    var webviewController: WebviewViewController?
    var legacyHomepageViewController: LegacyHomepageViewController?
    var homepageViewController: HomepageViewController?

    private var profile: Profile
    private let tabManager: TabManager
    private let themeManager: ThemeManager
    private let windowManager: WindowManager
    private let screenshotService: ScreenshotService
    private let glean: GleanWrapper
    private let applicationHelper: ApplicationHelper
    private var browserIsReady = false
    private var windowUUID: WindowUUID { return tabManager.windowUUID }
    private var isDeeplinkOptimiziationRefactorEnabled: Bool {
        return featureFlags.isFeatureEnabled(.deeplinkOptimizationRefactor, checking: .buildOnly)
    }

    override var isDismissable: Bool { false }

    init(router: Router,
         screenshotService: ScreenshotService,
         tabManager: TabManager,
         profile: Profile = AppContainer.shared.resolve(),
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         windowManager: WindowManager = AppContainer.shared.resolve(),
         glean: GleanWrapper = DefaultGleanWrapper(),
         applicationHelper: ApplicationHelper = DefaultApplicationHelper()) {
        self.screenshotService = screenshotService
        self.profile = profile
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.windowManager = windowManager
        self.browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        self.applicationHelper = applicationHelper
        self.glean = glean
        super.init(router: router)

        browserViewController.browserDelegate = self
        browserViewController.navigationHandler = self
        tabManager.addDelegate(self)
    }

    func start(with launchType: LaunchType?) {
        router.push(browserViewController, animated: false)

        if let launchType = launchType, launchType.canLaunch(fromType: .BrowserCoordinator) {
            startLaunch(with: launchType)
        }
    }

    // MARK: - Helper methods

    private func startLaunch(with launchType: LaunchType) {
        let launchCoordinator = LaunchCoordinator(router: router, windowUUID: windowUUID)
        launchCoordinator.parentCoordinator = self
        add(child: launchCoordinator)
        launchCoordinator.start(with: launchType)
    }

    // MARK: - LaunchCoordinatorDelegate
    func didFinishTermsOfService(from coordinator: LaunchCoordinator) {
        didFinishLaunch(from: coordinator)
    }

    func didFinishLaunch(from coordinator: LaunchCoordinator) {
        router.dismiss(animated: true, completion: nil)
        remove(child: coordinator)

        // Once launch is done, we check for any saved Route
        if let savedRoute {
            logger.log("Find and handle route called after didFinishLaunch after onboarding",
                       level: .info,
                       category: .coordinator)
            findAndHandle(route: savedRoute)
        }
    }

    // MARK: - BrowserDelegate

    func showLegacyHomepage(
        inline: Bool,
        toastContainer: UIView,
        homepanelDelegate: HomePanelDelegate,
        libraryPanelDelegate: LibraryPanelDelegate,
        statusBarScrollDelegate: StatusBarScrollDelegate,
        overlayManager: OverlayModeManager
    ) {
        let legacyHomepageViewController = getHomepage(
            inline: inline,
            toastContainer: toastContainer,
            homepanelDelegate: homepanelDelegate,
            libraryPanelDelegate: libraryPanelDelegate,
            statusBarScrollDelegate: statusBarScrollDelegate,
            overlayManager: overlayManager
        )

        guard browserViewController.embedContent(legacyHomepageViewController) else { return }
        self.legacyHomepageViewController = legacyHomepageViewController
        legacyHomepageViewController.scrollToTop()
        // We currently don't support full page screenshot of the homepage
        screenshotService.screenshotableView = nil
    }

    func showHomepage(
        overlayManager: OverlayModeManager,
        isZeroSearch: Bool,
        statusBarScrollDelegate: StatusBarScrollDelegate,
        toastContainer: UIView
    ) {
        let homepageController = self.homepageViewController ?? HomepageViewController(
            windowUUID: windowUUID,
            isZeroSearch: isZeroSearch,
            overlayManager: overlayManager,
            statusBarScrollDelegate: statusBarScrollDelegate,
            toastContainer: toastContainer
        )
        guard browserViewController.embedContent(homepageController) else {
            logger.log("Unable to embed new homepage", level: .debug, category: .coordinator)
            return
        }
        self.homepageViewController = homepageController
        homepageController.scrollToTop()
    }

    func showPrivateHomepage(overlayManager: OverlayModeManager) {
        let privateHomepageController = PrivateHomepageViewController(
            windowUUID: windowUUID,
            overlayManager: overlayManager
        )
        privateHomepageController.parentCoordinator = self
        guard browserViewController.embedContent(privateHomepageController) else {
            logger.log("Unable to embed private homepage", level: .debug, category: .coordinator)
            return
        }
    }

    func navigateFromHomePanel(to url: URL, visitType: VisitType, isGoogleTopSite: Bool) {
        browserViewController.homePanel(didSelectURL: url, visitType: visitType, isGoogleTopSite: isGoogleTopSite)
    }

    func showContextMenu(for configuration: ContextMenuConfiguration) {
        let coordinator = ContextMenuCoordinator(
            configuration: configuration,
            router: router,
            windowUUID: windowUUID,
            bookmarksHandlerDelegate: browserViewController
        )
        coordinator.parentCoordinator = self
        add(child: coordinator)
        coordinator.start()
    }

    func showEditBookmark(parentFolder: FxBookmarkNode, bookmark: FxBookmarkNode) {
        let navigationController = DismissableNavigationViewController()
        let router = DefaultRouter(navigationController: navigationController)
        let bookmarksCoordinator = BookmarksCoordinator(
            router: router,
            profile: profile,
            windowUUID: windowUUID,
            libraryCoordinator: self,
            libraryNavigationHandler: nil,
            isBookmarkRefactorEnabled: isBookmarkRefactorEnabled
        )
        add(child: bookmarksCoordinator)
        bookmarksCoordinator.start(parentFolder: parentFolder, bookmark: bookmark)
        navigationController.onViewDismissed = { [weak self] in
            // Remove coordinator when user drags down to dismiss modal
            self?.didFinish(from: bookmarksCoordinator)
        }
        present(navigationController)
    }

    // MARK: - PrivateHomepageDelegate
    func homePanelDidRequestToOpenInNewTab(with url: URL, isPrivate: Bool, selectNewTab: Bool) {
        openInNewTab(url: url, isPrivate: isPrivate, selectNewTab: selectNewTab)
    }

    func switchMode() {
        browserViewController.tabManager.switchPrivacyMode()
    }

    func show(webView: WKWebView) {
        // Keep the webviewController in memory, update to newest webview when needed
        if let webviewController = webviewController {
            webviewController.update(webView: webView)
            browserViewController.frontEmbeddedContent(webviewController)
            logger.log("Webview content was updated", level: .info, category: .coordinator)
        } else {
            let webviewViewController = WebviewViewController(webView: webView)
            webviewController = webviewViewController
            browserViewController.fullscreenDelegate = webviewViewController
            let isEmbedded = browserViewController.embedContent(webviewViewController)
            logger.log("Webview controller was created and embedded \(isEmbedded)", level: .info, category: .coordinator)
        }

        screenshotService.screenshotableView = webviewController
    }

    func browserHasLoaded() {
        if !isDeeplinkOptimiziationRefactorEnabled {
            browserIsReady = true
            logger.log("Browser has loaded", level: .info, category: .coordinator)

            if let savedRoute {
                logger.log("Find and handle route called after browserHasLoaded",
                           level: .info,
                           category: .coordinator)
                findAndHandle(route: savedRoute)
            }
        }
    }

    private func getHomepage(inline: Bool,
                             toastContainer: UIView,
                             homepanelDelegate: HomePanelDelegate,
                             libraryPanelDelegate: LibraryPanelDelegate,
                             statusBarScrollDelegate: StatusBarScrollDelegate,
                             overlayManager: OverlayModeManager) -> LegacyHomepageViewController {
        if let legacyHomepageViewController = legacyHomepageViewController {
            legacyHomepageViewController.configure(isZeroSearch: inline)
            return legacyHomepageViewController
        } else {
            let legacyHomepageViewController = LegacyHomepageViewController(
                profile: profile,
                isZeroSearch: inline,
                toastContainer: toastContainer,
                tabManager: tabManager,
                overlayManager: overlayManager)
            legacyHomepageViewController.homePanelDelegate = homepanelDelegate
            legacyHomepageViewController.libraryPanelDelegate = libraryPanelDelegate
            legacyHomepageViewController.statusBarScrollDelegate = statusBarScrollDelegate
            legacyHomepageViewController.browserNavigationHandler = self

            return legacyHomepageViewController
        }
    }

    // MARK: - ETPCoordinatorSSLStatusDelegate

    var showHasOnlySecureContentInTrackingPanel: Bool {
        if browserViewController.isToolbarRefactorEnabled {
            return browserViewController.tabManager.selectedTab?.currentWebView()?.hasOnlySecureContent ?? false
        }

        guard let bar = browserViewController.legacyUrlBar else { return false }
        return bar.locationView.hasSecureContent
    }

    // MARK: - Route handling

    override func canHandle(route: Route) -> Bool {
        if !isDeeplinkOptimiziationRefactorEnabled {
            guard browserIsReady, !tabManager.isRestoringTabs else {
                let readyMessage = "browser is ready? \(browserIsReady)"
                let restoringMessage = "is restoring tabs? \(tabManager.isRestoringTabs)"
                logger.log("Could not handle route, \(readyMessage), \(restoringMessage)",
                           level: .info,
                           category: .coordinator)
                return false
            }
        }

        switch route {
        case .searchQuery, .search, .searchURL, .glean, .homepanel, .action, .fxaSignIn, .defaultBrowser, .sharesheet:
            return true
        case let .settings(section):
            return canHandleSettings(with: section)
        }
    }

    override func handle(route: Route) {
        if !isDeeplinkOptimiziationRefactorEnabled {
            guard browserIsReady, !tabManager.isRestoringTabs else {
                logger.log("Not handling route. Ready? \(browserIsReady), restoring? \(tabManager.isRestoringTabs)",
                           level: .info,
                           category: .coordinator)
                return
            }
        }

        logger.log("Handling a route", level: .info, category: .coordinator)
        switch route {
        case let .searchQuery(query, isPrivate):
            handle(query: query, isPrivate: isPrivate)

        case let .search(url, isPrivate, options):
            handle(url: url, isPrivate: isPrivate, options: options)

        case let .searchURL(url, tabId):
            handle(searchURL: url, tabId: tabId)

        case let .sharesheet(shareType, shareMessage):
            handleShareRoute(shareType: shareType, shareMessage: shareMessage)

        case let .glean(url):
            glean.handleDeeplinkUrl(url: url)

        case let .homepanel(section):
            handle(homepanelSection: section)

        case let .settings(section):
            handleSettings(with: section)

        case let .action(routeAction):
            switch routeAction {
            case .closePrivateTabs:
                handleClosePrivateTabsWidgetAction()
            case .showQRCode:
                handleQRCode()
            case .showIntroOnboarding:
                showIntroOnboarding()
            }

        case let .fxaSignIn(params):
            handle(fxaParams: params)

        case let .defaultBrowser(section):
            switch section {
            case .systemSettings:
                applicationHelper.openSettings()
            case .tutorial:
                startLaunch(with: .defaultBrowser)
            }
        }
    }

    private func showIntroOnboarding() {
        let introManager = IntroScreenManager(prefs: profile.prefs)
        let launchType = LaunchType.intro(manager: introManager)
        startLaunch(with: launchType)
    }

    private func handleQRCode() {
        browserViewController.handleQRCode()
    }

    private func handleClosePrivateTabsWidgetAction() {
        // Our widget actions will arrive as a URL passed into the client iOS app.
        // If multiple iPad windows are open the resulting action + route will be
        // sent to one particular window, but for this action we want to close tabs
        // for all open windows, so we route this message to the WindowManager.
        windowManager.performMultiWindowAction(.closeAllPrivateTabs)
    }

    private func handle(homepanelSection section: Route.HomepanelSection) {
        switch section {
        case .bookmarks:
            browserViewController.showLibrary(panel: .bookmarks)
        case .history:
            browserViewController.showLibrary(panel: .history)
        case .readingList:
            browserViewController.showLibrary(panel: .readingList)
        case .downloads:
            browserViewController.showLibrary(panel: .downloads)
        case .topSites:
            browserViewController.openURLInNewTab(HomePanelType.topSites.internalUrl)
        case .newPrivateTab:
            browserViewController.openBlankNewTab(focusLocationField: true, isPrivate: true)
        case .newTab:
            browserViewController.openBlankNewTab(focusLocationField: true)
        }
    }

    // MARK: - Handle Deeplink Open URL / text

    private func handle(query: String, isPrivate: Bool) {
        browserViewController.handle(query: query, isPrivate: isPrivate)
    }

    private func handle(url: URL?, isPrivate: Bool, options: Set<Route.SearchOptions>? = nil) {
        browserViewController.handle(url: url, isPrivate: isPrivate, options: options)
    }

    private func handle(searchURL: URL?, tabId: String) {
        browserViewController.handle(url: searchURL, tabId: tabId)
    }

    private func handle(fxaParams: FxALaunchParams) {
        browserViewController.presentSignInViewController(fxaParams)
    }

    /// Starts the share sheet coordinator for the deep link `.sharesheet` route (share content via Nimbus Messaging).
    /// - Parameters:
    ///   - shareType: The content to share.
    ///   - shareMessage: An optional textual message to accompany the shared content. May contain a Mail subject line.
    private func handleShareRoute(shareType: ShareType, shareMessage: ShareMessage?) {
        // FIXME: FXIOS-10829 Deep link shares should set a reasonable sourceView for iPad... or sourceView could be optional
        startShareSheetCoordinator(
            shareType: shareType,
            shareMessage: shareMessage,
            sourceView: browserViewController.addressToolbarContainer,
            sourceRect: nil,
            toastContainer: browserViewController.contentContainer,
            popoverArrowDirection: .any
        )
    }

    private func canHandleSettings(with section: Route.SettingsSection) -> Bool {
        guard !childCoordinators.contains(where: { $0 is SettingsCoordinator }) else {
            return false // route is handled with existing child coordinator
        }
        return true
    }

    private func handleSettings(with section: Route.SettingsSection, onDismiss: (() -> Void)? = nil) {
        guard !childCoordinators.contains(where: { $0 is SettingsCoordinator }) else {
            return // route is handled with existing child coordinator
        }
        windowManager.postWindowEvent(event: .settingsOpened, windowUUID: windowUUID)
        let navigationController = ThemedNavigationController(windowUUID: windowUUID)
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let modalPresentationStyle: UIModalPresentationStyle = isPad ? .fullScreen: .formSheet
        navigationController.modalPresentationStyle = modalPresentationStyle
        let settingsRouter = DefaultRouter(navigationController: navigationController)

        let settingsCoordinator = SettingsCoordinator(
            router: settingsRouter,
            tabManager: tabManager
        )
        settingsCoordinator.parentCoordinator = self
        add(child: settingsCoordinator)
        settingsCoordinator.start(with: section)

        navigationController.onViewDismissed = { [weak self] in
            self?.didFinishSettings(from: settingsCoordinator)
            onDismiss?()
        }
        present(navigationController)
    }

    private func showLibrary(with homepanelSection: Route.HomepanelSection) {
        windowManager.postWindowEvent(event: .libraryOpened, windowUUID: windowUUID)
        if let libraryCoordinator = childCoordinators[LibraryCoordinator.self] {
            libraryCoordinator.start(with: homepanelSection)
            (libraryCoordinator.router.navigationController as? UINavigationController).map { router.present($0) }
        } else {
            let navigationController = DismissableNavigationViewController()
            navigationController.modalPresentationStyle = .formSheet

            let libraryCoordinator = LibraryCoordinator(
                router: DefaultRouter(navigationController: navigationController),
                tabManager: tabManager
            )
            libraryCoordinator.parentCoordinator = self
            add(child: libraryCoordinator)
            libraryCoordinator.start(with: homepanelSection)

            present(navigationController)
        }
    }

    private func showETPMenu(sourceView: UIView) {
        let enhancedTrackingProtectionCoordinator = EnhancedTrackingProtectionCoordinator(router: router,
                                                                                          tabManager: tabManager,
                                                                                          secureConnectionDelegate: self)
        enhancedTrackingProtectionCoordinator.parentCoordinator = self
        add(child: enhancedTrackingProtectionCoordinator)
        enhancedTrackingProtectionCoordinator.start(sourceView: sourceView)
    }

    // MARK: - SettingsCoordinatorDelegate

    func openURLinNewTab(_ url: URL) {
        browserViewController.openURLInNewTab(url)
    }

    func didFinishSettings(from coordinator: SettingsCoordinator) {
        router.dismiss(animated: true, completion: nil)
        remove(child: coordinator)
    }

    func openDebugTestTabs(count: Int) {
        guard let url = URL(string: "https://www.mozilla.org") else { return }
        browserViewController.debugOpen(numberOfNewTabs: count, at: url)
    }

    // MARK: - LibraryCoordinatorDelegate

    func openRecentlyClosedSiteInNewTab(_ url: URL, isPrivate: Bool) {
        browserViewController.openRecentlyClosedSiteInNewTab(url, isPrivate: isPrivate)
    }

    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        browserViewController.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate)
        router.dismiss()
    }

    func libraryPanel(didSelectURL url: URL, visitType: VisitType) {
        browserViewController.libraryPanel(didSelectURL: url, visitType: visitType)
        router.dismiss()
    }

    var libraryPanelWindowUUID: WindowUUID {
        return windowUUID
    }

    func didFinishLibrary(from coordinator: Coordinator) {
        router.dismiss(animated: true, completion: nil)
        remove(child: coordinator)
    }

    // MARK: - EnhancedTrackingProtectionCoordinatorDelegate

    func didFinishEnhancedTrackingProtection(from coordinator: EnhancedTrackingProtectionCoordinator) {
        router.dismiss(animated: true, completion: nil)
        remove(child: coordinator)
    }

    func settingsOpenPage(settings: Route.SettingsSection) {
        handleSettings(with: settings)
    }

    // MARK: - MainMenuCoordinatorDelegate

    func showMainMenu() {
        guard let menuNavViewController = makeMenuNavViewController() else { return }
        present(menuNavViewController)
    }

    func openURLInNewTab(_ url: URL?) {
        if let url {
            browserViewController.openURLInNewTab(url, isPrivate: self.tabManager.selectedTab?.isPrivate ?? false)
        }
    }

    func openNewTab(inPrivateMode isPrivate: Bool) {
        browserViewController.openNewTabFromMenu(
            focusLocationField: true,
            isPrivate: isPrivate
        )
    }

    func showLibraryPanel(_ panel: Route.HomepanelSection) {
        showLibrary(with: panel)
    }

    func showSettings(at destination: Route.SettingsSection) {
        presentWithModalDismissIfNeeded {
            self.handleSettings(with: destination, onDismiss: nil)
        }
    }

    func editBookmarkForCurrentTab() {
        guard let urlString = tabManager.selectedTab?.url?.absoluteString else { return }
        browserViewController.openBookmarkEditPanel(urlString: urlString)
    }

    func showFindInPage() {
        browserViewController.showFindInPage()
    }

    func updateZoomPageBarVisibility() {
        browserViewController.updateZoomPageBarVisibility(visible: true)
    }

    /// Share the currently selected tab using the share sheet.
    ///
    /// Part of the MainMenuCoordinatorDelegate implementation, called from the New Menu > Tools > Share.
    func showShareSheetForCurrentlySelectedTab() {
        // We share the tab's displayURL to make sure we don't share reader mode localhost URLs
        guard let selectedTab = tabManager.selectedTab,
              let url = selectedTab.canonicalURL?.displayURL else {
            return
        }

        startShareSheetCoordinator(
            shareType: .tab(url: url, tab: selectedTab),
            shareMessage: nil,
            sourceView: self.browserViewController.addressToolbarContainer,
            sourceRect: nil,
            toastContainer: self.browserViewController.contentContainer,
            popoverArrowDirection: .any
        )
    }

    func presentSavePDFController() {
        guard let selectedTab = browserViewController.tabManager.selectedTab else { return }
        if selectedTab.mimeType == MIMEType.PDF {
            showShareSheetForCurrentlySelectedTab()
        } else {
            selectedTab.webView?.createPDF { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let data):
                    guard let pdf = PDFDocument(data: data),
                          let outputURL = pdf.createOutputURL(withFileName: selectedTab.webView?.title ?? "") else {
                        return
                    }
                    startShareSheetCoordinator(
                        shareType: .file(url: outputURL),
                        shareMessage: nil,
                        sourceView: self.browserViewController.addressToolbarContainer,
                        sourceRect: nil,
                        toastContainer: self.browserViewController.contentContainer,
                        popoverArrowDirection: .any
                    )
                case .failure(let error):
                    // TODO: FXIOS-11542 [iOS Menu Redesign] - Handle saveAsPDF Menu option, error case
                    self.logger.log("Failed to get a valid data URL result, with error: \(error.localizedDescription)",
                                    level: .debug,
                                    category: .webview)
                }
            }
        }
    }

    func showPrintSheet() {
        if let webView = browserViewController.tabManager.selectedTab?.webView {
            let printController = UIPrintInteractionController.shared
            printController.printFormatter = webView.viewPrintFormatter()
            printController.present(animated: true, completionHandler: nil)
        }
    }

    private func makeMenuNavViewController() -> DismissableNavigationViewController? {
        if let mainMenuCoordinator = childCoordinators.first(where: { $0 is MainMenuCoordinator }) as? MainMenuCoordinator {
            mainMenuCoordinator.dismissMenuModal(animated: false)
        }

        let navigationController = DismissableNavigationViewController()
        navigationController.modalPresentationStyle = .formSheet
        if !navigationController.shouldUseiPadSetup() {
            navigationController.modalPresentationStyle = .formSheet
            navigationController.sheetPresentationController?.detents = [.medium(), .large()]
            navigationController.sheetPresentationController?.prefersGrabberVisible = true
        }

        let coordinator = MainMenuCoordinator(
            router: DefaultRouter(navigationController: navigationController),
            windowUUID: tabManager.windowUUID,
            profile: profile
        )
        coordinator.parentCoordinator = self
        coordinator.navigationHandler = self
        add(child: coordinator)
        coordinator.start()

        return navigationController
    }

    func showSignInView(fxaParameters: FxASignInViewParameters?) {
        guard let fxaParameters else { return }
        browserViewController.presentSignInViewController(fxaParameters.launchParameters,
                                                          flowType: fxaParameters.flowType,
                                                          referringPage: fxaParameters.referringPage)
    }

    // MARK: - SearchEngineSelectionCoordinatorDelegate

    func showSearchEngineSelection(forSourceView sourceView: UIView) {
        guard !childCoordinators.contains(where: { $0 is SearchEngineSelectionCoordinator }) else { return }
        let isEditing = store.state.screenState(ToolbarState.self,
                                                for: .toolbar,
                                                window: windowUUID)?.addressToolbar.isEditing == true

        let navigationController = DismissableNavigationViewController()
        if navigationController.shouldUseiPadSetup() {
            navigationController.modalPresentationStyle = .popover
            navigationController.preferredContentSize = UX.searchEnginePopoverSize
            navigationController.popoverPresentationController?.sourceView = sourceView
            navigationController.popoverPresentationController?.canOverlapSourceViewRect = false
        } else {
            navigationController.modalPresentationStyle = .pageSheet
            navigationController.sheetPresentationController?.detents = [.medium(), .large()]
            navigationController.sheetPresentationController?.prefersGrabberVisible = true
            if isEditing {
                store.dispatch(ToolbarAction(windowUUID: windowUUID, actionType: ToolbarActionType.hideKeyboard))
            }
        }

        let coordinator = DefaultSearchEngineSelectionCoordinator(
            router: DefaultRouter(navigationController: navigationController),
            windowUUID: tabManager.windowUUID
        )

        coordinator.parentCoordinator = self
        coordinator.navigationHandler = self
        add(child: coordinator)
        coordinator.start()

        present(navigationController)
    }

    // MARK: - BrowserNavigationHandler
    func openInNewTab(url: URL, isPrivate: Bool, selectNewTab: Bool) {
        browserViewController.homePanelDidRequestToOpenInNewTab(
            url,
            isPrivate: isPrivate,
            selectNewTab: selectNewTab
        )
    }
    func showShareSheet(
        shareType: ShareType,
        shareMessage: ShareMessage?,
        sourceView: UIView,
        sourceRect: CGRect?,
        toastContainer: UIView,
        popoverArrowDirection: UIPopoverArrowDirection
    ) {
        startShareSheetCoordinator(
            shareType: shareType,
            shareMessage: shareMessage,
            sourceView: sourceView,
            sourceRect: sourceRect,
            toastContainer: toastContainer,
            popoverArrowDirection: popoverArrowDirection
        )
    }

    func show(settings: Route.SettingsSection, onDismiss: (() -> Void)? = nil) {
        presentWithModalDismissIfNeeded {
            self.handleSettings(with: settings, onDismiss: onDismiss)
        }
    }

    /// Not all flows are handled by coordinators at the moment so we can't call router.dismiss for all
    /// This bridges to use the presentWithModalDismissIfNeeded method we have in older flows
    private func presentWithModalDismissIfNeeded(completion: @escaping () -> Void) {
        if let presentedViewController = router.navigationController.presentedViewController {
            presentedViewController.dismiss(animated: false, completion: {
                completion()
            })
        } else {
            completion()
        }
    }

    func show(homepanelSection: Route.HomepanelSection) {
        showLibrary(with: homepanelSection)
    }

    func showEnhancedTrackingProtection(sourceView: UIView) {
        showETPMenu(sourceView: sourceView)
    }

    func showFakespotFlowAsModal(productURL: URL) {
        guard let coordinator = makeFakespotCoordinator() else { return }
        coordinator.startModal(productURL: productURL)
    }

    func showFakespotFlowAsSidebar(productURL: URL,
                                   sidebarContainer: SidebarEnabledViewProtocol,
                                   parentViewController: UIViewController) {
        guard let coordinator = makeFakespotCoordinator() else { return }
        coordinator.startSidebar(productURL: productURL,
                                 sidebarContainer: sidebarContainer,
                                 parentViewController: parentViewController)
    }

    func dismissFakespotModal(animated: Bool = true) {
        guard let fakespotCoordinator = childCoordinators.first(where: {
            $0 is FakespotCoordinator
        }) as? FakespotCoordinator else {
            return // there is no modal to close
        }
        fakespotCoordinator.dismissModal(animated: animated)
    }

    func dismissFakespotSidebar(sidebarContainer: SidebarEnabledViewProtocol, parentViewController: UIViewController) {
        guard let fakespotCoordinator = childCoordinators.first(where: {
            $0 is FakespotCoordinator
        }) as? FakespotCoordinator else {
            return // there is no sidebar to close
        }
        fakespotCoordinator.closeSidebar(sidebarContainer: sidebarContainer,
                                         parentViewController: parentViewController)
    }

    func updateFakespotSidebar(productURL: URL,
                               sidebarContainer: SidebarEnabledViewProtocol,
                               parentViewController: UIViewController) {
        guard let fakespotCoordinator = childCoordinators.first(where: {
            $0 is FakespotCoordinator
        }) as? FakespotCoordinator else {
            return // there is no sidebar
        }
        fakespotCoordinator.updateSidebar(productURL: productURL,
                                          sidebarContainer: sidebarContainer,
                                          parentViewController: parentViewController)
    }

    private func makeFakespotCoordinator() -> FakespotCoordinator? {
        guard !childCoordinators.contains(where: { $0 is FakespotCoordinator }) else {
            return nil // flow is already handled
        }

        let coordinator = FakespotCoordinator(router: router, tabManager: tabManager)
        coordinator.parentCoordinator = self
        add(child: coordinator)
        return coordinator
    }

    /// Starts the ShareSheetCoordinator, which initiates opening the iOS share sheet using an `UIActivityViewController`.
    ///
    /// For shared tabs where the user is currently on a non-HTML page (e.g. viewing a PDF), this method will initiate a
    /// file download, and then share the file instead. This currently blocks without any UI indication, which is less
    /// than ideal but has been the existing behaviour for a long time (task to address this: FXIOS-10823).
    ///
    /// - Parameters:
    ///   - shareType: The type of content to share.
    ///   - shareMessage: An optional accompanying message to share (with optional email subject line).
    ///   - sourceView: The view tapped to initiate share. iPad share sheet popovers will point to this element.
    ///   - sourceRect: The source rect for the view tapped to initiate share. iPad share sheet popovers will point to this
    ///                 element.
    ///   - toastContainer: The container for displaying toast information.
    ///   - popoverArrowDirection: The arrow direction for iPad share sheet popovers.
    ///
    /// There are many ways to share many types of content from various areas of the app. Code paths that go through this
    /// method include:
    /// * Sharing content from a long press on Home screen tiles (e.g. long press Jump Back In context menu)
    /// * From the old Menu > Share and the new Menu > Tools > Share
    /// * From the new toolbar share button beside the address bar
    /// * From long pressing a link in the WKWebView and sharing from the context menu (via ActionProviderBuilder > addShare)
    /// * Via the sharesheet deeplink path in `RouteBuilder` (e.g. tapping home cards that initiate sharing content)
    ///     * Currently this is the only path that is using the ShareMessage param (Info Card Referral experiment FXE-1090)
    func startShareSheetCoordinator(
        shareType: ShareType,
        shareMessage: ShareMessage?,
        sourceView: UIView,
        sourceRect: CGRect?,
        toastContainer: UIView,
        popoverArrowDirection: UIPopoverArrowDirection
    ) {
        if let coordinator = childCoordinators.first(where: { $0 is ShareSheetCoordinator }) as? ShareSheetCoordinator {
            // The share sheet extension coordinator wasn't correctly removed in the last share session. Attempt to recover.
            logger.log(
                "ShareSheetCoordinator already exists when it shouldn't. Removing and recreating it to access share sheet",
                level: .info,
                category: .shareSheet,
                extra: ["existing ShareSheetCoordinator UUID": "\(coordinator.windowUUID)",
                        "BrowserCoordinator windowUUID": "\(windowUUID)"]
            )

            coordinator.dismiss()
        }

        Task {
            // FXIOS-10824 It's strange if the user has to wait a long time to download files that are literally already
            // being shown in the webview.
            var overrideShareType = shareType
            if case ShareType.tab = shareType {
                overrideShareType = await tryDownloadingTabFileToShare(shareType: shareType)
            }

            await MainActor.run { [weak self, overrideShareType] in
                guard let self else { return }

                let shareSheetCoordinator = ShareSheetCoordinator(
                    alertContainer: toastContainer,
                    router: router,
                    profile: profile,
                    parentCoordinator: self,
                    tabManager: tabManager
                )
                add(child: shareSheetCoordinator)
                shareSheetCoordinator.start(
                    shareType: overrideShareType,
                    shareMessage: shareMessage,
                    sourceView: sourceView,
                    sourceRect: sourceRect,
                    popoverArrowDirection: popoverArrowDirection
                )
            }
        }
    }

    func showCreditCardAutofill(creditCard: CreditCard?,
                                decryptedCard: UnencryptedCreditCardFields?,
                                viewType state: CreditCardBottomSheetState,
                                frame: WKFrameInfo?,
                                alertContainer: UIView) {
        let bottomSheetCoordinator = makeCredentialAutofillCoordinator()
        bottomSheetCoordinator.showCreditCardAutofill(
            creditCard: creditCard,
            decryptedCard: decryptedCard,
            viewType: state,
            frame: frame,
            alertContainer: alertContainer
        )
    }

    @MainActor
    @preconcurrency
    func showSavedLoginAutofill(tabURL: URL, currentRequestId: String, field: FocusFieldType) {
        let bottomSheetCoordinator = makeCredentialAutofillCoordinator()
        bottomSheetCoordinator.showSavedLoginAutofill(tabURL: tabURL, currentRequestId: currentRequestId, field: field)
    }

    func showAddressAutofill(frame: WKFrameInfo?) {
        let bottomSheetCoordinator = makeAddressAutofillCoordinator()
        bottomSheetCoordinator.showAddressAutofill(frame: frame)
    }

    func showRequiredPassCode() {
        let bottomSheetCoordinator = makeCredentialAutofillCoordinator()
        bottomSheetCoordinator.showPassCodeController()
    }

    private func makeAddressAutofillCoordinator() -> AddressAutofillCoordinator {
        if let bottomSheetCoordinator = childCoordinators.first(where: {
            $0 is AddressAutofillCoordinator
        }) as? AddressAutofillCoordinator {
            return bottomSheetCoordinator
        }
        let bottomSheetCoordinator = AddressAutofillCoordinator(
            profile: profile,
            router: router,
            parentCoordinator: self,
            tabManager: tabManager
        )
        add(child: bottomSheetCoordinator)
        return bottomSheetCoordinator
    }

    private func makeCredentialAutofillCoordinator() -> CredentialAutofillCoordinator {
        if let bottomSheetCoordinator = childCoordinators.first(where: {
            $0 is CredentialAutofillCoordinator
        }) as? CredentialAutofillCoordinator {
            return bottomSheetCoordinator
        }
        let bottomSheetCoordinator = CredentialAutofillCoordinator(
            profile: profile,
            router: router,
            parentCoordinator: self,
            tabManager: tabManager
        )
        add(child: bottomSheetCoordinator)
        return bottomSheetCoordinator
    }

    func showQRCode(delegate: QRCodeViewControllerDelegate, rootNavigationController: UINavigationController?) {
        windowManager.postWindowEvent(event: .qrScannerOpened, windowUUID: windowUUID)
        var coordinator: QRCodeCoordinator
        if let qrCodeCoordinator = childCoordinators.first(where: { $0 is QRCodeCoordinator }) as? QRCodeCoordinator {
            coordinator = qrCodeCoordinator
        } else {
            if rootNavigationController != nil {
                coordinator = QRCodeCoordinator(
                    parentCoordinator: self,
                    router: DefaultRouter(navigationController: rootNavigationController!)
                )
            } else {
                coordinator = QRCodeCoordinator(
                    parentCoordinator: self,
                    router: router
                )
            }

            add(child: coordinator)
        }
        coordinator.showQRCode(delegate: delegate)
    }

    func showTabTray(selectedPanel: TabTrayPanelType) {
        guard !childCoordinators.contains(where: { $0 is TabTrayCoordinator }) else {
            return // flow is already handled
        }
        let navigationController = DismissableNavigationViewController()
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let modalPresentationStyle: UIModalPresentationStyle
        if featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly) {
            modalPresentationStyle = .fullScreen
        } else {
            modalPresentationStyle = isPad ? .fullScreen: .formSheet
        }
        navigationController.modalPresentationStyle = modalPresentationStyle

        let tabTrayCoordinator = TabTrayCoordinator(
            router: DefaultRouter(navigationController: navigationController),
            tabTraySection: selectedPanel,
            profile: profile,
            tabManager: tabManager
        )
        tabTrayCoordinator.parentCoordinator = self
        add(child: tabTrayCoordinator)
        tabTrayCoordinator.start(with: selectedPanel)

        navigationController.onViewDismissed = { [weak self] in
            guard let self else { return }
            self.didDismissTabTray(from: tabTrayCoordinator)
            store.dispatch(
                TabTrayAction(
                    windowUUID: self.windowUUID,
                    actionType: TabTrayActionType.modalSwipedToClose
                )
            )
        }

        if featureFlags.isFeatureEnabled(.tabTrayUIExperiments, checking: .buildOnly) &&
            featureFlags.isFeatureEnabled(.tabAnimation, checking: .buildOnly) {
            guard let tabTrayVC = tabTrayCoordinator.tabTrayViewController else { return }
            present(navigationController, customTransition: tabTrayVC, style: modalPresentationStyle)
        } else {
            present(navigationController)
        }
    }

    // This implementation of present is specifically for the animation on .tabTrayUIExperiments
    private func present(_ viewController: UIViewController,
                         customTransition: UIViewControllerTransitioningDelegate,
                         style: UIModalPresentationStyle) {
        browserViewController.willNavigateAway(from: tabManager.selectedTab)
        if !UIAccessibility.isReduceMotionEnabled {
            router.present(viewController, animated: true, customTransition: customTransition, presentationStyle: style)
        } else {
            router.present(viewController)
        }
    }

    private func present(_ viewController: UIViewController) {
        browserViewController.willNavigateAway(from: tabManager.selectedTab)
        router.present(viewController)
    }

    func showBackForwardList() {
        guard let backForwardList = tabManager.selectedTab?.webView?.backForwardList else { return }
        let backForwardListVC = BackForwardListViewController(profile: profile,
                                                              windowUUID: windowUUID,
                                                              backForwardList: backForwardList)
        backForwardListVC.backForwardTransitionDelegate = BackForwardListAnimator()
        backForwardListVC.browserFrameInfoProvider = browserViewController
        backForwardListVC.tabManager = tabManager
        backForwardListVC.modalPresentationStyle = .overCurrentContext
        present(backForwardListVC)
    }

    func showDocumentLoading() {
        browserViewController.showDocumentLoadingView()
    }

    func removeDocumentLoading(completion: (() -> Void)? = nil) {
        browserViewController.removeDocumentLoadingView(completion: completion)
    }

    // MARK: Microsurvey

    func showMicrosurvey(model: MicrosurveyModel) {
        guard !childCoordinators.contains(where: { $0 is MicrosurveyCoordinator }) else {
            return
        }

        let navigationController = DismissableNavigationViewController()
        navigationController.sheetPresentationController?.detents = [.medium(), .large()]
        setiPadLayoutDetents(for: navigationController)
        navigationController.sheetPresentationController?.prefersGrabberVisible = true
        let coordinator = MicrosurveyCoordinator(
            model: model,
            router: DefaultRouter(navigationController: navigationController),
            tabManager: tabManager
        )
        coordinator.parentCoordinator = self
        add(child: coordinator)
        coordinator.start()

        navigationController.onViewDismissed = { [weak self] in
            // Remove coordinator when user drags down to dismiss modal
            self?.didFinish(from: coordinator)
        }

        present(navigationController)
    }

    func showNativeErrorPage(overlayManager: OverlayModeManager) {
        let errorPageController = NativeErrorPageViewController(
            windowUUID: windowUUID,
            overlayManager: overlayManager
        )

        guard browserViewController.embedContent(errorPageController) else {
            logger.log("Unable to embed error page", level: .debug, category: .coordinator)
            return
        }
    }

    private func setiPadLayoutDetents(for controller: UIViewController) {
        guard controller.shouldUseiPadSetup() else { return }
        controller.sheetPresentationController?.selectedDetentIdentifier = .large
    }

    // MARK: - Password Generator
    func showPasswordGenerator(tab: Tab, frame: WKFrameInfo) {
        let passwordGenVC = PasswordGeneratorViewController(windowUUID: windowUUID, currentTab: tab, currentFrame: frame)

        let action = PasswordGeneratorAction(
            windowUUID: windowUUID,
            actionType: PasswordGeneratorActionType.showPasswordGenerator,
            currentFrame: frame
        )
        store.dispatch(action)

        let bottomSheetVM = BottomSheetViewModel(
            shouldDismissForTapOutside: true,
            closeButtonA11yLabel: .PasswordGenerator.CloseButtonA11yLabel,
            closeButtonA11yIdentifier: AccessibilityIdentifiers.PasswordGenerator.closeButton
        )

        let bottomSheetVC = BottomSheetViewController(
            viewModel: bottomSheetVM,
            childViewController: passwordGenVC,
            usingDimmedBackground: true,
            windowUUID: windowUUID
        )
        present(bottomSheetVC)
    }

    // MARK: - ParentCoordinatorDelegate

    func didFinish(from childCoordinator: Coordinator) {
        remove(child: childCoordinator)
    }

    // MARK: - TabManagerDelegate

    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        // Once tab restore is made, if there's any saved route we make sure to call it
        if let savedRoute {
            logger.log("Find and handle route called after tabManagerDidRestoreTabs",
                       level: .info,
                       category: .coordinator)
            findAndHandle(route: savedRoute)
        }
    }

    // MARK: - TabTrayCoordinatorDelegate

    func didDismissTabTray(from coordinator: TabTrayCoordinator) {
        router.dismiss(animated: true, completion: nil)
        // [FXIOS-10482] Initial bandaid for memory leaking during tab tray open/close. Needs further investigation.
        coordinator.dismissChildTabTrayPanels()
        remove(child: coordinator)
    }

    // MARK: - WindowEventCoordinator

    func coordinatorHandleWindowEvent(event: WindowEvent, uuid: WindowUUID) {
        switch event {
        case .windowWillClose:
            guard uuid == windowUUID else { return }
            // Additional cleanup performed when the current iPad window is closed.
            // This is necessary in order to ensure the BVC and other memory is freed correctly.

            // Notify theme manager
            themeManager.windowDidClose(uuid: uuid)

            // Clean up views and ensure BVC for the window is freed
            browserViewController.view.endEditing(true)
            browserViewController.dismissUrlBar()
            legacyHomepageViewController?.view.removeFromSuperview()
            legacyHomepageViewController?.removeFromParent()
            legacyHomepageViewController = nil
            browserViewController.contentContainer.subviews.forEach { $0.removeFromSuperview() }
            browserViewController.removeFromParent()
        case .libraryOpened:
            // Auto-close library panel if it was opened in another iPad window. [FXIOS-8095]
            guard uuid != windowUUID else { return }
            performIfCoordinatorRootVCIsPresented(LibraryCoordinator.self) { _ in
                router.dismiss(animated: true, completion: nil)
            }
        case .settingsOpened:
            // Auto-close settings panel if it was opened in another iPad window. [FXIOS-8095]
            guard uuid != windowUUID else { return }
            performIfCoordinatorRootVCIsPresented(SettingsCoordinator.self) {
                didFinishSettings(from: $0)
            }
        case .syncMenuOpened:
            guard uuid != windowUUID else { return }
            let browserPresentedVC = router.navigationController.presentedViewController
            if let navVCs = (browserPresentedVC as? UINavigationController)?.viewControllers,
               navVCs.contains(where: {
                   $0 is FirefoxAccountSignInViewController || $0 is SyncContentSettingsViewController
               }) {
                router.dismiss(animated: true, completion: nil)
            }
        case .qrScannerOpened:
            guard uuid != windowUUID else { return }
            let browserPresentedVC = router.navigationController.presentedViewController
            let rootVC = (browserPresentedVC as? UINavigationController)?.viewControllers.first
            if rootVC is QRCodeViewController {
                router.dismiss(animated: true, completion: nil)
                remove(child: childCoordinators.first(where: { $0 is QRCodeCoordinator }))
            }
        }
    }

    // MARK: - Private helpers

    private func tryDownloadingTabFileToShare(shareType: ShareType) async -> ShareType {
        // We can only try to download files for `.tab` type shares that have a TemporaryDocument
        guard case let ShareType.tab(_, tab) = shareType,
              let temporaryDocument = tab.temporaryDocument,
              !temporaryDocument.isDownloading else {
            return shareType
        }

        guard let fileURL = await temporaryDocument.download() else {
            // If no file was downloaded, simply share the tab as usual with a web URL
            return shareType
        }

        // If we successfully got a temp file URL, share it like a downloaded file
        return .file(url: fileURL)
    }

    /// Utility. Performs the supplied action if a coordinator of the indicated type
    /// is currently presenting its primary view controller.
    /// - Parameters:
    ///   - coordinatorType: the type of coordinator.
    ///   - action: the action to perform. The Coordinator instance is supplied for convenience.
    private func performIfCoordinatorRootVCIsPresented<T: Coordinator>(_ coordinatorType: T.Type,
                                                                       action: (T) -> Void) {
        guard let expectedCoordinator = childCoordinators[coordinatorType] else { return }
        let browserPresentedVC = router.navigationController.presentedViewController
        let rootVC = (browserPresentedVC as? UINavigationController)?.viewControllers.first
        if rootVC === expectedCoordinator.router.rootViewController {
            action(expectedCoordinator)
        }
    }
}
