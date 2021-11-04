/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Shared
import Storage
import CoreSpotlight
import WebKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var profile: Profile?
    var browserViewController: BrowserViewController!
    var tabManager: TabManager!
    var isForeground: Bool = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let windowScene = scene as? UIWindowScene {
            windowScene.screenshotService?.delegate = self
            let window = UIWindow(windowScene: windowScene)
            let userActivity = connectionOptions.userActivities.first ?? session.stateRestorationActivity
            configure(window: window, with: userActivity)
            self.window = window
            window.makeKeyAndVisible()
        }
    }

    func configure(window: UIWindow, with activity: NSUserActivity?) {
        setupRootViewController(in: window)
        if let url = activity?.webpageURL {
            browserViewController.openURLInNewTab(url)
        }
    }

    private func setupRootViewController(in window: UIWindow) {
        NotificationCenter.default.addObserver(forName: .DisplayThemeChanged, object: nil, queue: .main) { (notification) -> Void in
            if !LegacyThemeManager.instance.systemThemeIsOn {
                self.window?.overrideUserInterfaceStyle = LegacyThemeManager.instance.userInterfaceStyle
            } else {
                self.window?.overrideUserInterfaceStyle = .unspecified
            }
        }

        if !LegacyThemeManager.instance.systemThemeIsOn {
            window.overrideUserInterfaceStyle = LegacyThemeManager.instance.userInterfaceStyle
        }

        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        profile = appDelegate.profile!
        // TODO: Use a per scene TabManager(?)
        let imageStore = DiskImageStore(files: profile!.files, namespace: "TabManagerScreenshots", quality: UIConstants.ScreenshotQuality)
        tabManager = TabManager(profile: appDelegate.profile!, imageStore: imageStore)
        appDelegate.tabManager = tabManager

        browserViewController = BrowserViewController(profile: profile!, tabManager: tabManager!)
        browserViewController.edgesForExtendedLayout = []

        let navigationController = UINavigationController(rootViewController: browserViewController)
        navigationController.delegate = appDelegate
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = []

        window.rootViewController = navigationController
        browserViewController.updateState = .coldStart
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        isForeground = true

        browserViewController.firefoxHomeViewController?.reloadAll()

        // Resume file downloads.
        browserViewController.downloadQueue.resumeAll()

        _ = profile?.logins.reopenIfClosed()
        _ = profile?.places.reopenIfClosed()

        // Delay these operations until after UIKit/UIApp init is complete
        // - loadQueuedTabs accesses the DB and shows up as a hot path in profiling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // We could load these here, but then we have to futz with the tab counter
            // and making NSURLRequests.
            let receivedURLs = (UIApplication.shared.delegate as! AppDelegate).receivedURLs
            self.browserViewController.loadQueuedTabs(receivedURLs: receivedURLs)
            (UIApplication.shared.delegate as! AppDelegate).receivedURLs.removeAll()
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        tabManager.preserveTabs()
        isForeground = false
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        if userActivity.activityType == SiriShortcuts.activityType.openURL.rawValue {
            browserViewController.openBlankNewTab(focusLocationField: false)
            return
        }

        // If the `NSUserActivity` has a `webpageURL`, it is either a deep link or an old history item
        // reached via a "Spotlight" search before we began indexing visited pages via CoreSpotlight.
        if let url = userActivity.webpageURL {
            let query = url.getQuery()

            // Check for fxa sign-in code and launch the login screen directly
            if query["signin"] != nil {
                // bvc.launchFxAFromDeeplinkURL(url) // Was using Adjust. Consider hooking up again when replacement system in-place.
                return
            }

            // Per Adjust documenation, https://docs.adjust.com/en/universal-links/#running-campaigns-through-universal-links,
            // it is recommended that links contain the `deep_link` query parameter. This link will also
            // be url encoded.
            if let deepLink = query["deep_link"]?.removingPercentEncoding, let url = URL(string: deepLink) {
                browserViewController.switchToTabForURLOrOpen(url)
                return
            }

            browserViewController.switchToTabForURLOrOpen(url)
            return
        }

        // Otherwise, check if the `NSUserActivity` is a CoreSpotlight item and switch to its tab or
        // open a new one.
        if userActivity.activityType == CSSearchableItemActionType {
            if let userInfo = userActivity.userInfo,
                let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String,
                let url = URL(string: urlString) {
                browserViewController.switchToTabForURLOrOpen(url)
                return
            }
        }

        return
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url,
              let routerpath = NavigationPath(url: url) else {
            return
        }

        if let profile = (UIApplication.shared.delegate as? AppDelegate)?.profile,
           let _ = profile.prefs.boolForKey(PrefsKeys.AppExtensionTelemetryOpenUrl) {
            profile.prefs.removeObjectForKey(PrefsKeys.AppExtensionTelemetryOpenUrl)
            var object = TelemetryWrapper.EventObject.url
            if case .text(_) = routerpath {
                object = .searchText
            }
            TelemetryWrapper.recordEvent(category: .appExtensionAction, method: .applicationOpenUrl, object: object)
        }

        DispatchQueue.main.async {
            NavigationPath.handle(nav: routerpath, with: self.browserViewController)
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        browserViewController.firefoxHomeViewController?.reloadAll()
        browserViewController.downloadQueue.resumeAll()
        browserViewController.updateViewConstraints()
    }
}

extension SceneDelegate: UIScreenshotServiceDelegate {
    func screenshotService(_ screenshotService: UIScreenshotService, generatePDFRepresentationWithCompletion completionHandler: @escaping (Data?, Int, CGRect) -> Void) {
        guard let webView = browserViewController.tabManager.selectedTab?.currentWebView() else {
            completionHandler(nil, 0, .zero)
            return
        }

        var rect = webView.scrollView.frame
        rect.origin.x = webView.scrollView.contentOffset.x
        rect.origin.y = webView.scrollView.contentSize.height - rect.height - webView.scrollView.contentOffset.y

        webView.createPDF { result in
            switch result {
            case .success(let data):
                completionHandler(data, 0, rect)
            case .failure(_):
                completionHandler(nil, 0, .zero)
            }
        }
    }
}
