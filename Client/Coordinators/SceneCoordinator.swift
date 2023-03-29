// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// Each scene has it's own scene coordinator, which is the root coordinator for a scene.
class SceneCoordinator: BaseCoordinator {
    var window: UIWindow?
    var browserCoordinator: BrowserCoordinator?

    func start(with scene: UIScene) {
        self.window = configureWindowFor(scene)
        let navigationController = createNavigationController()

        // FXIOS-5986: Add launch instructor to either start onboarding or browser
        let router = DefaultRouter(navigationController: navigationController)
        browserCoordinator = BrowserCoordinator(router: router)
        browserCoordinator?.start()

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }

    // MARK: - Helpers

    private func configureWindowFor(_ scene: UIScene) -> UIWindow {
        guard let windowScene = (scene as? UIWindowScene) else {
            return UIWindow(frame: UIScreen.main.bounds)
        }

        // FXIOS-6087: Handle screenshot service since this won't be done from Scene Delegate anymore
        // windowScene.screenshotService?.delegate = self

        let window = UIWindow(windowScene: windowScene)

        // Setting the initial theme correctly as we don't have a window attached yet to let ThemeManager set it
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        window.overrideUserInterfaceStyle = themeManager.currentTheme.type.getInterfaceStyle()

        return window
    }

    private func createNavigationController() -> UINavigationController {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)

        return navigationController
    }
}
