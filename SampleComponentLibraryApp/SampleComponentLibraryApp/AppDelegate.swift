// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    lazy var themeManager: ThemeManager = DefaultThemeManager(
        sharedContainerIdentifier: DependencyHelper.baseBundleIdentifier
    )

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        DependencyHelper().bootstrapDependencies()
        return true
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
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
