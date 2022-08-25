// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared
import Storage
import CoreSpotlight
import SDWebImage

let LatestAppVersionProfileKey = "latestAppVersion"

class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var browserViewController: BrowserViewController!
    var rootViewController: UIViewController!
    var tabManager: TabManager!
    var receivedURLs = [URL]()
    var orientationLock = UIInterfaceOrientationMask.all
    lazy var profile: Profile = BrowserProfile(localName: "profile",
                                               syncDelegate: UIApplication.shared.syncDelegate)
    private let log = Logger.browserLogger
    private var shutdownWebServer: DispatchSourceTimer?
    private var webServerUtil: WebServerUtil?
    private var appLaunchUtil: AppLaunchUtil?
    private var backgroundSyncUtil: BackgroundSyncUtil?
    private var widgetManager: TopSitesWidgetManager?

    func application(_ application: UIApplication,
                     willFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        log.info("startApplication begin")

        self.window = UIWindow(frame: UIScreen.main.bounds)

        appLaunchUtil = AppLaunchUtil(profile: profile)
        appLaunchUtil?.setUpPreLaunchDependencies()

        // Set up a web server that serves us static content. Do this early so that it is ready when the UI is presented.
        webServerUtil = WebServerUtil(profile: profile)
        webServerUtil?.setUpWebServer()

        let imageStore = DiskImageStore(files: profile.files, namespace: "TabManagerScreenshots", quality: UIConstants.ScreenshotQuality)
        self.tabManager = TabManager(profile: profile, imageStore: imageStore)

        setupRootViewController()
        startListeningForThemeUpdates()

        log.info("startApplication end")

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // We have only five seconds here, so let's hope this doesn't take too long.
        profile._shutdown()

        // Allow deinitializers to close our database connections.
        tabManager = nil
        browserViewController = nil
        rootViewController = nil
    }

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions
                     launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window!.makeKeyAndVisible()
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

        profile._reopen()

        if profile.prefs.boolForKey(PendingAccountDisconnectedKey) ?? false {
            profile.removeAccount()
        }

        profile.syncManager.applicationDidBecomeActive()
        webServerUtil?.setUpWebServer()

        /// When transitioning to scenes, each scene's BVC needs to resume its file download queue.
        browserViewController.downloadQueue.resumeAll()

        TelemetryWrapper.recordEvent(category: .action, method: .foreground, object: .app)

        // Delay these operations until after UIKit/UIApp init is complete
        // - loadQueuedTabs accesses the DB and shows up as a hot path in profiling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // We could load these here, but then we have to futz with the tab counter
            // and making NSURLRequests.
            self.browserViewController.loadQueuedTabs(receivedURLs: self.receivedURLs)
            self.receivedURLs.removeAll()
            application.applicationIconBadgeNumber = 0
        }
        // Create fx favicon cache directory
        FaviconFetcher.createWebImageCacheDirectory()
        // update top sites widget
        updateTopSitesWidget()

        // Cleanup can be a heavy operation, take it out of the startup path. Instead check after a few seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.profile.cleanupHistoryIfNeeded()
            self.browserViewController.ratingPromptManager.updateData()
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        updateTopSitesWidget()
        UserDefaults.standard.setValue(Date(), forKey: "LastActiveTimestamp")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Pause file downloads.
        // TODO: iOS 13 needs to iterate all the BVCs.
        browserViewController.downloadQueue.pauseAll()

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

    /// When a user presses and holds the app icon from the Home Screen, we present quick actions / shortcut items (see QuickActions).
    ///
    /// This method can handle a quick action from both app launch and when the app becomes active. However, the system calls launch methods first if the app `launches`
    /// and gives you a chance to handle the shortcut there. If it's not handled there, this method is called in the activation process with the shortcut item.
    ///
    /// Quick actions / shortcut items are handled here as long as our two launch methods return `true`. If either of them return `false`, this method
    /// won't be called to handle shortcut items.
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortCutItem = QuickActions.sharedInstance.handleShortCutItem(shortcutItem, withBrowserViewController: browserViewController)

        completionHandler(handledShortCutItem)
    }
}

// This functionality will need to be moved to the SceneDelegate when the time comes
extension AppDelegate {

    func startListeningForThemeUpdates() {
        NotificationCenter.default.addObserver(forName: .DisplayThemeChanged, object: nil, queue: .main) { (_) -> Void in
            if !LegacyThemeManager.instance.systemThemeIsOn {
                self.window?.overrideUserInterfaceStyle = LegacyThemeManager.instance.userInterfaceStyle
            } else {
                self.window?.overrideUserInterfaceStyle = .unspecified
            }
        }
    }

