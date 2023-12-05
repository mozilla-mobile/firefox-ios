// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import Shared
import Storage
import Redux
import TabDataStore

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
                          TabTrayCoordinatorDelegate {
    var browserViewController: BrowserViewController
    var webviewController: WebviewViewController?
    var homepageViewController: HomepageViewController?

    private var profile: Profile
    private let tabManager: TabManager
    private let themeManager: ThemeManager
    private let screenshotService: ScreenshotService
    private let glean: GleanWrapper
    private let applicationHelper: ApplicationHelper
    private var browserIsReady = false

    init(router: Router,
         screenshotService: ScreenshotService,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve(),
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         glean: GleanWrapper = DefaultGleanWrapper.shared,
         applicationHelper: ApplicationHelper = DefaultApplicationHelper()) {
        self.screenshotService = screenshotService
        self.profile = profile
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        self.applicationHelper = applicationHelper
        self.glean = glean
        super.init(router: router)

        tabManagerDidConnectToScene()
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

    private func tabManagerDidConnectToScene() {
        // [7863] [WIP] Redux: connect this Browser's TabManager to associated window scene
        guard ReduxFlagManager.isReduxEnabled else { return }
        let sceneUUID = WindowData.DefaultSingleWindowUUID
        store.dispatch(TabManagerAction.tabManagerDidConnectToScene(tabManager, sceneUUID))
    }

    private func startLaunch(with launchType: LaunchType) {
        let launchCoordinator = LaunchCoordinator(router: router)
        launchCoordinator.parentCoordinator = self
        add(child: launchCoordinator)
        launchCoordinator.start(with: launchType)
    }

    // MARK: - LaunchCoordinatorDelegate

    func didFinishLaunch(from coordinator: LaunchCoordinator) {
        router.dismiss(animated: true, completion: nil)
        remove(child: coordinator)

        // Once launch is done, we check for any saved Route
        if let savedRoute {
            findAndHandle(route: savedRoute)
        }
    }

    // MARK: - BrowserDelegate

    func showHomepage(inline: Bool,
                      toastContainer: UIView,
                      homepanelDelegate: HomePanelDelegate,
                      libraryPanelDelegate: LibraryPanelDelegate,
                      sendToDeviceDelegate: HomepageViewController.SendToDeviceDelegate,
                      statusBarScrollDelegate: StatusBarScrollDelegate,
                      overlayManager: OverlayModeManager) {
        let homepageController = getHomepage(inline: inline,
                                             toastContainer: toastContainer,
                                             homepanelDelegate: homepanelDelegate,
                                             libraryPanelDelegate: libraryPanelDelegate,
                                             sendToDeviceDelegate: sendToDeviceDelegate,
                                             statusBarScrollDelegate: statusBarScrollDelegate,
                                             overlayManager: overlayManager)

        guard browserViewController.embedContent(homepageController) else { return }
        self.homepageViewController = homepageController
        homepageController.scrollToTop()
        // We currently don't support full page screenshot of the homepage
        screenshotService.screenshotableView = nil
    }

    func show(webView: WKWebView) {
        // Keep the webviewController in memory, update to newest webview when needed
        if let webviewController = webviewController {
            webviewController.update(webView: webView, isPrivate: tabManager.selectedTab?.isPrivate ?? false)
            browserViewController.frontEmbeddedContent(webviewController)
        } else {
            let webviewViewController = WebviewViewController(webView: webView, isPrivate: tabManager.selectedTab?.isPrivate ?? false)
            webviewController = webviewViewController
            _ = browserViewController.embedContent(webviewViewController)
        }

        screenshotService.screenshotableView = webviewController
    }

    func browserHasLoaded() {
        browserIsReady = true
        logger.log("Browser has loaded", level: .info, category: .coordinator)

        if let savedRoute {
            findAndHandle(route: savedRoute)
        }
    }

    private func getHomepage(inline: Bool,
                             toastContainer: UIView,
                             homepanelDelegate: HomePanelDelegate,
                             libraryPanelDelegate: LibraryPanelDelegate,
                             sendToDeviceDelegate: HomepageViewController.SendToDeviceDelegate,
                             statusBarScrollDelegate: StatusBarScrollDelegate,
                             overlayManager: OverlayModeManager) -> HomepageViewController {
        if let homepageViewController = homepageViewController {
            homepageViewController.configure(isZeroSearch: inline)
            return homepageViewController
        } else {
            let homepageViewController = HomepageViewController(
                profile: profile,
                isZeroSearch: inline,
                toastContainer: toastContainer,
                overlayManager: overlayManager)
            homepageViewController.homePanelDelegate = homepanelDelegate
            homepageViewController.libraryPanelDelegate = libraryPanelDelegate
            homepageViewController.sendToDeviceDelegate = sendToDeviceDelegate
            homepageViewController.statusBarScrollDelegate = statusBarScrollDelegate
            homepageViewController.browserNavigationHandler = self

            return homepageViewController
        }
    }

    // MARK: - Route handling

    override func canHandle(route: Route) -> Bool {
        guard browserIsReady, !tabManager.isRestoringTabs else {
            let readyMessage = "browser is ready? \(browserIsReady)"
            let restoringMessage = "is restoring tabs? \(tabManager.isRestoringTabs)"
            logger.log("Could not handle route, \(readyMessage), \(restoringMessage)",
                       level: .info,
                       category: .coordinator)
            return false
        }

        switch route {
        case .searchQuery, .search, .searchURL, .glean, .homepanel, .action, .fxaSignIn, .defaultBrowser:
            return true
        case let .settings(section):
            return canHandleSettings(with: section)
        }
    }

    override func handle(route: Route) {
        guard browserIsReady, !tabManager.isRestoringTabs else {
            return
        }

        logger.log("Handling a route", level: .info, category: .coordinator)
        switch route {
        case let .searchQuery(query):
            handle(query: query)

        case let .search(url, isPrivate, options):
            handle(url: url, isPrivate: isPrivate, options: options)

        case let .searchURL(url, tabId):
            handle(searchURL: url, tabId: tabId)

        case let .glean(url):
            glean.handleDeeplinkUrl(url: url)

        case let .homepanel(section):
            handle(homepanelSection: section)

        case let .settings(section):
            handleSettings(with: section)

        case let .action(routeAction):
            switch routeAction {
            case .closePrivateTabs:
                handleClosePrivateTabs()
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

    private func handleClosePrivateTabs() {
        browserViewController.handleClosePrivateTabs()
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
            browserViewController.openBlankNewTab(focusLocationField: false, isPrivate: true)
        case .newTab:
            browserViewController.openBlankNewTab(focusLocationField: false)
        }
    }

    private func handle(query: String) {
        browserViewController.handle(query: query)
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

    private func canHandleSettings(with section: Route.SettingsSection) -> Bool {
        guard !childCoordinators.contains(where: { $0 is SettingsCoordinator }) else {
            return false // route is handled with existing child coordinator
        }
        return true
    }

    private func handleSettings(with section: Route.SettingsSection) {
        guard !childCoordinators.contains(where: { $0 is SettingsCoordinator }) else {
            return // route is handled with existing child coordinator
        }
        let navigationController = ThemedNavigationController()
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let modalPresentationStyle: UIModalPresentationStyle = isPad ? .fullScreen: .formSheet
        navigationController.modalPresentationStyle = modalPresentationStyle
        let settingsRouter = DefaultRouter(navigationController: navigationController)

        let settingsCoordinator = SettingsCoordinator(router: settingsRouter)
        settingsCoordinator.parentCoordinator = self
        add(child: settingsCoordinator)
        settingsCoordinator.start(with: section)

        router.present(navigationController) { [weak self] in
            self?.didFinishSettings(from: settingsCoordinator)
        }
    }

    private func showLibrary(with homepanelSection: Route.HomepanelSection) {
        if let libraryCoordinator = childCoordinators[LibraryCoordinator.self] {
            libraryCoordinator.start(with: homepanelSection)
            (libraryCoordinator.router.navigationController as? UINavigationController).map { router.present($0) }
        } else {
            let navigationController = DismissableNavigationViewController()
            navigationController.modalPresentationStyle = .formSheet

            let libraryCoordinator = LibraryCoordinator(
                router: DefaultRouter(navigationController: navigationController)
            )
            libraryCoordinator.parentCoordinator = self
            add(child: libraryCoordinator)
            libraryCoordinator.start(with: homepanelSection)

            router.present(navigationController)
        }
    }

    private func showETPMenu(sourceView: UIView) {
        let enhancedTrackingProtectionCoordinator = EnhancedTrackingProtectionCoordinator(router: router)
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

    func openRecentlyClosedSiteInSameTab(_ url: URL) {
        browserViewController.openRecentlyClosedSiteInSameTab(url)
    }

    func openRecentlyClosedSiteInNewTab(_ url: URL, isPrivate: Bool) {
        browserViewController.openRecentlyClosedSiteInNewTab(url, isPrivate: isPrivate)
    }

    func libraryPanelDidRequestToOpenInNewTab(_ url: URL, isPrivate: Bool) {
        browserViewController.libraryPanelDidRequestToOpenInNewTab(url, isPrivate: isPrivate)
        router.dismiss()
    }

    func libraryPanel(didSelectURL url: URL, visitType: Storage.VisitType) {
        browserViewController.libraryPanel(didSelectURL: url, visitType: visitType)
        router.dismiss()
    }

    func didFinishLibrary(from coordinator: LibraryCoordinator) {
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

    // MARK: - BrowserNavigationHandler

    func show(settings: Route.SettingsSection) {
        presentWithModalDismissIfNeeded {
            self.handleSettings(with: settings)
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
        guard let fakespotCoordinator = childCoordinators.first(where: { $0 is FakespotCoordinator }) as? FakespotCoordinator else {
            return // there is no modal to close
        }
        fakespotCoordinator.dismissModal(animated: animated)
    }

    func dismissFakespotSidebar(sidebarContainer: SidebarEnabledViewProtocol, parentViewController: UIViewController) {
        guard let fakespotCoordinator = childCoordinators.first(where: { $0 is FakespotCoordinator }) as? FakespotCoordinator else {
            return // there is no sidebar to close
        }
        fakespotCoordinator.closeSidebar(sidebarContainer: sidebarContainer,
                                         parentViewController: parentViewController)
    }

    func updateFakespotSidebar(productURL: URL,
                               sidebarContainer: SidebarEnabledViewProtocol,
                               parentViewController: UIViewController) {
        guard let fakespotCoordinator = childCoordinators.first(where: { $0 is FakespotCoordinator }) as? FakespotCoordinator else {
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

        let coordinator = FakespotCoordinator(router: router)
        coordinator.parentCoordinator = self
        add(child: coordinator)
        return coordinator
    }

    func showShareExtension(url: URL, sourceView: UIView, sourceRect: CGRect?, toastContainer: UIView, popoverArrowDirection: UIPopoverArrowDirection) {
        guard childCoordinators.first(where: { $0 is ShareExtensionCoordinator }) as? ShareExtensionCoordinator == nil
        else {
            // If this case is hitted it means the share extension coordinator wasn't removed correctly in the previous session.
            return
        }
        let shareExtensionCoordinator = ShareExtensionCoordinator(alertContainer: toastContainer, router: router, profile: profile, parentCoordinator: self)
        add(child: shareExtensionCoordinator)
        shareExtensionCoordinator.start(url: url, sourceView: sourceView, sourceRect: sourceRect, popoverArrowDirection: popoverArrowDirection)
    }

    func showCreditCardAutofill(creditCard: CreditCard?,
                                decryptedCard: UnencryptedCreditCardFields?,
                                viewType state: CreditCardBottomSheetState,
                                frame: WKFrameInfo?,
                                alertContainer: UIView) {
        let bottomSheetCoordinator = makeCredentialAutofillCoordinator()
        bottomSheetCoordinator.showCreditCardAutofill(creditCard: creditCard, decryptedCard: decryptedCard, viewType: state, frame: frame, alertContainer: alertContainer)
    }

    func showRequiredPassCode() {
        let bottomSheetCoordinator = makeCredentialAutofillCoordinator()
        bottomSheetCoordinator.showPassCodeController()
    }

    private func makeCredentialAutofillCoordinator() -> CredentialAutofillCoordinator {
        if let bottomSheetCoordinator = childCoordinators.first(where: { $0 is CredentialAutofillCoordinator }) as? CredentialAutofillCoordinator {
            return bottomSheetCoordinator
        }
        let bottomSheetCoordinator = CredentialAutofillCoordinator(profile: profile, router: router, parentCoordinator: self)
        add(child: bottomSheetCoordinator)
        return bottomSheetCoordinator
    }

    func showQRCode() {
        var coordinator: QRCodeCoordinator
        if let qrCodeCoordinator = childCoordinators.first(where: { $0 is QRCodeCoordinator }) as? QRCodeCoordinator {
            coordinator = qrCodeCoordinator
        } else {
            coordinator = QRCodeCoordinator(parentCoordinator: self, router: router)
            add(child: coordinator)
        }
        coordinator.showQRCode(delegate: browserViewController)
    }

    func showTabTray(selectedPanel: TabTrayPanelType) {
        guard !childCoordinators.contains(where: { $0 is TabTrayCoordinator }) else {
            return // flow is already handled
        }

        let navigationController = DismissableNavigationViewController()
        let isPad = UIDevice.current.userInterfaceIdiom == .pad
        let modalPresentationStyle: UIModalPresentationStyle = isPad ? .fullScreen: .formSheet
        navigationController.modalPresentationStyle = modalPresentationStyle

        let tabTrayCoordinator = TabTrayCoordinator(
            router: DefaultRouter(navigationController: navigationController),
            tabTraySection: selectedPanel
        )
        tabTrayCoordinator.parentCoordinator = self
        add(child: tabTrayCoordinator)
        tabTrayCoordinator.start(with: selectedPanel)

        router.present(navigationController)
    }

    // MARK: - ParentCoordinatorDelegate
    func didFinish(from childCoordinator: Coordinator) {
        remove(child: childCoordinator)
    }

    // MARK: - TabManagerDelegate
    func tabManagerDidRestoreTabs(_ tabManager: TabManager) {
        // Once tab restore is made, if there's any saved route we make sure to call it
        if let savedRoute {
            findAndHandle(route: savedRoute)
        }
    }

    // MARK: - TabTrayCoordinatorDelegate
    func didDismissTabTray(from coordinator: TabTrayCoordinator) {
        router.dismiss(animated: true, completion: nil)
        remove(child: coordinator)
    }
}
