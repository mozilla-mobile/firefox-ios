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

private let log = Logger.browserLogger

let LatestAppVersionProfileKey = "latestAppVersion"
let AllowThirdPartyKeyboardsKey = "settings.allowThirdPartyKeyboards"
private let InitialPingSentKey = "initialPingSent"

class AppDelegate: UIResponder, UIApplicationDelegate, UIViewControllerRestoration {
    public static func viewController(withRestorationIdentifierPath identifierComponents: [Any], coder: NSCoder) -> UIViewController? {
        return nil
    }

    var window: UIWindow?
    var browserViewController: BrowserViewController!
    var rootViewController: UIViewController!
    weak var profile: Profile?
    var tabManager: TabManager!
    var adjustIntegration: AdjustIntegration?
    var applicationCleanlyBackgrounded = true

    weak var application: UIApplication?
    var launchOptions: [AnyHashable: Any]?

    let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

    var receivedURLs = [URL]()
    var unifiedTelemetry: UnifiedTelemetry?

    @discardableResult func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
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
        defaults.synchronize()

        // Hold references to willFinishLaunching parameters for delayed app launch
        self.application = application
        self.launchOptions = launchOptions

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window!.backgroundColor = UIColor.Photon.White100

        // Short circuit the app if we want to email logs from the debug menu
        if DebugSettingsBundleOptions.launchIntoEmailComposer {
            self.window?.rootViewController = UIViewController()
            presentEmailComposerWithLogs()
            return true
        } else {
            return startApplication(application, withLaunchOptions: launchOptions)
        }
    }

    @discardableResult fileprivate func startApplication(_ application: UIApplication, withLaunchOptions launchOptions: [AnyHashable: Any]?) -> Bool {
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

        if !DebugSettingsBundleOptions.disableLocalWebServer {
            // Set up a web server that serves us static content. Do this early so that it is ready when the UI is presented.
            setUpWebServer(profile)
        }

        let imageStore = DiskImageStore(files: profile.files, namespace: "TabManagerScreenshots", quality: UIConstants.ScreenshotQuality)

        // Temporary fix for Bug 1390871 - NSInvalidArgumentException: -[WKContentView menuHelperFindInPage]: unrecognized selector
        if #available(iOS 11, *) {
            if let clazz = NSClassFromString("WKCont" + "ent" + "View"), let swizzledMethod = class_getInstanceMethod(TabWebViewMenuHelper.self, #selector(TabWebViewMenuHelper.swizzledMenuHelperFindInPage)) {
                class_addMethod(clazz, MenuHelper.SelectorFindInPage, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))
            }
        }

        self.tabManager = TabManager(prefs: profile.prefs, imageStore: imageStore)
        self.tabManager.stateDelegate = self

        // Add restoration class, the factory that will return the ViewController we
        // will restore with.

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

        if LeanPlumClient.shouldEnable(profile: profile) {
            LeanPlumClient.shared.setup(profile: profile)
            LeanPlumClient.shared.set(enabled: true)
        }

        self.updateAuthenticationInfo()
        SystemUtils.onFirstRun()

        let fxaLoginHelper = FxALoginHelper.sharedInstance
        fxaLoginHelper.application(application, didLoadProfile: profile)

        log.info("startApplication end")
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // We have only five seconds here, so let's hope this doesn't take too long.
        self.profile?.shutdown()

        // Allow deinitializers to close our database connections.
        self.profile = nil
        self.tabManager = nil
        self.browserViewController = nil
        self.rootViewController = nil
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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        var shouldPerformAdditionalDelegateHandling = true

        adjustIntegration?.triggerApplicationDidFinishLaunchingWithOptions(launchOptions)

        UNUserNotificationCenter.current().delegate = self
        SentTabAction.registerActions()
        UIScrollView.doBadSwizzleStuff()

        #if BUDDYBUILD
            print("Setting up BuddyBuild SDK")
            BuddyBuildSDK.setup()
        #endif
        
        window!.makeKeyAndVisible()

        // Now roll logs.
        DispatchQueue.global(qos: DispatchQoS.background.qosClass).async {
            Logger.syncLogger.deleteOldLogsDownToSizeLimit()
            Logger.browserLogger.deleteOldLogsDownToSizeLimit()
        }

        // If a shortcut was launched, display its information and take the appropriate action
        if let shortcutItem = launchOptions?[UIApplicationLaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {

            QuickActions.sharedInstance.launchedShortcutItem = shortcutItem
            // This will block "performActionForShortcutItem:completionHandler" from being called.
            shouldPerformAdditionalDelegateHandling = false
        }

        // Force the ToolbarTextField in LTR mode - without this change the UITextField's clear
        // button will be in the incorrect position and overlap with the input text. Not clear if
        // that is an iOS bug or not.
        AutocompleteTextField.appearance().semanticContentAttribute = .forceLeftToRight

        return shouldPerformAdditionalDelegateHandling
    }

    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
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
            NavigationPath.handle(nav: routerpath, with: self.browserViewController)
        }
        return true
    }

    // We sync in the foreground only, to avoid the possibility of runaway resource usage.
    // Eventually we'll sync in response to notifications.
    func applicationDidBecomeActive(_ application: UIApplication) {
        guard !DebugSettingsBundleOptions.launchIntoEmailComposer else {
            return
        }

        //
        // We are back in the foreground, so set CleanlyBackgrounded to false so that we can detect that
        // the application was cleanly backgrounded later.
        //

        let defaults = UserDefaults()
        defaults.set(false, forKey: "ApplicationCleanlyBackgrounded")
        defaults.synchronize()

        if let profile = self.profile {
            profile.reopen()

            if profile.prefs.boolForKey(PendingAccountDisconnectedKey) ?? false {
                FxALoginHelper.sharedInstance.applicationDidDisconnect(application)
            }

            profile.syncManager.applicationDidBecomeActive()
        }

        // We could load these here, but then we have to futz with the tab counter
        // and making NSURLRequests.
        browserViewController.loadQueuedTabs(receivedURLs: receivedURLs)
        receivedURLs.removeAll()
        application.applicationIconBadgeNumber = 0

        // handle quick actions is available
        let quickActions = QuickActions.sharedInstance
        if let shortcut = quickActions.launchedShortcutItem {
            // dispatch asynchronously so that BVC is all set up for handling new tabs
            // when we try and open them
            quickActions.handleShortCutItem(shortcut, withBrowserViewController: browserViewController)
            quickActions.launchedShortcutItem = nil
        }

        UnifiedTelemetry.recordEvent(category: .action, method: .foreground, object: .app)
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        //
        // At this point we are happy to mark the app as CleanlyBackgrounded. If a crash happens in background
        // sync then that crash will still be reported. But we won't bother the user with the Restore Tabs
        // dialog. We don't have to because at this point we already saved the tab state properly.
        //

        let defaults = UserDefaults()
        defaults.set(true, forKey: "ApplicationCleanlyBackgrounded")
        defaults.synchronize()

        syncOnDidEnterBackground(application: application)

        UnifiedTelemetry.recordEvent(category: .action, method: .background, object: .app)
    }

    fileprivate func syncOnDidEnterBackground(application: UIApplication) {
        guard let profile = self.profile else {
            return
        }

        profile.syncManager.applicationDidEnterBackground()

        var taskId: UIBackgroundTaskIdentifier = 0
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
            profile.shutdown()
            application.endBackgroundTask(taskId)
        }
    }

    fileprivate func shutdownProfileWhenNotActive(_ application: UIApplication) {
        // Only shutdown the profile if we are not in the foreground
        guard application.applicationState != .active else {
            return
        }

        profile?.shutdown()
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
        ReaderModeHandlers.register(server, profile: profile)
        ErrorPageHelper.register(server, certStore: profile.certStore)
        AboutHomeHandler.register(server)
        AboutLicenseHandler.register(server)
        SessionRestoreHandler.register(server)

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
        let firefoxUA = UserAgent.defaultUserAgent()

        // Set the UA for WKWebView (via defaults), the favicon fetcher, and the image loader.
        // This only needs to be done once per runtime. Note that we use defaults here that are
        // readable from extensions, so they can just use the cached identifier.
        let defaults = UserDefaults(suiteName: AppInfo.sharedContainerIdentifier)!
        defaults.register(defaults: ["UserAgent": firefoxUA])

        SDWebImageDownloader.shared().setValue(firefoxUA, forHTTPHeaderField: "User-Agent")

        // Record the user agent for use by search suggestion clients.
        SearchViewController.userAgent = firefoxUA

        // Some sites will only serve HTML that points to .ico files.
        // The FaviconFetcher is explicitly for getting high-res icons, so use the desktop user agent.
        FaviconFetcher.userAgent = UserAgent.desktopUserAgent()
    }

    fileprivate func presentEmailComposerWithLogs() {
        if let buildNumber = Bundle.main.object(forInfoDictionaryKey: String(kCFBundleVersionKey)) as? NSString {
            let mailComposeViewController = MFMailComposeViewController()
            mailComposeViewController.mailComposeDelegate = self
            mailComposeViewController.setSubject("Debug Info for iOS client version v\(appVersion) (\(buildNumber))")

            if DebugSettingsBundleOptions.attachLogsToDebugEmail {
                do {
                    let logNamesAndData = try Logger.diskLogFilenamesAndData()
                    logNamesAndData.forEach { nameAndData in
                        if let data = nameAndData.1 {
                            mailComposeViewController.addAttachmentData(data, mimeType: "text/plain", fileName: nameAndData.0)
                        }
                    }
                } catch _ {
                    print("Failed to retrieve logs from device")
                }
            }

            if DebugSettingsBundleOptions.attachTabStateToDebugEmail {
                if let tabStateDebugData = TabManager.tabRestorationDebugInfo().data(using: .utf8) {
                    mailComposeViewController.addAttachmentData(tabStateDebugData, mimeType: "text/plain", fileName: "tabState.txt")
                }

                if let tabStateData = TabManager.tabArchiveData() {
                    mailComposeViewController.addAttachmentData(tabStateData as Data, mimeType: "application/octet-stream", fileName: "tabsState.archive")
                }
            }

            self.window?.rootViewController?.present(mailComposeViewController, animated: true, completion: nil)
        }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([Any]?) -> Void) -> Bool {

        // If the `NSUserActivity` has a `webpageURL`, it is either a deep link or an old history item
        // reached via a "Spotlight" search before we began indexing visited pages via CoreSpotlight.
        if let url = userActivity.webpageURL {
            let query = url.getQuery()
            
            // Check for fxa sign-in code and launch the login screen directly
            if query["signin"] != nil {
                browserViewController.launchFxAFromDeeplinkURL(url)
                return true
            }
            
            // Per Adjust documenation, https://docs.adjust.com/en/universal-links/#running-campaigns-through-universal-links,
            // it is recommended that links contain the `deep_link` query parameter. This link will also
            // be url encoded.
            if let deepLink = query["deep_link"]?.removingPercentEncoding, let url = URL(string: deepLink) {
                browserViewController.switchToTabForURLOrOpen(url, isPrivileged: true)
                return true
            }

            browserViewController.switchToTabForURLOrOpen(url, isPrivileged: true)
            return true
        }

        // Otherwise, check if the `NSUserActivity` is a CoreSpotlight item and switch to its tab or
        // open a new one.
        if userActivity.activityType == CSSearchableItemActionType {
            if let userInfo = userActivity.userInfo,
                let urlString = userInfo[CSSearchableItemActivityIdentifier] as? String,
                let url = URL(string: urlString) {
                browserViewController.switchToTabForURLOrOpen(url, isPrivileged: true)
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
    }

    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        let handledShortCutItem = QuickActions.sharedInstance.handleShortCutItem(shortcutItem, withBrowserViewController: browserViewController)

        completionHandler(handledShortCutItem)
    }
}

