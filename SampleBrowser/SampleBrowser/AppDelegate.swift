// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebEngine

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    lazy var themeManager: ThemeManager = DefaultThemeManager(
        sharedContainerIdentifier: DependencyHelper.baseBundleIdentifier
    )

    lazy var engineProvider: EngineProvider = {
        let dependencies = EngineSessionDependencies(telemetryProxy: TelemetryHandler())
        return EngineProvider(sessionDependencies: dependencies)!
    }()

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        DependencyHelper().bootstrapDependencies()
        AppLaunchUtil().setUpPreLaunchDependencies()

        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
