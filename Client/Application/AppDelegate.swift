/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import AVFoundation
import XCGLogger
import MessageUI
import SDWebImage
import SwiftKeychainWrapper
import LocalAuthentication
import SyncTelemetry
import Sync
import CoreSpotlight
import UserNotifications

#if canImport(BackgroundTasks)
 import BackgroundTasks
#endif


private let log = Logger.browserLogger

let LatestAppVersionProfileKey = "latestAppVersion"
let AllowThirdPartyKeyboardsKey = "settings.allowThirdPartyKeyboards"
private let InitialPingSentKey = "initialPingSent"

class AppDelegate: UIResponder, UIApplicationDelegate, UIViewControllerRestoration {
    public static func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        return nil
    }

    var window: UIWindow?
    var browserViewController: BrowserViewController!
    var rootViewController: UIViewController!
    weak var profile: Profile?
    var tabManager: TabManager!
    var adjustIntegration: AdjustIntegration?
    var applicationCleanlyBackgrounded = true
    var shutdownWebServer: DispatchSourceTimer?

    weak var application: UIApplication?
    var launchOptions: [AnyHashable: Any]?

    var receivedURLs = [URL]()
    var unifiedTelemetry: UnifiedTelemetry?

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        //
        // Determine if the application cleanly exited last time it was used. We default to true in
        // case we have never done this before. Then check if the "ApplicationCleanlyBackgrounded" user
        // default exists and whether was properly set to true on app exit.
        //
        // Then we always set the user default to false. It will be set to true when we the application
        // is backgrounded.
        //

        self.applicationCleanlyBackgrounded = true

        let defaults = UserDefaults()
        if defaults.object(forKey: "ApplicationCleanlyBackgrounded") != nil {
            self.applicationCleanlyBackgrounded = defaults.bool(forKey: "ApplicationCleanlyBackgrounded")
        }
        defaults.set(false, forKey: "ApplicationCleanlyBackgrounded")

        // Hold references to willFinishLaunching parameters for delayed app launch
        self.application = application
        self.launchOptions = launchOptions

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = UIColor.theme.browser.background

        // If the 'Save logs to Files app on next launch' toggle
        // is turned on in the Settings app, copy over old logs.
        if DebugSettingsBundleOptions.saveLogsToDocuments {
            Logger.copyPreviousLogsToDocuments()
        }

        return startApplication(application, withLaunchOptions: launchOptions)
    }

    func startApplication(_ application: UIApplication, withLaunchOptions launchOptions: [AnyHashable: Any]?) -> Bool {
        log.info("startApplication begin")

        // Need to get "settings.sendUsageData" this way so that Sentry can be initialized
        // before getting the Profile.
        let sendUsageData = NSUserDefaultsPrefs(prefix: "profile").boolForKey(AppConstants.PrefSendUsageData) ?? true
        Sentry.shared.setup(sendUsageData: sendUsageData)

        // Set the Firefox UA for browsing.
        setUserAgent()

        // Start the keyboard helper to monitor and cache keyboard state.
        KeyboardHelper.defaultHelper.startObserving()

        DynamicFontHelper.defaultHelper.startObserving()

        MenuHelper.defaultHelper.setItems()

        let logDate = Date()
        // Create a new sync log file on cold app launch. Note that this doesn't roll old logs.
        Logger.syncLogger.newLogWithDate(logDate)

        Logger.browserLogger.newLogWithDate(logDate)

        let profile = getProfile(application)

        unifiedTelemetry = UnifiedTelemetry(profile: profile)

        // Set up a web server that serves us static content. Do this early so that it is ready when the UI is presented.
        setUpWebServer(profile)

        let imageStore = DiskImageStore(files: profile.files, namespace: "TabManagerScreenshots", quality: UIConstants.ScreenshotQuality)

        // Temporary fix for Bug 1390871 - NSInvalidArgumentException: -[WKContentView menuHelperFindInPage]: unrecognized selector
        if let clazz = NSClassFromString("WKCont" + "ent" + "View"), let swizzledMethod = class_getInstanceMethod(TabWebViewMenuHelper.self, #selector(TabWebViewMenuHelper.swizzledMenuHelperFindInPage)) {
            class_addMethod(clazz, MenuHelper.SelectorFindInPage, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
        }

        self.tabManager = TabManager(profile: profile, imageStore: imageStore)

        // Add restoration class, the factory that will return the ViewController we
        // will restore with.

        setupRootViewController()

        NotificationCenter.default.addObserver(forName: .FSReadingListAddReadingListItem, object: nil, queue: nil) { (notification) -> Void in
            if let userInfo = notification.userInfo, let url = userInfo["URL"] as? URL {
                let title = (userInfo["Title"] as? String) ?? ""
                profile.readingList.createRecordWithURL(url.absoluteString, title: title, addedBy: UIDevice.current.name)
            }
        }

        NotificationCenter.default.addObserver(forName: .FirefoxAccountDeviceRegistrationUpdated, object: nil, queue: nil) { _ in
            profile.flushAccount()
        }

        adjustIntegration = AdjustIntegration(profile: profile)

        self.updateAuthenticationInfo()
        SystemUtils.onFirstRun()

        let fxaLoginHelper = FxALoginHelper.sharedInstance
        fxaLoginHelper.application(application, didLoadProfile: profile)

        log.info("startApplication end")
        return true
    }

    // TODO: Move to scene controller for iOS 13
    private func setupRootViewController() {
        browserViewController = BrowserViewController(profile: self.profile!, tabManager: self.tabManager)
        browserViewController.edgesForExtendedLayout = []

        browserViewController.restorationIdentifier = NSStringFromClass(BrowserViewController.self)
        browserViewController.restorationClass = AppDelegate.self

        let navigationController = UINavigationController(rootViewController: browserViewController)
        navigationController.delegate = self
        navigationController.isNavigationBarHidden = true
        navigationController.edgesForExtendedLayout = UIRectEdge(rawValue: 0)
        rootViewController = navigationController

        self.window!.rootViewController = rootViewController
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // We have only five seconds here, so let's hope this doesn't take too long.
        profile?._shutdown()

        // Allow deinitializers to close our database connections.
        profile = nil
        tabManager = nil
        browserViewController = nil
        rootViewController = nil
    }

    /**
     * We maintain a weak reference to the profile so that we can pause timed
     * syncs when we're backgrounded.
     *
     * The long-lasting ref to the profile lives in BrowserViewController,
     * which we set in application:willFinishLaunchingWithOptions:.
     *
     * If that ever disappears, we won't be able to grab the profile to stop
     * syncing... but in that case the profile's deinit will take care of things.
     */
    func getProfile(_ application: UIApplication) -> Profile {
        if let profile = self.profile {
            return profile
        }
        let p = BrowserProfile(localName: "profile", syncDelegate: application.syncDelegate)
        self.profile = p
        return p
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        var shouldPerformAdditionalDelegateHandling = true

        adjustIntegration?.triggerApplicationDidFinishLaunchingWithOptions(launchOptions)

        UNUserNotificationCenter.current().delegate = self
        SentTabAction.registerActions()
        UIScrollView.doBadSwizzleStuff()

        window!.makeKeyAndVisible()

        // Now roll logs.
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
            Logger.syncLogger.deleteOldLogsDownToSizeLimit()
            Logger.browserLogger.deleteOldLogsDownToSizeLimit()
        }

        // If a shortcut was launched, display its information and take the appropriate action
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {

            QuickActions.sharedInstance.launchedShortcutItem = shortcutItem
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }

        // Force the ToolbarTextField in LTR mode - without this change the UITextField's clear
        // button will be in the incorrect position and overlap with the input text. Not clear if
        // that is an iOS bug or not.
        AutocompleteTextField.appearance().semanticContentAttribute = .forceLeftToRight
        // Leanplum usersearch variable setup for onboarding research
        _ = OnboardingUserResearch()
        // Leanplum setup
        if let profile = self.profile, LeanPlumClient.shouldEnable(profile: profile) {
            LeanPlumClient.shared.setup(profile: profile)
            LeanPlumClient.shared.set(enabled: true)
        }

        if #available(iOS 13.0, *) {
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "org.mozilla.ios.sync.part1", using: DispatchQueue.global()) { task in
                guard self.profile?.hasSyncableAccount() ?? false else {
                    self.shutdownProfileWhenNotActive(application)
                    return
                }

                NSLog("background sync part 1") // NSLog to see in device console
                let collection = ["bookmarks", "history"]
                self.profile?.syncManager.syncNamedCollections(why: .backgrounded, names: collection).uponQueue(.main) { _ in
                    task.setTaskCompleted(success: true)
                    let request = BGProcessingTaskRequest(identifier: "org.mozilla.ios.sync.part2")
                    request.earliestBeginDate = Date(timeIntervalSinceNow: 1)
                    request.requiresNetworkConnectivity = true
                    do {
                        try BGTaskScheduler.shared.submit(request)
                    } catch {
                        NSLog(error.localizedDescription)
                    }
                }
            }

            // Split up the sync tasks so each can get maximal time for a bg task.
            // This task runs after the bookmarks+history sync.
            BGTaskScheduler.shared.register(forTaskWithIdentifier: "org.mozilla.ios.sync.part2", using: DispatchQueue.global()) { task in
                NSLog("background sync part 2") // NSLog to see in device console
                let collection = ["tabs", "logins", "clients"]
                self.profile?.syncManager.syncNamedCollections(why: .backgrounded, names: collection).uponQueue(.main) { _ in
                    self.shutdownProfileWhenNotActive(application)
                    task.setTaskCompleted(success: true)
                }
            }
        }

        return shouldPerformAdditionalDelegateHandling
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        guard let routerpath = NavigationPath(url: url) else {
            return false
        }

        if let profile = profile, let _ = profile.prefs.boolForKey(PrefsKeys.AppExtensionTelemetryOpenUrl) {
            profile.prefs.removeObjectForKey(PrefsKeys.AppExtensionTelemetryOpenUrl)
            var object = UnifiedTelemetry.EventObject.url
            if case .text(_) = routerpath {
                object = .searchText
            }
            UnifiedTelemetry.recordEvent(category: .appExtensionAction, method: .applicationOpenUrl, object: object)
        }

        DispatchQueue.main.async {
            NavigationPath.handle(nav: routerpath, with: BrowserViewController.foregroundBVC())
        }
        return true
    }

    // We sync in the foreground only, to avoid the possibility of runaway resource usage.
    // Eventually we'll sync in response to notifications.
    func applicationDidBecomeActive(_ application: UIApplication) {
        shutdownWebServer?.cancel()
        shutdownWebServer = nil

        //
        // We are back in the foreground, so set CleanlyBackgrounded to false so that we can detect that
        // the application was cleanly backgrounded later.
        //

        let defaults = UserDefaults()
        defaults.set(false, forKey: "ApplicationCleanlyBackgrounded")

        if let profile = self.profile {
            profile._reopen()

            if profile.prefs.boolForKey(PendingAccountDisconnectedKey) ?? false {
                FxALoginHelper.sharedInstance.applicationDidDisconnect(application)
            }

            profile.syncManager.applicationDidBecomeActive()

            setUpWebServer(profile)
        }
        
        BrowserViewController.foregroundBVC().firefoxHomeViewController?.reloadAll()
        
        // Resume file downloads.
        // TODO: iOS 13 needs to iterate all the BVCs.
        BrowserViewController.foregroundBVC().downloadQueue.resumeAll()

        // handle quick actions is available
        let quickActions = QuickActions.sharedInstance
        if let shortcut = quickActions.launchedShortcutItem {
            // dispatch asynchronously so that BVC is all set up for handling new tabs
            // when we try and open them
            quickActions.handleShortCutItem(shortcut, withBrowserViewController: BrowserViewController.foregroundBVC())
            quickActions.launchedShortcutItem = nil
        }

        UnifiedTelemetry.recordEvent(category: .action, method: .foreground, object: .app)

        // Delay these operations until after UIKit/UIApp init is complete
        // - loadQueuedTabs accesses the DB and shows up as a hot path in profiling
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // We could load these here, but then we have to futz with the tab counter
            // and making NSURLRequests.
            BrowserViewController.foregroundBVC().loadQueuedTabs(receivedURLs: self.receivedURLs)
            self.receivedURLs.removeAll()
            application.applicationIconBadgeNumber = 0
        }

        // Cleanup can be a heavy operation, take it out of the startup path. Instead check after a few seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.profile?.cleanupHistoryIfNeeded()
        }
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        //
        // At this point we are happy to mark the app as CleanlyBackgrounded. If a crash happens in background
        // sync then that crash will still be reported. But we won't bother the user with the Restore Tabs
        // dialog. We don't have to because at this point we already saved the tab state properly.
        //

        let defaults = UserDefaults()
        defaults.set(true, forKey: "ApplicationCleanlyBackgrounded")

        // Pause file downloads.
        // TODO: iOS 13 needs to iterate all the BVCs.
        BrowserViewController.foregroundBVC().downloadQueue.pauseAll()

        UnifiedTelemetry.recordEvent(category: .action, method: .background, object: .app)

        let singleShotTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
        // 2 seconds is ample for a localhost request to be completed by GCDWebServer. <500ms is expected on newer devices.
        singleShotTimer.schedule(deadline: .now() + 2.0, repeating: .never)
        singleShotTimer.setEventHandler {
            WebServer.sharedInstance.server.stop()
            self.shutdownWebServer = nil
        }
        singleShotTimer.resume()
        shutdownWebServer = singleShotTimer

        if #available(iOS 13.0, *) {
            scheduleBGSync(application: application)
        } else {
            syncOnDidEnterBackground(application: application)
        }
    }

    fileprivate func syncOnDidEnterBackground(application: UIApplication) {
        guard let profile = self.profile else {
            return
        }

        profile.syncManager.applicationDidEnterBackground()

        // Create an expiring background task. This allows plenty of time for db locks to be released
        // async. Otherwise we are getting crashes due to db locks not released yet.
        var taskId: UIBackgroundTaskIdentifier = UIBackgroundTaskIdentifier(rawValue: 0)
        taskId = application.beginBackgroundTask (expirationHandler: {
            print("Running out of background time, but we have a profile shutdown pending.")
            self.shutdownProfileWhenNotActive(application)
            application.endBackgroundTask(taskId)
        })

        if profile.hasSyncableAccount() {
            profile.syncManager.syncEverything(why: .backgrounded).uponQueue(.main) { _ in
                self.shutdownProfileWhenNotActive(application)
                application.endBackgroundTask(taskId)
            }
        } else {
            profile._shutdown()
            application.endBackgroundTask(taskId)
        }
    }

    fileprivate func shutdownProfileWhenNotActive(_ application: UIApplication) {
        // Only shutdown the profile if we are not in the foreground
        guard application.applicationState != .active else {
            return
        }

        profile?._shutdown()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // The reason we need to call this method here instead of `applicationDidBecomeActive`
        // is that this method is only invoked whenever the application is entering the foreground where as
        // `applicationDidBecomeActive` will get called whenever the Touch ID authentication overlay disappears.
        self.updateAuthenticationInfo()
    }

    fileprivate func updateAuthenticationInfo() {
        if let authInfo = KeychainWrapper.sharedAppContainerKeychain.authenticationInfo() {
            if !LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) {
                authInfo.useTouchID = false
                KeychainWrapper.sharedAppContainerKeychain.setAuthenticationInfo(authInfo)
            }
        }
    }

    fileprivate func setUpWebServer(_ profile: Profile) {
        let server = WebServer.sharedInstance
        guard !server.server.isRunning else { return }

        ReaderModeHandlers.register(server, profile: profile)

        let responders: [(String, InternalSchemeResponse)] =
            [ (AboutHomeHandler.path, AboutHomeHandler()),
              (AboutLicenseHandler.path, AboutLicenseHandler()),
              (SessionRestoreHandler.path, SessionRestoreHandler()),
              (ErrorPageHandler.path, ErrorPageHandler())]
        responders.forEach { (path, responder) in
            InternalSchemeHandler.responders[path] = responder
        }

        if AppConstants.IsRunningTest {
            registerHandlersForTestMethods(server: server.server)
        }

        // Bug 1223009 was an issue whereby CGDWebserver crashed when moving to a background task
        // catching and handling the error seemed to fix things, but we're not sure why.
        // Either way, not implicitly unwrapping a try is not a great way of doing things
        // so this is better anyway.
        do {
            try server.start()
        } catch let err as NSError {
            print("Error: Unable to start WebServer \(err)")
        }
    }

    fileprivate func setUserAgent() {
        let firefoxUA = UserAgent.getUserAgent()

        // Set the UA for WKWebView (via defaults), the favicon fetcher, and the image loader.
        // This only needs to be done once per runtime. Note that we use defaults here that are
        // readable from extensions, so they can just use the cached identifier.

        SDWebImageDownloader.shared.setValue(firefoxUA, forHTTPHeaderField: "User-Agent")
        //SDWebImage is setting accept headers that report we support webp. We don't
        SDWebImageDownloader.shared.setValue("image/*;q=0.8", forHTTPHeaderField: "Accept")

        // Record the user agent for use by search suggestion clients.
        SearchViewController.userAgent = firefoxUA

        // Some sites will only serve HTML that points to .ico files.
        // The FaviconFetcher is explicitly for getting high-res icons, so use the desktop user agent.
        FaviconFetcher.userAgent = UserAgent.desktopUserAgent()
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        let bvc = BrowserViewController.foregroundBVC()
        if #available(iOS 12.0, *) {
            if userActivity.activityType == SiriShortcuts.activityType.openURL.rawValue {
                bvc.openBlankNewTab(focusLocationField: false)
                return true
            }
        }

        // If the `NSUserActivity` has a `webpageURL`, it is either a deep link or an old history item
        // reached via a "Spotlight" search before we began indexing visited pages via CoreSpotlight.
        if let url = userActivity.webpageURL {
            let query = url.getQuery()

            // Check for fxa sign-in code and launch the login screen directly
            if query["signin"] != nil {
                bvc.launchFxAFromDeeplinkURL(url)
                return true
            }

            // Per Adjust documenation, https://docs.adjust.com/en/universal-links/#running-campaigns-through-universal-links,
            // it is recommended that links contain the `deep_link` query parameter. This link will also
            // be url encoded.
            if let deepLink = query["deep_link"]?.removingPercentEncoding, let url = URL(string: deepLink) {
                bvc.switchToTabForURLOrOpen(url)
                return true
            }

            bvc.switchToTabForURLOrOpen(url)
            return true
        }

        // Otherwise, check if the `NSUserActivity` is a CoreSpotlight item and switch to its tab or
        // open a new one.
        if userActivity.activityType == CSSearchableItemActionType {
            if let userInfo = userActivity.userInfo,
                let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String,
                let url = URL(string: urlString) {
                bvc.switchToTabForURLOrOpen(url)
                return true
            }
        }

        return false
    }

    fileprivate func openURLsInNewTabs(_ notification: UNNotification) {
        guard let urls = notification.request.content.userInfo["sentTabs"] as? [NSDictionary]  else { return }
        for sentURL in urls {
            if let urlString = sentURL.value(forKey: "url") as? String, let url = URL(string: urlString) {
                receivedURLs.append(url)
            }
        }

        // Check if the app is foregrounded, _also_ verify the BVC is initialized. Most BVC functions depend on viewDidLoad() having run –if not, they will crash.
        if UIApplication.shared.applicationState == .active && BrowserViewController.foregroundBVC().isViewLoaded {
            BrowserViewController.foregroundBVC().loadQueuedTabs(receivedURLs: receivedURLs)
            receivedURLs.removeAll()
        }
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortCutItem = QuickActions.sharedInstance.handleShortCutItem(shortcutItem, withBrowserViewController: BrowserViewController.foregroundBVC())

        completionHandler(handledShortCutItem)
    }

    @available(iOS 13.0, *)
    private func scheduleBGSync(application: UIApplication) {
        if profile?.syncManager.isSyncing ?? false {
            // If syncing, create a bg task because _shutdown() is blocking and might take a few seconds to complete
            var taskId = UIBackgroundTaskIdentifier(rawValue: 0)
            taskId = application.beginBackgroundTask(expirationHandler: {
                self.shutdownProfileWhenNotActive(application)
                application.endBackgroundTask(taskId)
            })

            DispatchQueue.main.async {
                self.shutdownProfileWhenNotActive(application)
                application.endBackgroundTask(taskId)
            }
        } else {
            // Blocking call, however without sync running it should be instantaneous
            profile?._shutdown()

            let request = BGProcessingTaskRequest(identifier: "org.mozilla.ios.sync.part1")
            request.earliestBeginDate = Date(timeIntervalSinceNow: 1)
            request.requiresNetworkConnectivity = true
            do {
                try BGTaskScheduler.shared.submit(request)
            } catch {
                NSLog(error.localizedDescription)
            }
        }
    }
}

