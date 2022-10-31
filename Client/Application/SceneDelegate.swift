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

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// This is temporary. We don't want to continue treating App / Scene delegates as containers for certain session specific properties.
    /// TODO: When we begin to support multiple scenes, this is risky to keep. If we foregroundBVC, we should have a more specific
    /// way to foreground the BVC FOR the scene being actively interacted with.
    var browserViewController: BrowserViewController!

    let profile: Profile = AppContainer.shared.resolve()
    let tabManager: TabManager = AppContainer.shared.resolve()

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

        let window = configureWindowFor(scene)
        let rootVC = configureRootViewController()

        window.rootViewController = rootVC
        window.makeKeyAndVisible()

        self.window = window

        handleDeeplinkOrShortcutsAtLaunch(with: connectionOptions, on: scene)
    }

    /// Invoked as the scene is being released by the system. A scene is released when its backgrounded or when its session is discarded.
    /// The scene can reconnect later if it's session wasn't discarded.
    ///
    /// Use this method to do any final clean up before the scene is purged from memory. Release resources and shutdown things gracefully.
    /// Note: Removal of a scene occurs before it's discarded.
    func sceneDidDisconnect(_ scene: UIScene) {
        // no-op
    }

    // MARK: - Transitioning to Foreground

    /// Invoked before a scene enters the foreground and becomes visible to the user.
    ///
    /// Use this method to undo changes made on the scene entering the background.
    func sceneWillEnterForeground(_ scene: UIScene) {
        // no-op
    }

    /// Invoked when the interface is finished loading for your screen, but before that interface appears on screen.
    ///
    /// Use this method to refresh the contents of your scene's view (especially if it's a restored scene), or other activities that need
    /// to begin.
    func sceneDidBecomeActive(_ scene: UIScene) {
        guard !AppConstants.isRunningUnitTest else { return }

        /// Resume previously stopped downloads for, and on, THIS scene only.
        browserViewController.downloadQueue.resumeAll()
    }

    // MARK: - Transitioning to Background

    /// Invoked before transitioning the app to the background, OR for temporary interruptions like system alerts.
    ///
    /// Use this method to prepare to be backgrounded cleanly. Any data that needs to persist can be done in here AS A LAST RESORT.
    /// In general, data management should be done outside of this method.
    func sceneWillResignActive(_ scene: UIScene) {
        // no-op
    }

    /// The scene's running in the background and not visible on screen.
    ///
    /// Use this method to reduce the scene's memory usage, clear claims to resources & dependencies / services.
    /// UIKit takes a snapshot of the scene for the app switcher after this method returns.
    func sceneDidEnterBackground(_ scene: UIScene) {
        browserViewController.downloadQueue.pauseAll()
    }

    // MARK: - Opening URLs

    /// Asks the delegate to open one or more URLs.
    ///
    /// This method is equialent to AppDelegate's openURL method. We implement deeplinks this way.
    func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) {
        guard let url = URLContexts.first?.url,
              let routerPath = NavigationPath(url: url) else { return }

        if profile.prefs.boolForKey(PrefsKeys.AppExtensionTelemetryOpenUrl) != nil {
            profile.prefs.removeObjectForKey(PrefsKeys.AppExtensionTelemetryOpenUrl)

            var object = TelemetryWrapper.EventObject.url
            if case .text = routerPath {
                object = .searchText
            }

            TelemetryWrapper.recordEvent(category: .appExtensionAction, method: .applicationOpenUrl, object: object)
        }

        DispatchQueue.main.async {
            NavigationPath.handle(nav: routerPath, with: self.browserViewController)
        }

    }

    // MARK: - Continuing User Activities

    /// Tells the delegate it's about to recieve Handoff-related data.
    func scene(
        _ scene: UIScene,
        willContinueUserActivityWithType userActivityType: String
    ) {
        // no-op
    }

    /// Use this method to handle Handoff-related data or other activities.
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if userActivity.activityType == SiriShortcuts.activityType.openURL.rawValue {
            browserViewController.openBlankNewTab(focusLocationField: false)
        }

        // If the `NSUserActivity` has a `webpageURL`, it is either a deep link or an old history item
        // reached via a "Spotlight" search before we began indexing visited pages via CoreSpotlight.
        if let url = userActivity.webpageURL {
            let query = url.getQuery()

            // Check for fxa sign-in code and launch the login screen directly
            if query["signin"] != nil {
                // bvc.launchFxAFromDeeplinkURL(url) // Was using Adjust. Consider hooking up again when replacement system in-place.
            }

            // Per Adjust documentation, https://docs.adjust.com/en/universal-links/#running-campaigns-through-universal-links,
            // it is recommended that links contain the `deep_link` query parameter. This link will also
            // be url encoded.
            if let deepLink = query["deep_link"]?.removingPercentEncoding, let url = URL(string: deepLink) {
                browserViewController.switchToTabForURLOrOpen(url)
            }

            browserViewController.switchToTabForURLOrOpen(url)
        }

        // Otherwise, check if the `NSUserActivity` is a CoreSpotlight item and switch to its tab or
        // open a new one.
        if userActivity.activityType == CSSearchableItemActionType {
            if let userInfo = userActivity.userInfo,
                let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String,
                let url = URL(string: urlString) {
                browserViewController.switchToTabForURLOrOpen(url)
            }
        }

    }

    /// Use this method to notify the user that the specified activity couldn't be completed.
    ///
    /// We need to think about the right ways to notifiy users
    func scene(
        _ scene: UIScene,
        didFailToContinueUserActivityWithType userActivityType: String, error: Error
    ) {
        // no-op
    }

    // MARK: - Responding to Scene (environment) Changes

    /// Use this method to handle certain environment changes and adjust your scene accordingly.
    ///
    /// See how / what needs to be done here so that we can lock orientation on modal presentation as well.
    func windowScene(
        _ windowScene: UIWindowScene,
        didUpdate previousCoordinateSpace: UICoordinateSpace,
        interfaceOrientation previousInterfaceOrientation: UIInterfaceOrientation,
        traitCollection previousTraitCollection: UITraitCollection
    ) {
        // no-op
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
        QuickActionsImplementation().handleShortCutItem(
            shortcutItem,
            withBrowserViewController: browserViewController,
            completionHandler: completionHandler
        )
    }

    // MARK: - Misc. Helpers

    private func configureWindowFor(_ scene: UIScene) -> UIWindow {
        guard let windowScene = (scene as? UIWindowScene) else {
            return UIWindow(frame: UIScreen.main.bounds)
        }

        let window = UIWindow(windowScene: windowScene)

        if !LegacyThemeManager.instance.systemThemeIsOn {
            window.overrideUserInterfaceStyle = LegacyThemeManager.instance.userInterfaceStyle
        }

        return window
    }

    private func configureRootViewController() -> UINavigationController {
        let browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)

        // TODO: When we begin to support multiple scenes, remove this line and the reference to BVC in SceneDelegate.
        self.browserViewController = browserViewController

        let navigationController = UINavigationController(rootViewController: browserViewController)
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)

        return navigationController
    }

    /// Handling either deeplinks or shortcuts at launch is slightly different than when the scene has been backgrounded.
    private func handleDeeplinkOrShortcutsAtLaunch(
        with connectionOptions: UIScene.ConnectionOptions,
        on scene: UIScene
    ) {
        /// Handling deeplinks at launch can be handled this way.
        if !connectionOptions.urlContexts.isEmpty {
            self.scene(scene, openURLContexts: connectionOptions.urlContexts)
        }

        /// At launch, shortcut items can be handled this way.
        if let shortcutItem = connectionOptions.shortcutItem {
            QuickActionsImplementation().handleShortCutItem(
                shortcutItem,
                withBrowserViewController: browserViewController,
                completionHandler: { _ in }
            )
        }
    }

}
