// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import WebKit

class BrowserCoordinator: BaseCoordinator, LaunchCoordinatorDelegate, BrowserDelegate {
    var browserViewController: BrowserViewController
    var webviewController: WebviewViewController?
    var homepageViewController: HomepageViewController?

    private var profile: Profile
    private var logger: Logger
    private let screenshotService: ScreenshotService

    init(router: Router,
         screenshotService: ScreenshotService,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve(),
         logger: Logger = DefaultLogger.shared) {
        self.screenshotService = screenshotService
        self.profile = profile
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
}