// MARK: - Root View Controller Animations
extension AppDelegate: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            return BrowserToTrayAnimator()
        case .pop:
            return TrayToBrowserAnimator()
        default:
            return nil
        }
    }
}

extension AppDelegate: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss the view controller and start the app up
        controller.dismiss(animated: true, completion: nil)
        _ = startApplication(application!, withLaunchOptions: self.launchOptions)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Called when the user taps on a sent-tab notification from the background.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        openURLsInNewTabs(response.notification)
    }

    // Called when the user receives a tab while in foreground.
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        openURLsInNewTabs(notification)
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        FxALoginHelper.sharedInstance.apnsRegisterDidSucceed(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("failed to register. \(error)")
        FxALoginHelper.sharedInstance.apnsRegisterDidFail()
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if Logger.logPII && log.isEnabledFor(level: .info) {
            NSLog("APNS NOTIFICATION \(userInfo)")
        }

        // At this point, we know that NotificationService has been run.
        // We get to this point if the notification was received while the app was in the foreground
        // OR the app was backgrounded and now the user has tapped on the notification.
        // Either way, if this method is being run, then the app is foregrounded.

        // Either way, we should zero the badge number.
        application.applicationIconBadgeNumber = 0

        guard let profile = self.profile else {
            return completionHandler(.noData)
        }

        // NotificationService will have decrypted the push message, and done some syncing
        // activity. If the `client` collection was synced, and there are `displayURI` commands (i.e. sent tabs)
        // NotificationService will have collected them for us in the userInfo.
        if let serializedTabs = userInfo["sentTabs"] as? [NSDictionary] {
            // Let's go ahead and open those.
            for item in serializedTabs {
                if let urlString = item["url"] as? String, let url = URL(string: urlString) {
                    receivedURLs.append(url)
                }
            }

            if receivedURLs.count > 0 {
                // If we're in the foreground, load the queued tabs now.
                if application.applicationState == .active {
                    DispatchQueue.main.async {
                        BrowserViewController.foregroundBVC().loadQueuedTabs(receivedURLs: self.receivedURLs)
                        self.receivedURLs.removeAll()
                    }
                }

                return completionHandler(.newData)
            }
        }

        // By now, we've dealt with any sent tab notifications.
        //
        // The only thing left to do now is to perform actions that can only be performed
        // while the app is foregrounded.
        //
        // Use the push message handler to re-parse the message,
        // this time with a BrowserProfile and processing the return
        // differently than in NotificationService.
        let handler = FxAPushMessageHandler(with: profile)
        handler.handle(userInfo: userInfo).upon { res in
            if let message = res.successValue {
                switch message {
                case .accountVerified:
                    _ = handler.postVerification()
                case .thisDeviceDisconnected:
                    FxALoginHelper.sharedInstance.applicationDidDisconnect(application)
                default:
                    break
                }
            }

            completionHandler(res.isSuccess ? .newData : .failed)
        }
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        let completionHandler: (UIBackgroundFetchResult) -> Void = { _ in }
        self.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
}

