// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import Shared

class BrowserCoordinator: BaseCoordinator, LaunchCoordinatorDelegate, BrowserDelegate {
    var browserViewController: BrowserViewController
    var webviewController: WebviewViewController?
    var homepageViewController: HomepageViewController?

    private var profile: Profile
    private let tabManager: TabManager
    private let themeManager: ThemeManager
    private var logger: Logger
    private let screenshotService: ScreenshotService
    private let glean: GleanWrapper
    private let applicationHelper: ApplicationHelper
    private let wallpaperManager: WallpaperManagerInterface

    init(router: Router,
         screenshotService: ScreenshotService,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         glean: GleanWrapper = DefaultGleanWrapper.shared,
         applicationHelper: ApplicationHelper = DefaultApplicationHelper(),
         wallpaperManager: WallpaperManagerInterface = WallpaperManager()) {
        self.screenshotService = screenshotService
        self.profile = profile
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        self.logger = logger
        self.applicationHelper = applicationHelper
        self.glean = glean
        self.wallpaperManager = wallpaperManager
        super.init(router: router)
        self.browserViewController.browserDelegate = self
    }

    func start(with launchType: LaunchType?) {
        router.push(browserViewController, animated: false)

        if let launchType = launchType, launchType.canLaunch(fromType: .BrowserCoordinator) {
            startLaunch(with: launchType)
        }
    }

    // MARK: - Helper methods

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
    }

    func didRequestToOpenInNewTab(from coordinator: LaunchCoordinator, url: URL, isPrivate: Bool) {
        didFinishLaunch(from: coordinator)

        let route = Route.search(url: url, isPrivate: isPrivate)
        findAndHandle(route: route)
    }

    // MARK: - BrowserDelegate

    func showHomepage(inline: Bool,
                      homepanelDelegate: HomePanelDelegate,
                      libraryPanelDelegate: LibraryPanelDelegate,
                      sendToDeviceDelegate: HomepageViewController.SendToDeviceDelegate,
                      overlayManager: OverlayModeManager) {
        var homepage: HomepageViewController
        if let homepageViewController = homepageViewController {
            homepage = homepageViewController
        } else {
            let homepageViewController = HomepageViewController(
                profile: profile,
                isZeroSearch: inline,
                overlayManager: overlayManager
            )
            homepageViewController.homePanelDelegate = homepanelDelegate
            homepageViewController.libraryPanelDelegate = libraryPanelDelegate
            homepageViewController.sendToDeviceDelegate = sendToDeviceDelegate
            homepage = homepageViewController
            self.homepageViewController = homepageViewController
        }

        browserViewController.embedContent(homepage)

        // We currently don't support full page screenshot of the homepage
        screenshotService.screenshotableView = nil
    }

    func show(webView: WKWebView?) {
        // Navigate with a new webview, or to the existing one
        if let webView = webView {
            let webviewViewController = WebviewViewController(webView: webView)
            webviewController = webviewViewController
            // Make sure we show the latest webview if we are provided with one
            browserViewController.embedContent(webviewViewController, forceEmbed: true)
        } else if let webviewController = webviewController {
            browserViewController.embedContent(webviewController)
        } else {
            logger.log("Webview controller couldn't be shown, this shouldn't happen.",
                       level: .fatal,
                       category: .lifecycle)
        }

        screenshotService.screenshotableView = webviewController
    }

    // MARK: - Route handling

    override func handle(route: Route) -> Bool {
        switch route {
        case let .searchQuery(query):
            handle(query: query)
            return true

        case let .search(url, isPrivate, options):
            handle(url: url, isPrivate: isPrivate, options: options)
            return true

        case let .searchURL(url, tabId):
            handle(searchURL: url, tabId: tabId)
            return true

        case let .glean(url):
            glean.handleDeeplinkUrl(url: url)
            return true

        case let .homepanel(section):
            handle(homepanelSection: section)
            return true

        case let .settings(section):
            // Note: This will be handled in the settings coordinator when FXIOS-6274 is done
            handle(settingsSection: section)
            return true

        case let .action(routeAction):
            switch routeAction {
            case .closePrivateTabs:
                handleClosePrivateTabs()
                return true
            case .showQRCode:
                handleQRCode()
                return true
            }

        case let .fxaSignIn(params):
            handle(fxaParams: params)
            return true

        case let .defaultBrowser(section):
            switch section {
            case .systemSettings:
                applicationHelper.openSettings()
            case .tutorial:
                startLaunch(with: .defaultBrowser)
            }
            return true
        }
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

    private func handle(settingsSection: Route.SettingsSection) {
        let baseSettingsVC = AppSettingsTableViewController(
            with: profile,
            and: tabManager,
            delegate: browserViewController
        )

        let controller = ThemedNavigationController(rootViewController: baseSettingsVC)
        controller.presentingModalViewControllerDelegate = browserViewController
        controller.modalPresentationStyle = .formSheet
        router.present(controller)

        guard let viewController = getSettingsViewController(settingsSection: settingsSection) else { return }
        controller.pushViewController(viewController, animated: true)
    }

    func getSettingsViewController(settingsSection section: Route.SettingsSection) -> UIViewController? {
        switch section {
        case .newTab:
            let viewController = NewTabContentSettingsViewController(prefs: profile.prefs)
            viewController.profile = profile
            return viewController

        case .homePage:
            let viewController = HomePageSettingViewController(prefs: profile.prefs)
            viewController.profile = profile
            return viewController

        case .mailto:
            let viewController = OpenWithSettingsViewController(prefs: profile.prefs)
            return viewController

        case .search:
            let viewController = SearchSettingsTableViewController(profile: profile)
            return viewController

        case .clearPrivateData:
            let viewController = ClearPrivateDataTableViewController()
            viewController.profile = profile
            viewController.tabManager = tabManager
            return viewController

        case .fxa:
            let fxaParams = FxALaunchParams(entrypoint: .fxaDeepLinkSetting, query: [:])
            let viewController = FirefoxAccountSignInViewController.getSignInOrFxASettingsVC(
                fxaParams,
                flowType: .emailLoginFlow,
                referringPage: .settings,
                profile: browserViewController.profile
            )
            return viewController

        case .theme:
            return ThemeSettingsController()

        case .wallpaper:
            if wallpaperManager.canSettingsBeShown {
                let viewModel = WallpaperSettingsViewModel(
                    wallpaperManager: wallpaperManager,
                    tabManager: tabManager,
                    theme: themeManager.currentTheme
                )
                let wallpaperVC = WallpaperSettingsViewController(viewModel: viewModel)
                return wallpaperVC
            } else {
                return nil
            }

        default:
            // For cases that are not yet handled we show the main settings page, more to come with FXIOS-6274
            return nil
        }
    }

    private func handle(fxaParams: FxALaunchParams) {
        browserViewController.presentSignInViewController(fxaParams)
    }
}
