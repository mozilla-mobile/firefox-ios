// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import WebEngine

@main
class AppDelegate: UIResponder, UIApplicationDelegate, Notifiable {
    var notificationCenter: NotificationProtocol = NotificationCenter.default

    lazy var themeManager: ThemeManager = DefaultThemeManager(
        sharedContainerIdentifier: DependencyHelper.baseBundleIdentifier
    )

    lazy var engineDependencyManager = EngineDependencyManager()
    var engineProvider: EngineProvider?

    func application(
        _ application: UIApplication,
        willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Task {
            self.engineProvider = await EngineProviderManager.shared.getProvider()
            engineProvider?.warmEngine()
        }

        return true
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        DependencyHelper().bootstrapDependencies()
        AppLaunchUtil().setUpPreLaunchDependencies()
        addObservers()
        // Override point for customization after application launch.
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        engineProvider?.idleEngine()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        engineProvider?.warmEngine()
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

    // MARK: Notifications

    private func addObservers() {
        setupNotifications(forObserver: self, observing: [UIApplication.didBecomeActiveNotification,
                                                          UIApplication.didEnterBackgroundNotification])
    }

    /// When migrated to Scenes, these methods aren't called so using the same as in Firefox iOS application.
    func handleNotifications(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didBecomeActiveNotification:
            applicationDidBecomeActive(UIApplication.shared)
        case UIApplication.didEnterBackgroundNotification:
            applicationDidEnterBackground(UIApplication.shared)

        default: break
        }
    }
}
