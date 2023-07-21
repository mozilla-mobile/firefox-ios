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
    var logger: Logger = DefaultLogger.shared

    /// This is a temporary work around until we have the architecture to properly replace the use cases where this code is used
    /// Do not use in new code under any circumstances
    var coordinatorBrowserViewController: BrowserViewController {
        if let browserCoordinator = sceneCoordinator?.childCoordinators.first(where: { $0 as? BrowserCoordinator != nil }) as? BrowserCoordinator {
            return browserCoordinator.browserViewController
        } else {
            logger.log("BrowserViewController couldn't be retrieved", level: .fatal, category: .lifecycle)
            return BrowserViewController(profile: profile, tabManager: tabManager)
        }
    }

    let profile: Profile = AppContainer.shared.resolve()
    let tabManager: TabManager = AppContainer.shared.resolve()
    var sessionManager: AppSessionProvider = AppContainer.shared.resolve()
    var downloadQueue: DownloadQueue = AppContainer.shared.resolve()

    var sceneCoordinator: SceneCoordinator?
    var routeBuilder = RouteBuilder()

    // MARK: - Connecting / Disconnecting Scenes

    /// Invoked when the app creates OR restores an instance of the UI.
    ///
    /// Use this method to respond to the addition of a new scene, and begin loading data that needs to display.
    /// Take advantage of what's given in `options`.
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard !AppConstants.isRunningUnitTest else { return }

        // Add hooks for the nimbus-cli to test experiments on device or involving deeplinks.
        if let url = connectionOptions.urlContexts.first?.url {
            Experiments.shared.initializeTooling(url: url)
        }

        routeBuilder.configure(isPrivate: UserDefaults.standard.bool(forKey: PrefsKeys.LastSessionWasPrivate),
                               prefs: profile.prefs)

        sceneCoordinator = SceneCoordinator(scene: scene)
        sceneCoordinator?.start()

        // Adding a half second delay to ensure start up actions have resolved prior to attempting deeplink actions
        // This is a hacky fix and a long term solution will be add in FXIOS-6828
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.handle(connectionOptions: connectionOptions)
        }
    }

    // MARK: - Transitioning to Foreground

    /// Invoked when the interface is finished loading for your screen, but before that interface appears on screen.
    ///
    /// Use this method to refresh the contents of your scene's view (especially if it's a restored scene), or other activities that need
    /// to begin.
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
    /// This method is equivalent to AppDelegate's openURL method. We implement deep links this way.
    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        guard let url = URLContexts.first?.url,
              let route = routeBuilder.makeRoute(url: url) else { return }
        sceneCoordinator?.findAndHandle(route: route)

        sessionManager.launchSessionProvider.openedFromExternalSource = true
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
    }
}
