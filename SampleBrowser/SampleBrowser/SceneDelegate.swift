// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebEngine

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var engineProvider: EngineProvider = {
        let dependencies = EngineSessionDependencies(telemetryProxy: TelemetryHandler())
        return EngineProvider(sessionDependencies: dependencies)
    }()

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let windowUUID = UUID()
        let baseViewController = RootViewController(engineProvider: engineProvider, windowUUID: windowUUID)
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = baseViewController
        window?.makeKeyAndVisible()

        guard let window else { return }
        let themeManager: ThemeManager = AppContainer.shared.resolve()
        themeManager.setWindow(window, for: windowUUID)
        themeManager.setSystemTheme(isOn: true)
    }
}