// MARK: - Root View Controller Animations
extension AppDelegate: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationControllerOperation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
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

extension AppDelegate: TabManagerStateDelegate {
    func tabManagerWillStoreTabs(_ tabs: [Tab]) {
        // It is possible that not all tabs have loaded yet, so we filter out tabs with a nil URL.
        let storedTabs: [RemoteTab] = tabs.compactMap( Tab.toTab )

        // Don't insert into the DB immediately. We tend to contend with more important
        // work like querying for top sites.
        let queue = DispatchQueue.global(qos: DispatchQoS.background.qosClass)
        queue.asyncAfter(deadline: DispatchTime.now() + Double(Int64(ProfileRemoteTabsSyncDelay * Double(NSEC_PER_MSEC))) / Double(NSEC_PER_SEC)) {
            self.profile?.storeTabs(storedTabs)
        }
    }
}

extension AppDelegate: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // Dismiss the view controller and start the app up
        controller.dismiss(animated: true, completion: nil)
        startApplication(application!, withLaunchOptions: self.launchOptions)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        openURLsInNewTabs(response.notification)
    }

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
        if let serializedTabs = userInfo["sentTabs"] as? [[String: String]] {
            // Let's go ahead and open those.
            for item in serializedTabs {
                if let tabURL = item["url"], let url = URL(string: tabURL) {
                    receivedURLs.append(url)
                }
            }

            if receivedURLs.count > 0 {
                // If we're in the foreground, load the queued tabs now.
                if application.applicationState == .active {
                    DispatchQueue.main.async {
                        self.browserViewController.loadQueuedTabs(receivedURLs: self.receivedURLs)
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
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        return appDelegate?.browserViewController.tabManager.selectedTab?.isPrivate ?? false
    }
}

class AppSyncDelegate: SyncDelegate {
    let app: UIApplication

    init(app: UIApplication) {
        self.app = app
    }

    open func displaySentTab(for url: URL, title: String, from deviceName: String?) {
        DispatchQueue.main.sync {
            if let appDelegate = app.delegate as? AppDelegate, app.applicationState == .active {
                appDelegate.browserViewController.switchToTabForURLOrOpen(url, isPrivileged: false)
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
