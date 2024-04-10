// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let rootViewController = RootViewController()
        let navigationController = UINavigationController(rootViewController: rootViewController)

        let newWindow = UIWindow(windowScene: windowScene)
        window = newWindow
        newWindow.rootViewController = navigationController
        newWindow.makeKeyAndVisible()

        let themeManager: ThemeManager = AppContainer.shared.resolve()
        themeManager.setWindow(newWindow, for: defaultSampleComponentUUID)
        themeManager.setSystemTheme(isOn: true)
    }
}
