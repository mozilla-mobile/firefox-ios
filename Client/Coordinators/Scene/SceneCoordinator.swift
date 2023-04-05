// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

/// Each scene has it's own scene coordinator, which is the root coordinator for a scene.
class SceneCoordinator: BaseCoordinator, OpenURLDelegate {
    var window: UIWindow?
    var browserCoordinator: BrowserCoordinator?
    var launchCoordinator: LaunchCoordinator?

    init(scene: UIScene, sceneSetupHelper: SceneSetupHelper = SceneSetupHelper()) {
        self.window = sceneSetupHelper.configureWindowFor(scene, screenshotServiceDelegate: nil)
        let navigationController = sceneSetupHelper.createNavigationController()
        let router = DefaultRouter(navigationController: navigationController)
        super.init(router: router)

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    func start(with launchManager: LaunchManager) {
        if launchManager.canLaunchFromSceneCoordinator, let launchType = launchManager.getLaunchType() {
            launchCoordinator = LaunchCoordinator(router: router)
            launchCoordinator?.start(with: launchType)
        } else {
            browserCoordinator = BrowserCoordinator(router: router)
            browserCoordinator?.start(launchManager: launchManager)
        }
    }

    // MARK: - OpenURLDelegate

    func didRequestToOpenInNewTab(url: URL, isPrivate: Bool, selectNewTab: Bool) {
        // FXIOS-6030: openURL in new tab route
    }
}
