// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebEngine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let tempVC = UIViewController()
        tempVC.view.backgroundColor = .systemBackground

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        window.rootViewController = tempVC
        window.makeKeyAndVisible()

        Task {
            let engineProvider = await EngineProviderManager.shared.getProvider()
            let windowUUID = UUID()
            let rootVC = RootViewController(engineProvider: engineProvider, windowUUID: windowUUID)

            await MainActor.run {
                window.rootViewController = rootVC

                let themeManager: ThemeManager = AppContainer.shared.resolve()
                themeManager.setWindow(window, for: windowUUID)
                themeManager.setSystemTheme(isOn: true)
            }
        }
    }
}