    // Orientation lock for views that use new modal presenter
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return self.orientationLock
    }

    func application(_ application: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if userActivity.activityType == SiriShortcuts.activityType.openURL.rawValue {
            browserViewController.openBlankNewTab(focusLocationField: false)
            return true
        }

        // If the `NSUserActivity` has a `webpageURL`, it is either a deep link or an old history item
        // reached via a "Spotlight" search before we began indexing visited pages via CoreSpotlight.
        if let url = userActivity.webpageURL {
            let query = url.getQuery()

            // Check for fxa sign-in code and launch the login screen directly
            if query["signin"] != nil {
                // bvc.launchFxAFromDeeplinkURL(url) // Was using Adjust. Consider hooking up again when replacement system in-place.
                return true
            }

            // Per Adjust documentation, https://docs.adjust.com/en/universal-links/#running-campaigns-through-universal-links,
            // it is recommended that links contain the `deep_link` query parameter. This link will also
            // be url encoded.
            if let deepLink = query["deep_link"]?.removingPercentEncoding, let url = URL(string: deepLink) {
                browserViewController.switchToTabForURLOrOpen(url)
                return true
            }

            browserViewController.switchToTabForURLOrOpen(url)
            return true
        }

        // Otherwise, check if the `NSUserActivity` is a CoreSpotlight item and switch to its tab or
        // open a new one.
        if userActivity.activityType == CSSearchableItemActionType {
            if let userInfo = userActivity.userInfo,
                let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String,
                let url = URL(string: urlString) {
                browserViewController.switchToTabForURLOrOpen(url)
                return true
            }
        }

        return false
    }

    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let routerpath = NavigationPath(url: url) else { return false }

        if let _ = profile.prefs.boolForKey(PrefsKeys.AppExtensionTelemetryOpenUrl) {
            profile.prefs.removeObjectForKey(PrefsKeys.AppExtensionTelemetryOpenUrl)
            var object = TelemetryWrapper.EventObject.url
            if case .text = routerpath {
                object = .searchText
            }
            TelemetryWrapper.recordEvent(category: .appExtensionAction, method: .applicationOpenUrl, object: object)
        }

        DispatchQueue.main.async {
            NavigationPath.handle(nav: routerpath, with: self.browserViewController)
        }
        return true
    }

    private func setupRootViewController() {
        if !LegacyThemeManager.instance.systemThemeIsOn {
            window?.overrideUserInterfaceStyle = LegacyThemeManager.instance.userInterfaceStyle
        }

        browserViewController = BrowserViewController(profile: profile, tabManager: tabManager)
        browserViewController.edgesForExtendedLayout = []

        let navigationController = UINavigationController(rootViewController: browserViewController)
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        rootViewController = navigationController

        window!.rootViewController = rootViewController
    }
}

// MARK: - Key Commands

