// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

/// Each scene has it's own scene coordinator, which is the root coordinator for a scene.
class SceneCoordinator: BaseCoordinator, OpenURLDelegate {
    var window: UIWindow?
    var launchScreenManager: LaunchScreenManager

    init(scene: UIScene,
         launchScreenManager: LaunchScreenManager,
         sceneSetupHelper: SceneSetupHelper = SceneSetupHelper()) {
        self.window = sceneSetupHelper.configureWindowFor(scene, screenshotServiceDelegate: nil)
        let navigationController = sceneSetupHelper.createNavigationController()
        let router = DefaultRouter(navigationController: navigationController)
        self.launchScreenManager = launchScreenManager
        super.init(router: router)

        self.launchScreenManager.set(openURLDelegate: self)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    func start() {
        let launchScreenVC = LaunchScreenViewController()
        router.setRootViewController(launchScreenVC, hideBar: true)
    }

    // MARK: - OpenURLDelegate

    func didRequestToOpenInNewTab(url: URL, isPrivate: Bool, selectNewTab: Bool) {
        // FXIOS-6030: openURL in new tab route
    }

    // MARK: - LaunchFinishedLoadingDelegate

    func launchTypeLoaded() {
        if let launchType = launchScreenManager.getLaunchType(forType: .SceneCoordinator) {
            startLaunch(with: launchType)
        } else {
            startBrowser()
        }
    }

    // MARK: - Helper methods

    private func startLaunch(with launchType: LaunchType) {
        let launchCoordinator = LaunchCoordinator(router: router, launchScreenManager: launchScreenManager)
        add(child: launchCoordinator)
        launchCoordinator.start(with: launchType) {
            self.remove(child: launchCoordinator)
            self.startBrowser()
        }
    }

    private func startBrowser() {
        let browserCoordinator = BrowserCoordinator(router: router, launchScreenManager: launchScreenManager)
        add(child: browserCoordinator)
        browserCoordinator.start()
    }
}
