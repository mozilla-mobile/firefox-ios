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

<<<<<<< HEAD
    lazy var engineDependencyManager = EngineDependencyManager()
    var engineProvider: EngineProvider?
=======
    lazy var engineProvider: EngineProvider = {
        let parameters = WKWebviewParameters(blockPopups: false,
                                             isPrivate: false)
        let sessionDependencies = EngineSessionDependencies(webviewParameters: parameters,
                                                            readerModeDelegate: ReaderModeDelegate(),
                                                            telemetryProxy: TelemetryHandler())

        let readerModeConfig = ReaderModeConfiguration(loadingText: "Loading",
                                                       loadingFailedText: "Loading failed",
                                                       loadOriginalText: "Loading",
                                                       readerModeErrorText: "Error")
        let engineDependencies = EngineDependencies(readerModeConfiguration: readerModeConfig)
        let engine = WKEngine.factory(engineDependencies: engineDependencies)
        return EngineProvider(engine: engine, sessionDependencies: sessionDependencies)!
    }()
>>>>>>> b7975dc676 (Fix sample browser)

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

class ReaderModeDelegate: WKReaderModeDelegate {
    func readerMode(_ readerMode: ReaderModeStyleSetter,
                    didChangeReaderModeState state: ReaderModeState,
                    forSession session: EngineSession) {
        print("Laurie - didChangeReaderModeState state: \(state)")
    }

    func readerMode(_ readerMode: ReaderModeStyleSetter,
                    didDisplayReaderizedContentForSession session: EngineSession) {
        print("Laurie - didDisplayReaderizedContentForSession")
    }

    func readerMode(_ readerMode: ReaderModeStyleSetter,
                    didParseReadabilityResult readabilityResult: ReadabilityResult,
                    forSession session: EngineSession) {
        print("Laurie - didParseReadabilityResult readabilityResult: \(readabilityResult)")
    }
}