extension AppDelegate {
    override func buildMenu(with builder: UIMenuBuilder) {
        super.buildMenu(with: builder)

        guard builder.system == .main else { return }
        let newPrivateTab = UICommandAlternate(title: .KeyboardShortcuts.NewPrivateTab, action: #selector(BrowserViewController.newPrivateTabKeyCommand), modifierFlags: [.shift])

        let applicationMenu = UIMenu(options: .displayInline, children: [
            UIKeyCommand(title: .AppSettingsTitle, action: #selector(BrowserViewController.openSettingsKeyCommand), input: ",", modifierFlags: .command, discoverabilityTitle: .AppSettingsTitle)
        ])

        let fileMenu = UIMenu(options: .displayInline, children: [
            UIKeyCommand(title: .KeyboardShortcuts.NewTab, action: #selector(BrowserViewController.newTabKeyCommand), input: "t", modifierFlags: .command, alternates: [newPrivateTab], discoverabilityTitle: .KeyboardShortcuts.NewTab),
            UIKeyCommand(title: .KeyboardShortcuts.NewPrivateTab, action: #selector(BrowserViewController.newPrivateTabKeyCommand), input: "p", modifierFlags: [.command, .shift], discoverabilityTitle: .KeyboardShortcuts.NewPrivateTab),
            UIKeyCommand(title: .KeyboardShortcuts.SelectLocationBar, action: #selector(BrowserViewController.selectLocationBarKeyCommand), input: "l", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.SelectLocationBar),
            UIKeyCommand(title: .KeyboardShortcuts.CloseCurrentTab, action: #selector(BrowserViewController.closeTabKeyCommand), input: "w", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.CloseCurrentTab),
        ])

        if #available(iOS 15, *) {
            fileMenu.children.forEach {
                ($0 as! UIKeyCommand).wantsPriorityOverSystemBehavior = true
            }
        }

        let editMenu = UIMenu(options: .displayInline, children: [
            UIKeyCommand(title: .KeyboardShortcuts.Find, action: #selector(BrowserViewController.findInPageKeyCommand), input: "f", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.Find),
            UIKeyCommand(title: .KeyboardShortcuts.FindAgain, action: #selector(BrowserViewController.findInPageAgainKeyCommand), input: "g", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.FindAgain),
        ])

        let viewMenu = UIMenu(options: .displayInline, children: [
            UIKeyCommand(title: .KeyboardShortcuts.ZoomIn, action: #selector(BrowserViewController.zoomIn), input: "+", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.ZoomIn),
            UIKeyCommand(title: .KeyboardShortcuts.ZoomOut, action: #selector(BrowserViewController.zoomOut), input: "-", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.ZoomOut),
            UIKeyCommand(title: .KeyboardShortcuts.ActualSize, action: #selector(BrowserViewController.resetZoom), input: "0", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.ActualSize),
            UIKeyCommand(title: .KeyboardShortcuts.ReloadPage, action: #selector(BrowserViewController.reloadTabKeyCommand), input: "r", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.ReloadPage)
        ])

        if #available(iOS 15, *) {
            viewMenu.children.forEach {
                ($0 as! UIKeyCommand).wantsPriorityOverSystemBehavior = true
            }
        }

        let historyMenu = UIMenu(title: .KeyboardShortcuts.Sections.History, identifier: UIMenu.Identifier("com.mozilla.firefox.menus.history"), options: .displayInline, children: [
            UIKeyCommand(title: .KeyboardShortcuts.ShowHistory, action: #selector(BrowserViewController.showHistoryKeyCommand), input: "y", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.ShowHistory),
            UIKeyCommand(title: .KeyboardShortcuts.Back, action: #selector(BrowserViewController.goBackKeyCommand), input: "[", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.Back),
            UIKeyCommand(title: .KeyboardShortcuts.Forward, action: #selector(BrowserViewController.goForwardKeyCommand), input: "]", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.Forward),
            UIKeyCommand(title: .KeyboardShortcuts.ClearRecentHistory, action: #selector(BrowserViewController.openClearHistoryPanelKeyCommand), input: "\u{8}", modifierFlags: [.command, .shift], discoverabilityTitle: .KeyboardShortcuts.ClearRecentHistory)
        ])

        let bookmarksMenu = UIMenu(title: .KeyboardShortcuts.Sections.Bookmarks, identifier: UIMenu.Identifier("com.mozilla.firefox.menus.bookmarks"), options: .displayInline, children: [
            UIKeyCommand(title: .KeyboardShortcuts.ShowBookmarks, action: #selector(BrowserViewController.showBookmarksKeyCommand), input: "o", modifierFlags: [.command, .shift], discoverabilityTitle: .KeyboardShortcuts.ShowBookmarks),
            UIKeyCommand(title: .KeyboardShortcuts.AddBookmark, action: #selector(BrowserViewController.addBookmarkKeyCommand), input: "d", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.AddBookmark)
        ])

        let toolsMenu = UIMenu(title: .KeyboardShortcuts.Sections.Tools, identifier: UIMenu.Identifier("com.mozilla.firefox.menus.tools"), options: .displayInline, children: [
            UIKeyCommand(title: .KeyboardShortcuts.ShowDownloads, action: #selector(BrowserViewController.showDownloadsKeyCommand), input: "j", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.ShowDownloads),
            UIKeyCommand(action: #selector(BrowserViewController.selectFirstTab), input: "1", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.ShowFirstTab),
            UIKeyCommand(action: #selector(BrowserViewController.selectLastTab), input: "9", modifierFlags: .command, discoverabilityTitle: .KeyboardShortcuts.ShowLastTab),
        ])

        let windowMenu = UIMenu(title: .KeyboardShortcuts.Sections.Window, options: .displayInline, children: [
            UIKeyCommand(title: .KeyboardShortcuts.ShowNextTab, action: #selector(BrowserViewController.nextTabKeyCommand), input: "\t", modifierFlags: [.control], discoverabilityTitle: .KeyboardShortcuts.ShowNextTab),
            UIKeyCommand(title: .KeyboardShortcuts.ShowPreviousTab, action: #selector(BrowserViewController.previousTabKeyCommand), input: "\t", modifierFlags: [.control, .shift], discoverabilityTitle: .KeyboardShortcuts.ShowPreviousTab),
            UIKeyCommand(title: .KeyboardShortcuts.ShowTabTray, action: #selector(BrowserViewController.showTabTrayKeyCommand), input: "\t", modifierFlags: [.command, .alternate], discoverabilityTitle: .KeyboardShortcuts.ShowTabTray),
        ])

        if #available(iOS 15, *) {
            windowMenu.children.forEach {
                ($0 as! UIKeyCommand).wantsPriorityOverSystemBehavior = true
            }
        }

        builder.insertChild(applicationMenu, atStartOfMenu: .application)
        builder.insertChild(fileMenu, atStartOfMenu: .file)
        builder.insertChild(editMenu, atStartOfMenu: .edit)
        builder.insertChild(viewMenu, atStartOfMenu: .view)
        builder.insertSibling(historyMenu, afterMenu: .view)
        builder.insertSibling(bookmarksMenu, afterMenu: UIMenu.Identifier("com.mozilla.firefox.menus.history"))
        builder.insertSibling(toolsMenu, afterMenu: UIMenu.Identifier("com.mozilla.firefox.menus.bookmarks"))
        builder.insertChild(windowMenu, atStartOfMenu: .window)
    }
}
