// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import CoreSpotlight
import Shared
import UserNotifications
import Common

class SceneDelegate: UIResponder,
                     UIWindowSceneDelegate,
                     FeatureFlaggable {
    var window: UIWindow?

    let profile: Profile = AppContainer.shared.resolve()
    var sessionManager: AppSessionProvider = AppContainer.shared.resolve()
    var downloadQueue: DownloadQueue = AppContainer.shared.resolve()

    var sceneCoordinator: SceneCoordinator?
    var routeBuilder = RouteBuilder()

    private let logger: Logger = DefaultLogger.shared
    private let tabErrorTelemetryHelper = TabErrorTelemetryHelper.shared
    private var isDeeplinkOptimizationRefactorEnabled: Bool {
        return featureFlags.isFeatureEnabled(.deeplinkOptimizationRefactor, checking: .buildOnly)
    }

    // MARK: - Connecting / Disconnecting Scenes

    /// Invoked when the app creates OR restores an instance of the UI. This is also where deeplinks are handled
    /// when the app is launched from a cold start. The deeplink URLs are passed in via the `connectionOptions`.
    ///
    /// Use this method to respond to the addition of a new scene, and begin loading data that needs to display.
    /// Take advantage of what's given in `options`.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard !AppConstants.isRunningUnitTest else { return }
        logger.log("SceneDelegate: will connect to session", level: .info, category: .lifecycle)

        // Add hooks for the nimbus-cli to test experiments on device or involving deeplinks.
        if let url = connectionOptions.urlContexts.first?.url {
            Experiments.shared.initializeTooling(url: url)
        }

        routeBuilder.configure(
            isPrivate: UserDefaults.standard.bool(
                forKey: PrefsKeys.LastSessionWasPrivate
            ),
            prefs: profile.prefs
        )

        let sceneCoordinator = SceneCoordinator(scene: scene)
        self.sceneCoordinator = sceneCoordinator
        self.window = sceneCoordinator.window
        sceneCoordinator.start()
        handle(connectionOptions: connectionOptions)
        if !sessionManager.launchSessionProvider.openedFromExternalSource {
            AppEventQueue.signal(event: .recordStartupTimeOpenDeeplinkCancelled)
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        let logUUID = sceneCoordinator?.windowUUID.uuidString ?? "<nil>"
        logger.log("SceneDelegate: scene did disconnect. UUID: \(logUUID)", level: .info, category: .lifecycle)
        // Handle clean-up here for closing windows on iPad
        guard let sceneCoordinator = (scene.delegate as? SceneDelegate)?.sceneCoordinator else { return }

        // For now, we explicitly cancel downloads for windows that are closed.
        // On iPhone this will happen during app termination, for iPad it will
        // occur on termination or when a window is disconnected/closed by iPadOS
        downloadQueue.cancelAll(for: sceneCoordinator.windowUUID)

        // Notify WindowManager that window is closing
        (AppContainer.shared.resolve() as WindowManager).windowWillClose(uuid: sceneCoordinator.windowUUID)
        self.sceneCoordinator?.removeAllChildren()
        self.sceneCoordinator = nil
    }

    // MARK: - Transitioning to Foreground

    /// Invoked when the interface is finished loading for your screen, but before that interface appears on screen.
    ///
    /// Use this method to refresh the contents of your scene's view (especially if it's a restored scene),
    /// or other activities that need to begin.
    func sceneDidBecomeActive(_ scene: UIScene) {
        guard !AppConstants.isRunningUnitTest else { return }
        let logUUID = sceneCoordinator?.windowUUID.uuidString ?? "<nil>"
        logger.log("SceneDelegate: scene did become active. UUID: \(logUUID)", level: .info, category: .lifecycle)

        // Resume previously stopped downloads for, and on, THIS scene only.
        if let uuid = sceneCoordinator?.windowUUID {
            downloadQueue.resumeAll(for: uuid)
            AppEventQueue.wait(for: .tabRestoration(uuid)) {
                self.tabErrorTelemetryHelper.validateTabCountForForegroundedScene(uuid)
            }
        }
    }

    // MARK: - Transitioning to Background

    /// The scene's running in the background and not visible on screen.
    ///
    /// Use this method to reduce the scene's memory usage, clear claims to resources & dependencies / services.
    /// UIKit takes a snapshot of the scene for the app switcher after this method returns.
    func sceneDidEnterBackground(_ scene: UIScene) {
        let logUUID = sceneCoordinator?.windowUUID.uuidString ?? "<nil>"
        logger.log("SceneDelegate: scene did enter background. UUID: \(logUUID)", level: .info, category: .lifecycle)
        if let uuid = sceneCoordinator?.windowUUID {
            downloadQueue.pauseAll(for: uuid)
            tabErrorTelemetryHelper.recordTabCountForBackgroundedScene(uuid)
        }
    }

    // MARK: - Opening URLs

    /// Asks the delegate to open one or more URLs.
    ///
    /// This method is equivalent to AppDelegate's openURL method. Deeplinks opened while
    /// the app is running are passed in through this delegate method.
    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        guard let url = URLContexts.first?.url else { return }
        handleOpenURL(url)
    }

    // MARK: - Continuing User Activities

    /// Use this method to handle Handoff-related data or other activities.
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let route = routeBuilder.makeRoute(userActivity: userActivity) else { return }
        handle(route: route)
    }

    // MARK: - Performing Tasks

    /// Use this method to handle a selected shortcut action.
    ///
    /// Invoked when:
    /// - a user activates the application by selecting a shortcut item on the home screen AND
    /// - the window scene is already connected.
    func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        routeBuilder.configure(
            isPrivate: UserDefaults.standard.bool(
                forKey: PrefsKeys.LastSessionWasPrivate
            ),
            prefs: profile.prefs
        )

        guard let route = routeBuilder.makeRoute(shortcutItem: shortcutItem,
                                                 tabSetting: NewTabAccessors.getNewTabPage(profile.prefs))
        else { return }
        handle(route: route)
    }

    func handleOpenURL(_ url: URL) {
        routeBuilder.configure(
            isPrivate: UserDefaults.standard.bool(
                forKey: PrefsKeys.LastSessionWasPrivate
            ),
            prefs: profile.prefs
        )

        // Before processing the incoming URL, check if it is a widget that is opening a tab via UUID.
        // If so, we want to be sure that we select the tab in the correct iPad window.
        if shouldRerouteIncomingURLToSpecificWindow(url),
           let tabUUID = URLScanner(url: url)?.value(query: "uuid"),
           let targetWindow = (AppContainer.shared.resolve() as WindowManager).window(for: tabUUID),
           targetWindow != sceneCoordinator?.windowUUID {
            DefaultApplicationHelper().open(url, inWindow: targetWindow)
        } else {
            guard let route = routeBuilder.makeRoute(url: url) else { return }
            handle(route: route)
        }
    }

    // MARK: - Misc. Helpers

    private func shouldRerouteIncomingURLToSpecificWindow(_ url: URL) -> Bool {
        return routeBuilder.parseURLHost(url)?.shouldRouteDeeplinkToSpecificIPadWindow ?? false
    }

    private func handle(connectionOptions: UIScene.ConnectionOptions) {
        if let context = connectionOptions.urlContexts.first,
           let route = routeBuilder.makeRoute(url: context.url) {
            handle(route: route)
        }

        if let activity = connectionOptions.userActivities.first,
           let route = routeBuilder.makeRoute(userActivity: activity) {
            handle(route: route)
        }

        if let shortcut = connectionOptions.shortcutItem,
           let route = routeBuilder.makeRoute(shortcutItem: shortcut,
                                              tabSetting: NewTabAccessors.getNewTabPage(profile.prefs)) {
            handle(route: route)
        }

        // Check if our connection options include a user response to a push
        // notification that is for Sent Tabs. If so, route the related tab URLs.
        let sentTabsKey = NotificationSentTabs.sentTabsKey
        if let notification = connectionOptions.notificationResponse?.notification,
           let userInfo = notification.request.content.userInfo[sentTabsKey] as? [[String: Any]] {
            handleConnectionOptionsSentTabs(userInfo)
        }
    }

    private func handleConnectionOptionsSentTabs(_ userInfo: [[String: Any]]) {
        // For Sent Tab data structure, see also:
        // NotificationService.displayNewSentTabNotification()
        for tab in userInfo {
            guard let urlString = tab["url"] as? String,
                  let url = URL(string: urlString),
                  let route = routeBuilder.makeRoute(url: url) else { continue }
            handle(route: route)
        }
    }

    private func handle(route: Route) {
        guard let sceneCoordinator = sceneCoordinator else {
            logger.log("Scene coordinator should exist", level: .fatal, category: .coordinator)
            return
        }

        logger.log("Scene coordinator will handle a route", level: .info, category: .coordinator)
        sessionManager.launchSessionProvider.openedFromExternalSource = true

        if isDeeplinkOptimizationRefactorEnabled {
            sceneCoordinator.findAndHandle(route: route)
        } else {
            AppEventQueue.wait(for: [.startupFlowComplete, .tabRestoration(sceneCoordinator.windowUUID)]) { [weak self] in
                self?.logger.log("Start up flow and restoration done, will handle route",
                                 level: .info,
                                 category: .coordinator)
                sceneCoordinator.findAndHandle(route: route)
                AppEventQueue.signal(event: .recordStartupTimeOpenDeeplinkComplete)
            }
        }
    }
}
