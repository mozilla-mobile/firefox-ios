// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared

class BrowserWindow: UIWindow {
    let uuid: WindowUUID

    init(frame: CGRect, uuid: WindowUUID) {
        self.uuid = uuid
        super.init(frame: frame)
    }

    init(windowScene: UIWindowScene, uuid: WindowUUID) {
        self.uuid = uuid
        super.init(windowScene: windowScene)
    }

    required init?(coder: NSCoder) {
        assertionFailure("init(coder:) currently unsupported for BrowserWindow")
        self.uuid = .unavailable
        super.init(coder: coder)
    }
}

struct SceneSetupHelper {
    func configureWindowFor(_ scene: UIScene,
                            windowUUID: WindowUUID,
                            screenshotServiceDelegate: UIScreenshotServiceDelegate) -> UIWindow {
        guard let windowScene = (scene as? UIWindowScene) else {
            return BrowserWindow(frame: UIScreen.main.bounds, uuid: windowUUID)
        }

        windowScene.screenshotService?.delegate = screenshotServiceDelegate

        let window = BrowserWindow(windowScene: windowScene, uuid: windowUUID)

        // Setting the initial theme correctly as we don't have a window attached yet to let ThemeManager set it
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        themeManager.setWindow(window, for: windowUUID)
        window.overrideUserInterfaceStyle = themeManager.getCurrentTheme(for: windowUUID).type.getInterfaceStyle()

        return window
    }

    func createNavigationController() -> UINavigationController {
        let navigationController = RootNavigationController()
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)

        return navigationController
    }
}

class RootNavigationController: UINavigationController {
    override var prefersStatusBarHidden: Bool {
        return true
    }
}
