// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import Storage
import CoreSpotlight
import SDWebImage

let LatestAppVersionProfileKey = "latestAppVersion"

class AppDelegate: UIResponder, UIApplicationDelegate {

    // This is the easiest way to force a bootstrap that's guaranteed to happen on app launch
    private var appContainer: ServiceProvider = AppContainer.shared
    var window: UIWindow?
    var tabManager: TabManager!
    var receivedURLs = [URL]()
    var orientationLock = UIInterfaceOrientationMask.all
    lazy var themeManager: ThemeManager = DefaultThemeManager(appDelegate: self)
    lazy var profile: Profile = BrowserProfile(localName: "profile",
                                               syncDelegate: UIApplication.shared.syncDelegate)
    private let log = Logger.browserLogger
    private var shutdownWebServer: DispatchSourceTimer?
    private var webServerUtil: WebServerUtil?
    private var appLaunchUtil: AppLaunchUtil?
    private var backgroundSyncUtil: BackgroundSyncUtil?
    private var widgetManager: TopSitesWidgetManager?
    private var menuBuilderHelper: MenuBuilderHelper?

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        log.info("startApplication begin")

        appLaunchUtil = AppLaunchUtil(profile: profile)
        appLaunchUtil?.setUpPreLaunchDependencies()

        // Set up a web server that serves us static content. Do this early so that it is ready when the UI is presented.
        webServerUtil = WebServerUtil(profile: profile)
        webServerUtil?.setUpWebServer()

        menuBuilderHelper = MenuBuilderHelper()

        log.info("startApplication end")

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // We have only five seconds here, so let's hope this doesn't take too long.
        profile.shutdown()

        // Allow deinitializers to close our database connections.
        tabManager = nil
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        pushNotificationSetup()
        appLaunchUtil?.setUpPostLaunchDependencies()
        backgroundSyncUtil = BackgroundSyncUtil(profile: profile, application: application)

        // Widgets are available on iOS 14 and up only.
        if #available(iOS 14.0, *) {
            let topSitesProvider = TopSitesProviderImplementation(browserHistoryFetcher: profile.history,
                                                                  prefs: profile.prefs)

            widgetManager = TopSitesWidgetManager(topSitesProvider: topSitesProvider)
        }

        return true
    }

    // We sync in the foreground only, to avoid the possibility of runaway resource usage.
    // Eventually we'll sync in response to notifications.
    func applicationDidBecomeActive(_ application: UIApplication) {
        shutdownWebServer?.cancel()
        shutdownWebServer = nil

        profile.reopen()

        if profile.prefs.boolForKey(PendingAccountDisconnectedKey) ?? false {
            profile.removeAccount()
        }

        profile.syncManager.applicationDidBecomeActive()
        webServerUtil?.setUpWebServer()

        /// When transitioning to scenes, each scene's BVC needs to resume its file download queue.
        for session in application.openSessions {
            (session.scene?.delegate as? SceneDelegate)?.browserViewController.downloadQueue.resumeAll()
        }

        TelemetryWrapper.recordEvent(category: .action, method: .foreground, object: .app)

        // Create fx favicon cache directory
        FaviconFetcher.createWebImageCacheDirectory()
        // update top sites widget
        updateTopSitesWidget()

        // Cleanup can be a heavy operation, take it out of the startup path. Instead check after a few seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.profile.cleanupHistoryIfNeeded()
            BrowserViewController.foregroundBVC().ratingPromptManager.updateData()
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        updateTopSitesWidget()
        UserDefaults.standard.setValue(Date(), forKey: "LastActiveTimestamp")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Pause file downloads.
        for session in application.openSessions {
            (session.scene?.delegate as? SceneDelegate)?.browserViewController.downloadQueue.pauseAll()
        }

        TelemetryWrapper.recordEvent(category: .action, method: .background, object: .app)
        TabsQuantityTelemetry.trackTabsQuantity(tabManager: tabManager)

        let singleShotTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        // 2 seconds is ample for a localhost request to be completed by GCDWebServer. <500ms is expected on newer devices.
        singleShotTimer.schedule(deadline: .now() + 2.0, repeating: .never)
        singleShotTimer.setEventHandler {
            WebServer.sharedInstance.server.stop()
            self.shutdownWebServer = nil
        }
        singleShotTimer.resume()
        shutdownWebServer = singleShotTimer
        backgroundSyncUtil?.scheduleSyncOnAppBackground()
        tabManager.preserveTabs()

        // send glean telemetry and clear cache
        // we do this to remove any disk cache
        // that the app might have built over the
        // time which is taking up un-necessary space
        SDImageCache.shared.clearDiskCache { _ in }
    }

    private func updateTopSitesWidget() {
        // Since we only need the topSites data in the archiver, let's write it
        // only if iOS 14 is available.
        if #available(iOS 14.0, *) {
            widgetManager?.writeWidgetKitTopSites()
        }
    }
}

// This functionality will need to be moved to the SceneDelegate when the time comes
extension AppDelegate {

    // Orientation lock for views that use new modal presenter
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }
}

extension AppDelegate {
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}

// MARK: - Key Commands

extension AppDelegate {
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        guard builder.system == .main else { return }

        menuBuilderHelper?.mainMenu(for: builder)
    }
}
