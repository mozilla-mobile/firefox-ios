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
    private let screenshotService: ScreenshotService

    init(router: Router,
         screenshotService: ScreenshotService,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.screenshotService = screenshotService
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

    override func handle(route: Route) -> Bool {
        switch route {
        case .searchQuery:
            // FXIOS-6017 #13661 - Enable search path in BrowserCoordinator
            return false

        case .search:
            // FXIOS-6017 #13661 - Enable search path in BrowserCoordinator
            return false

        case .searchURL:
            // FXIOS-6017 #13661 - Enable search path in BrowserCoordinator
            return false

        case .glean:
            // FXIOS-6018 #13662 - Enable Glean path in BrowserCoordinator
            return false

        case .homepanel:
            // FXIOS-6029 #13679 ⁃ Enable homepanel in BrowserCoordinator
            return false

        case .settings:
            // FXIOS-6028 #13677 - Enable settings route path in BrowserCoordinator
            return false

        case .action:
            // FXIOS-6030 #13678 - Enable AppAction route path in BrowserCoordinator
            return false

        case .fxaSignIn:
            // FXIOS-6031 #13680 - Enable FxaSignin route path in BrowserCoordinator
            return false

        case .defaultBrowser:
            // FXIOS-6032 #13681 - Enable defaultBrowser route path in BrowserCoordinator
            return false
        }
    }
}
