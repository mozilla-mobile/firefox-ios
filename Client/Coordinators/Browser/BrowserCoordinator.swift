// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit
import Glean
import Shared

class BrowserCoordinator: BaseCoordinator, LaunchCoordinatorDelegate, BrowserDelegate {
    var browserViewController: BrowserViewController
    var webviewController: WebviewViewController?
    var homepageViewController: HomepageViewController?

    private var profile: Profile
    private let tabManager: TabManager
    private let themeManager: ThemeManager
    private var logger: Logger

    init(router: Router,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.profile = profile
        self.tabManager = tabManager
        self.themeManager = themeManager
        self.browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        self.logger = logger
        super.init(router: router)
        self.browserViewController.browserDelegate = self
    }

    func start(with launchType: LaunchType?) {
        router.setRootViewController(browserViewController, hideBar: true, animated: true)

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

    func didRequestToOpenInNewTab(url: URL, isPrivate: Bool, selectNewTab: Bool) {
        // FXIOS-6030: Handle open in new tab route
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
    }

    override func handle(route: Route) -> Bool {
        switch route {
        case .searchQuery(query: let query):
            self.handle(query: query)
            return true

        case .search(url: let url, isPrivate: let isPrivate, options: let options):
            self.handle(url: url, isPrivate: isPrivate, options: options)
            return true

        case .searchURL(url: let url, tabId: let tabId):
            self.handle(searchURL: url, tabId: tabId)
            return false

        case .glean(url: let url):
            self.handle(gleanURL: url)
            return true

        case .homepanel(section: let section):
            self.handle(homepanelSection: section)
            return true

        case .settings(section: let section):
            // TODO: - Great candidate for a Settings Coordinator
            self.handle(settingsSection: section)
            return true

        case .action(action: let action):
            switch action {
            case .closePrivateTabs:
                self.handleClosePrivateTabs()
                return true
            case .presentDefaultBrowserOnboarding:
                return false
            case .showQRCode:
                self.handleQRCode()
                return true
            }

        case .fxaSignIn(params: let params):
            self.handle(fxaParams: params)
            return true

        case .defaultBrowser(section: let section):
            self.handle(defaultBrowserSection: section)
            return true
        }
    }

    private func handle(searchURL: URL?, tabId: String) {
        if let newURL = searchURL {
            self.browserViewController.switchToTabForURLOrOpen(newURL, uuid: tabId, isPrivate: false)
        } else {
            self.browserViewController.openBlankNewTab(focusLocationField: true, isPrivate: false)
        }
    }

    private func handleQRCode() {
        let qrCodeViewController = QRCodeViewController()
        qrCodeViewController.qrCodeDelegate = self.browserViewController
        self.browserViewController.presentedViewController?.dismiss(animated: true)
        self.browserViewController.present(UINavigationController(rootViewController: qrCodeViewController), animated: true, completion: nil)
    }

    private func handleClosePrivateTabs() {
        browserViewController.tabManager.removeTabs(browserViewController.tabManager.privateTabs)
        guard let tab = mostRecentTab(inTabs: browserViewController.tabManager.normalTabs) else {
            browserViewController.tabManager.selectTab(browserViewController.tabManager.addTab())
            return
        }
        browserViewController.tabManager.selectTab(tab)
    }

    private func handle(query: String) {
        browserViewController.openBlankNewTab(focusLocationField: false)
        browserViewController.urlBar(browserViewController.urlBar, didSubmitText: query)
    }

    private func handle(fxaParams: FxALaunchParams) {
        browserViewController.presentSignInViewController(fxaParams)
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

    private func handle(url: URL?, isPrivate: Bool, options: Set<Route.SearchOptions>? = nil) {
        if let url = url {
            if options?.contains(.switchToNormalMode) == true {
                browserViewController.switchToPrivacyMode(isPrivate: false)
            }
            browserViewController.switchToTabForURLOrOpen(url, isPrivate: isPrivate)
        } else {
            browserViewController.openBlankNewTab(focusLocationField: options?.contains(.focusLocationField) == true, isPrivate: isPrivate)
        }
    }

    private func handle(gleanURL: URL) {
        Glean.shared.handleCustomUrl(url: gleanURL)
    }

    private func handle(defaultBrowserSection section: Route.DefaultBrowserSection) {
        switch section {
        case .systemSettings:
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:])
        case .tutorial:
            browserViewController.presentDBOnboardingViewController(true)
        }
    }

    private func handle(settingsSection: Route.SettingsSection) {
        guard let viewController = getViewController(settingsSection: settingsSection) else { return }
        let baseSettingsVC = AppSettingsTableViewController(
            with: self.browserViewController.profile,
            and: self.browserViewController.tabManager,
            delegate: self.browserViewController
        )

        let controller = ThemedNavigationController(rootViewController: baseSettingsVC)
        controller.presentingModalViewControllerDelegate = self.browserViewController
        controller.modalPresentationStyle = .formSheet
        router.present(controller, animated: true, completion: nil)

        controller.pushViewController(viewController, animated: true)
    }

    private func getViewController(settingsSection section: Route.SettingsSection) -> UIViewController? {
        switch section {
        case .general:
            return nil // Intentional NOOP; Already displaying the general settings VC

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
                profile: self.browserViewController.profile
            )
            return viewController

        case .theme:
            return ThemeSettingsController()

        case .wallpaper:
            let wallpaperManager = WallpaperManager()
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

        case .systemDefaultBrowser:
            return nil

        case .contentBlocker:
            return nil

        case .toolbar:
            return nil

        case .tabs:
            return nil

        case .topSites:
            return nil
        }
    }
}