extension UIApplication {
    var syncDelegate: SyncDelegate {
        return AppSyncDelegate(app: self)
    }

    static var isInPrivateMode: Bool {
        return BrowserViewController.foregroundBVC().tabManager.selectedTab?.isPrivate ?? false
    }
}

class AppSyncDelegate: SyncDelegate {
    let app: UIApplication

    init(app: UIApplication) {
        self.app = app
    }

    open func displaySentTab(for url: URL, title: String, from deviceName: String?) {
        DispatchQueue.main.sync {
            if app.applicationState == .active {
                BrowserViewController.foregroundBVC().switchToTabForURLOrOpen(url)
                return
            }

            // check to see what the current notification settings are and only try and send a notification if
            // the user has agreed to them
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                if settings.alertSetting == .enabled {
                    if Logger.logPII {
                        log.info("Displaying notification for URL \(url.absoluteString)")
                    }

                    let notificationContent = UNMutableNotificationContent()
                    let title: String
                    if let deviceName = deviceName {
                        title = String(format: Strings.SentTab_TabArrivingNotification_WithDevice_title, deviceName)
                    } else {
                        title = Strings.SentTab_TabArrivingNotification_NoDevice_title
                    }
                    notificationContent.title = title
                    notificationContent.body = url.absoluteDisplayExternalString
                    notificationContent.userInfo = [SentTabAction.TabSendURLKey: url.absoluteString, SentTabAction.TabSendTitleKey: title]
                    notificationContent.categoryIdentifier = "org.mozilla.ios.SentTab.placeholder"

                    // `timeInterval` must be greater than zero
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

                    // The identifier for each notification request must be unique in order to be created
                    let requestIdentifier = "\(SentTabAction.TabSendCategory).\(url.absoluteString)"
                    let request = UNNotificationRequest(identifier: requestIdentifier, content: notificationContent, trigger: trigger)

                    UNUserNotificationCenter.current().add(request) { error in
                        if let error = error {
                            log.error(error.localizedDescription)
                        }
                    }
                }
            }
        }
    }
}

/**
 * This exists because the Sync code is extension-safe, and thus doesn't get
 * direct access to UIApplication.sharedApplication, which it would need to
 * display a notification.
 * This will also likely be the extension point for wipes, resets, and
 * getting access to data sources during a sync.
 */

enum SentTabAction: String {
    case view = "TabSendViewAction"

    static let TabSendURLKey = "TabSendURL"
    static let TabSendTitleKey = "TabSendTitle"
    static let TabSendCategory = "TabSendCategory"

    static func registerActions() {
        let viewAction = UNNotificationAction(identifier: SentTabAction.view.rawValue, title: Strings.SentTabViewActionTitle, options: .foreground)

        // Register ourselves to handle the notification category set by NotificationService for APNS notifications
        let sentTabCategory = UNNotificationCategory(identifier: "org.mozilla.ios.SentTab.placeholder", actions: [viewAction], intentIdentifiers: [], options: UNNotificationCategoryOptions(rawValue: 0))
        UNUserNotificationCenter.current().setNotificationCategories([sentTabCategory])
    }
}
