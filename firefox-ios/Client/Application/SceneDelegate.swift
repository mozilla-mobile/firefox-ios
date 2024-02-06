// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import CoreSpotlight
import Storage
import Shared
import Sync
import UserNotifications
import Account
import MozillaAppServices
import Common

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    let profile: Profile = AppContainer.shared.resolve()
    var sessionManager: AppSessionProvider = AppContainer.shared.resolve()
    var downloadQueue: DownloadQueue = AppContainer.shared.resolve()

    var sceneCoordinator: SceneCoordinator?
    var routeBuilder = RouteBuilder()
    private let logger: Logger = DefaultLogger.shared

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
        logWillConnectToSession(options: connectionOptions)

        // Add hooks for the nimbus-cli to test experiments on device or involving deeplinks.
        if let url = connectionOptions.urlContexts.first?.url {
            Experiments.shared.initializeTooling(url: url)
        }

        routeBuilder.configure(isPrivate: UserDefaults.standard.bool(forKey: PrefsKeys.LastSessionWasPrivate),
                               prefs: profile.prefs)

        let sceneCoordinator = SceneCoordinator(scene: scene)
        self.sceneCoordinator = sceneCoordinator
        sceneCoordinator.start()

        // Before enqueueing deeplink handler in the Event Queue, log a message for the deeplink
        let urls = sentTabsURLs(for: sentTabsUserInfoFromConnectionOptions(connectionOptions))
        if let deeplinkURL = urls.first {
            logEventForExpectedDeeplink(url: deeplinkURL, windowUUID: sceneCoordinator.windowUUID)
            logWillConnectDeeplink(deeplinkURL)
        }

        AppEventQueue.wait(for: [.startupFlowComplete, .tabRestoration(sceneCoordinator.windowUUID)]) { [weak self] in
            self?.logger.log("Event queue: handle deeplink via connectionOptions",
                             level: .debug,
                             category: .deeplinks)
            self?.handle(connectionOptions: connectionOptions)
        }
    }

    private func logWillConnectToSession(options: UIScene.ConnectionOptions) {
        #if MOZ_CHANNEL_FENNEC
        logger.log("Scene Delegate: willConnectTo session. Options: \(options)", level: .debug, category: .deeplinks)
        #else
        logger.log("Scene Delegate: willConnectTo session", level: .debug, category: .deeplinks)
        #endif
    }

    private func logWillConnectDeeplink(_ deeplinkURL: URL) {
        #if MOZ_CHANNEL_FENNEC
        logger.log("Incoming deeplink (willConnectTo). URL: \(deeplinkURL)", level: .debug, category: .deeplinks)
        #else
        logger.log("Incoming deeplink (willConnectTo)", level: .debug, category: .deeplinks)
        #endif
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Handle clean-up here for closing windows on iPad
        guard let sceneCoordinator = (scene.delegate as? SceneDelegate)?.sceneCoordinator else { return }

        // Notify WindowManager that window is closing
        (AppContainer.shared.resolve() as WindowManager).windowWillClose(uuid: sceneCoordinator.windowUUID)
    }

    // MARK: - Transitioning to Foreground

    /// Invoked when the interface is finished loading for your screen, but before that interface appears on screen.
    ///
    /// Use this method to refresh the contents of your scene's view (especially if it's a restored scene),
    /// or other activities that need to begin.
    func sceneDidBecomeActive(_ scene: UIScene) {
        guard !AppConstants.isRunningUnitTest else { return }

        // Resume previously stopped downloads for, and on, THIS scene only.
        downloadQueue.resumeAll()
    }

    // MARK: - Transitioning to Background

    /// The scene's running in the background and not visible on screen.
    ///
    /// Use this method to reduce the scene's memory usage, clear claims to resources & dependencies / services.
    /// UIKit takes a snapshot of the scene for the app switcher after this method returns.
    func sceneDidEnterBackground(_ scene: UIScene) {
        downloadQueue.pauseAll()
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
        guard let url = URLContexts.first?.url,
              let route = routeBuilder.makeRoute(url: url) else { return }

        logger.log("SceneDelegate openURLContexts()", level: .debug, category: .deeplinks)
        logOpenURLContextsDeeplink(URLContexts.first?.url)

        if let coordinator = sceneCoordinator {
            logEventForExpectedDeeplink(url: url, windowUUID: coordinator.windowUUID)
        }
        sceneCoordinator?.findAndHandle(route: route)

        sessionManager.launchSessionProvider.openedFromExternalSource = true
    }

    private func logOpenURLContextsDeeplink(_ url: URL?) {
        guard let url else { return }
        #if MOZ_CHANNEL_FENNEC
        logger.log("Incoming deeplink (openURLContext). URL: \(url)", level: .debug, category: .deeplinks)
        #else
        logger.log("Incoming deeplink (openURLContext)", level: .debug, category: .deeplinks)
        #endif
    }

    // MARK: - Continuing User Activities

    /// Use this method to handle Handoff-related data or other activities.
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        guard let route = routeBuilder.makeRoute(userActivity: userActivity) else { return }
        sceneCoordinator?.findAndHandle(route: route)
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
        guard let route = routeBuilder.makeRoute(shortcutItem: shortcutItem,
                                                 tabSetting: NewTabAccessors.getNewTabPage(profile.prefs))
        else { return }
        sceneCoordinator?.findAndHandle(route: route)
    }

    // MARK: - Misc. Helpers

    private func handle(connectionOptions: UIScene.ConnectionOptions) {
        if let context = connectionOptions.urlContexts.first,
           let route = routeBuilder.makeRoute(url: context.url) {
            sceneCoordinator?.findAndHandle(route: route)
        }

        if let activity = connectionOptions.userActivities.first,
           let route = routeBuilder.makeRoute(userActivity: activity) {
            sceneCoordinator?.findAndHandle(route: route)
        }

        if let shortcut = connectionOptions.shortcutItem,
           let route = routeBuilder.makeRoute(shortcutItem: shortcut,
                                              tabSetting: NewTabAccessors.getNewTabPage(profile.prefs)) {
            sceneCoordinator?.findAndHandle(route: route)
        }

        // Check if our connection options include a user response to a push
        // notification that is for Sent Tabs. If so, route the related tab URLs.
        if let sentTabsUserInfo = sentTabsUserInfoFromConnectionOptions(connectionOptions) {
            handleConnectionOptionsSentTabs(sentTabsUserInfo)
        }
    }

    private func sentTabsUserInfoFromConnectionOptions(_ options: UIScene.ConnectionOptions) -> [[String: Any]]? {
        let sentTabsKey = NotificationSentTabs.sentTabsKey
        if let notification = options.notificationResponse?.notification,
           let userInfo = notification.request.content.userInfo[sentTabsKey] as? [[String: Any]] {
            return userInfo
        }
        return nil
    }

    private func sentTabsURLs(for userInfo: [[String: Any]]?) -> [URL] {
        guard let userInfo else { return [] }
        return userInfo.compactMap {
            guard let urlString = $0["url"] as? String, let url = URL(string: urlString) else { return nil }
            return url
        }
    }

    private func handleConnectionOptionsSentTabs(_ userInfo: [[String: Any]]) {
        // For Sent Tab data structure, see also:
        // NotificationService.displayNewSentTabNotification()
        let urls = sentTabsURLs(for: userInfo)
        urls.forEach {
            guard let route = routeBuilder.makeRoute(url: $0) else { return }
            sceneCoordinator?.findAndHandle(route: route)
        }
    }

    private func logEventForExpectedDeeplink(url: URL, windowUUID: WindowUUID) {
        guard let urlScanner = URLScanner(url: url) else { return }
        let targetURL: URL
        if urlScanner.isOurScheme {
            guard let parsedURL = urlScanner.fullURLQueryItem()?.asURL else { return }
            targetURL = parsedURL
        } else {
            targetURL = url
        }

        let expectedEvent: AppEvent = .selectTab(targetURL, windowUUID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
            guard let self else { return }
            if AppEventQueue.hasSignalled(expectedEvent) {
                logger.log("Deeplink tab check: success.", level: .debug, category: .deeplinks)
            } else {
                // Indicates a Sent Tab or deeplink that failed to open. Log to Sentry. [FXIOS-8374]
                logger.log("Deeplink tab check: failed. Tab not opened for incoming deeplink",
                           level: .fatal,
                           category: .deeplinks)
            }
        }
    }
}
