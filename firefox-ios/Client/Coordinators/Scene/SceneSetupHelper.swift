// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

struct SceneSetupHelper {
    func configureWindowFor(_ scene: UIScene,
                            screenshotServiceDelegate: UIScreenshotServiceDelegate) -> UIWindow {
        guard let windowScene = (scene as? UIWindowScene) else {
            return UIWindow(frame: UIScreen.main.bounds)
        }

        windowScene.screenshotService?.delegate = screenshotServiceDelegate

        let window = UIWindow(windowScene: windowScene)

        // Setting the initial theme correctly as we don't have a window attached yet to let ThemeManager set it
        var themeManager: ThemeManager = AppContainer.shared.resolve()
        themeManager.window = window
        window.overrideUserInterfaceStyle = themeManager.currentTheme.type.getInterfaceStyle()

        return window
    }

    func createNavigationController() -> UINavigationController {
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)

        return navigationController
    }
}
