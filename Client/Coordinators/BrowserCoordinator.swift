// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

protocol HomepageDelegate: AnyObject {
    func showHomepage(homepanelDelegate: HomePanelDelegate,
                      libraryPanelDelegate: LibraryPanelDelegate,
                      sendToDeviceDelegate: HomepageViewController.SendToDeviceDelegate,
                      overlayManager: OverlayModeManager)
    func showWebView()
}

class BrowserCoordinator: BaseCoordinator, LaunchCoordinatorDelegate, HomepageDelegate {
    var browserViewController: BrowserViewController
    private var profile: Profile

    init(router: Router,
         profile: Profile = AppContainer.shared.resolve(),
         tabManager: TabManager = AppContainer.shared.resolve()) {
        self.profile = profile
        self.browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        super.init(router: router)
        self.browserViewController.homepageDelegate = self
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

    // MARK: - HomepageDelegate

    func showHomepage(homepanelDelegate: HomePanelDelegate,
                      libraryPanelDelegate: LibraryPanelDelegate,
                      sendToDeviceDelegate: HomepageViewController.SendToDeviceDelegate,
                      overlayManager: OverlayModeManager) {
        let tabManager: TabManager = AppContainer.shared.resolve()
        let homepageViewController = HomepageViewController(
            profile: profile,
            tabManager: tabManager,
            overlayManager: overlayManager)
        homepageViewController.homePanelDelegate = homepanelDelegate
        homepageViewController.libraryPanelDelegate = libraryPanelDelegate
        homepageViewController.sendToDeviceDelegate = sendToDeviceDelegate

        browserViewController.embedContent(homepageViewController)

        // TODO: Laurie - Put this in homepage view controller view did appear
//        homepageViewController?.applyTheme()
//        homepageViewController?.homepageWillAppear(isZeroSearch: !inline)
//        homepageViewController?.reloadView()
//        NotificationCenter.default.post(name: .ShowHomepage, object: nil)
    }

    func showWebView() {
        // FXIOS-6015 - Show webview embedded content
    }
}
