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
import SwiftRouter
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

    var openInFirefoxParams: LaunchParams?

    var receivedURLs: [URL]?
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
        self.window!.backgroundColor = UIColor.white

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

        do {
            // for aural progress bar: play even with silent switch on, and do not stop audio from other apps (like music)
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: AVAudioSessionCategoryOptions.mixWithOthers)
        } catch _ {
            print("Error: Failed to assign AVAudioSession category to allow playing with silent switch on for aural progress bar")
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

        NotificationCenter.default.addObserver(forName: NSNotification.Name.FSReadingListAddReadingListItem, object: nil, queue: nil) { (notification) -> Void in
            if let userInfo = notification.userInfo, let url = userInfo["URL"] as? URL {
                let title = (userInfo["Title"] as? String) ?? ""
                profile.readingList?.createRecordWithURL(url.absoluteString, title: title, addedBy: UIDevice.current.name)
            }
        }

        NotificationCenter.default.addObserver(forName: NotificationFirefoxAccountDeviceRegistrationUpdated, object: nil, queue: nil) { _ in
            profile.flushAccount()
        }

        adjustIntegration = AdjustIntegration(profile: profile)

        let leanplum = LeanplumIntegration.sharedInstance
        leanplum.setup(profile: profile)
        leanplum.setEnabled(true)

        self.updateAuthenticationInfo()
        SystemUtils.onFirstRun()

        let fxaLoginHelper = FxALoginHelper.sharedInstance
        fxaLoginHelper.application(application, didLoadProfile: profile)

        setUpDeepLinks(application: application)

        log.info("startApplication end")
        return true
    }

    func setUpDeepLinks(application: UIApplication) {
        let router = Router.shared
        let rootNav = rootViewController as! UINavigationController

        router.map("homepanel/:page", handler: { (params: [String: String]?) -> (Bool) in
            guard let page = params?["page"] else {
                return false
            }

            assert(Thread.isMainThread, "Opening homepanels requires being invoked on the main thread")

            switch page {
                case "bookmarks":
                    self.browserViewController.openURLInNewTab(HomePanelType.bookmarks.localhostURL, isPrivileged: true)
                case "history":
                    self.browserViewController.openURLInNewTab(HomePanelType.history.localhostURL, isPrivileged: true)
                case "new-private-tab":
                    self.browserViewController.openBlankNewTab(focusLocationField: false, isPrivate: true)
            default:
                break
            }

            return true
        })

        // Route to general settings page like this: "...settings/general"
        router.map("settings/:page", handler: { (params: [String: String]?) -> (Bool) in
            guard let page = params?["page"] else {
                return false
            }

            assert(Thread.isMainThread, "Opening settings requires being invoked on the main thread")

            let settingsTableViewController = AppSettingsTableViewController()
            settingsTableViewController.profile = self.profile
            settingsTableViewController.tabManager = self.tabManager
            settingsTableViewController.settingsDelegate = self.browserViewController

            let controller = SettingsNavigationController(rootViewController: settingsTableViewController)
            controller.popoverDelegate = self.browserViewController
            controller.modalPresentationStyle = UIModalPresentationStyle.formSheet

            rootNav.present(controller, animated: true, completion: nil)

            switch page {
                case "newtab":
                    let viewController = NewTabChoiceViewController(prefs: self.getProfile(application).prefs)
                    controller.pushViewController(viewController, animated: true)
                case "homepage":
                    let viewController = HomePageSettingsViewController()
                    viewController.profile = self.getProfile(application)
                    viewController.tabManager = self.tabManager
                    controller.pushViewController(viewController, animated: true)
                case "mailto":
                    let viewController = OpenWithSettingsViewController(prefs: self.getProfile(application).prefs)
                    controller.pushViewController(viewController, animated: true)
                case "search":
                    let viewController = SearchSettingsTableViewController()
                    viewController.model = self.getProfile(application).searchEngines
                    viewController.profile = self.getProfile(application)
                    controller.pushViewController(viewController, animated: true)
                case "clear-private-data":
                    let viewController = ClearPrivateDataTableViewController()
                    viewController.profile = self.getProfile(application)
                    viewController.tabManager = self.tabManager
                    controller.pushViewController(viewController, animated: true)
                case "fxa":
                    self.browserViewController.presentSignInViewController()
            default:
                break
            }

            return true
        })
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
        self.registerNotificationCategories()

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

        return shouldPerformAdditionalDelegateHandling
    }

    func registerNotificationCategories() {
        let viewAction = UNNotificationAction(identifier: SentTabAction.view.rawValue, title: Strings.SentTabViewActionTitle, options: .foreground)
        let bookmarkAction = UNNotificationAction(identifier: SentTabAction.bookmark.rawValue, title: Strings.SentTabBookmarkActionTitle, options: .authenticationRequired)
        let readingListAction = UNNotificationAction(identifier: SentTabAction.readingList.rawValue, title: Strings.SentTabAddToReadingListActionTitle, options: .authenticationRequired)

        // Register ourselves to handle the notification category set by NotificationService for APNS notifications
        let sentTabCategory = UNNotificationCategory(identifier: "org.mozilla.ios.SentTab.placeholder", actions: [viewAction, bookmarkAction, readingListAction], intentIdentifiers: [], options: UNNotificationCategoryOptions(rawValue: 0))
        UNUserNotificationCenter.current().setNotificationCategories([sentTabCategory])
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return false
        }

        guard let urlTypes = Bundle.main.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [AnyObject],
                let urlSchemes = urlTypes.first?["CFBundleURLSchemes"] as? [String] else {
            // Something very strange has happened; org.mozilla.Client should be the zeroeth URL type.
            log.error("Custom URL schemes not available for validating")
            return false
        }

        guard let scheme = components.scheme, urlSchemes.contains(scheme) else {
            log.warning("Cannot handle \(components.scheme ?? "nil") URL scheme")
            return false
        }

        guard let host = url.host else {
            log.warning("Cannot handle nil URL host")
            return false
        }

        let query = url.getQuery()

        switch host {
        case "open-url":
            let url = query["url"]?.unescape() ?? ""
            let isPrivate = NSString(string: query["private"] ?? "false").boolValue

            let params = LaunchParams(url: URL(string: url), isPrivate: isPrivate)

            if application.applicationState == .active {
                // If we are active then we can ask the BVC to open the new tab right away.
                // Otherwise, we remember the URL and we open it in applicationDidBecomeActive.
                launchFromURL(params)
            } else {
                openInFirefoxParams = params
            }
            return true
        case "deep-link":
            guard let url = query["url"], Bundle.main.bundleIdentifier == sourceApplication else {
                break
            }
            Router.shared.routeURL(url)
            return true
        case "fxa-signin":
            if AppConstants.MOZ_FXA_DEEP_LINK_FORM_FILL {
                // FxA form filling requires a `signin` query param and host = fxa-signin
                // Ex. firefox://fxa-signin?signin=<token>&someQuery=<data>...
                guard let signinQuery = query["signin"] else {
                    break
                }
                let fxaParams: FxALaunchParams
                fxaParams = FxALaunchParams(query: query)
                launchFxAFromURL(fxaParams)
                return true
            }
            break
        default: ()
        }
        return false
    }

    func launchFxAFromURL(_ params: FxALaunchParams) {
        guard params.query != nil else {
            return
        }
        self.browserViewController.presentSignInViewController(params)
    }

    func launchFromURL(_ params: LaunchParams) {
        let isPrivate = params.isPrivate ?? false
        if let newURL = params.url {
            self.browserViewController.switchToTabForURLOrOpen(newURL, isPrivate: isPrivate, isPrivileged: false)
        } else {
            self.browserViewController.openBlankNewTab(focusLocationField: true, isPrivate: isPrivate)
        }

        LeanplumIntegration.sharedInstance.track(eventName: .openedNewTab, withParameters: ["Source": "External App or Extension" as AnyObject])
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
        self.browserViewController.loadQueuedTabs(receivedURLs: self.receivedURLs)
        self.receivedURLs = nil
        application.applicationIconBadgeNumber = 0

        // handle quick actions is available
        let quickActions = QuickActions.sharedInstance
        if let shortcut = quickActions.launchedShortcutItem {
            // dispatch asynchronously so that BVC is all set up for handling new tabs
            // when we try and open them
            quickActions.handleShortCutItem(shortcut, withBrowserViewController: browserViewController)
            quickActions.launchedShortcutItem = nil
        }

        // Check if we have a URL from an external app or extension waiting to launch,
        // then launch it on the main thread.
        if let params = openInFirefoxParams {
            openInFirefoxParams = nil
            DispatchQueue.main.async {
                self.launchFromURL(params)
            }
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
        defaults.synchronize()

        syncOnDidEnterBackground(application: application)
    }

    fileprivate func syncOnDidEnterBackground(application: UIApplication) {
        guard let profile = self.profile else {
            return
        }

        profile.syncManager.applicationDidEnterBackground()

        var taskId: UIBackgroundTaskIdentifier = 0
        taskId = application.beginBackgroundTask (expirationHandler: { _ in
            print("Running out of background time, but we have a profile shutdown pending.")
            self.shutdownProfileWhenNotActive(application)
            application.endBackgroundTask(taskId)
        })

        if profile.hasSyncableAccount() {
            profile.syncManager.syncEverything(why: .backgrounded).uponQueue(DispatchQueue.main) { _ in
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
        guard application.applicationState != UIApplicationState.active else {
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
                if let tabStateDebugData = TabManager.tabRestorationDebugInfo().data(using: String.Encoding.utf8) {
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

    fileprivate func viewURLInNewTab(_ notification: UNNotification) {
        if let alertURL = notification.request.content.userInfo[TabSendURLKey] as? String {
            if let urlToOpen = URL(string: alertURL) {
                browserViewController.openURLInNewTab(urlToOpen, isPrivileged: true)
            }
        }
    }

    fileprivate func addBookmark(_ notification: UNNotification) {
        if let alertURL = notification.request.content.userInfo[TabSendURLKey] as? String,
            let title = notification.request.content.userInfo[TabSendTitleKey] as? String {
            let tabState = TabState(isPrivate: false, desktopSite: false, isBookmarked: false, url: URL(string: alertURL), title: title, favicon: nil)
                browserViewController.addBookmark(tabState)

                let userData = [QuickActions.TabURLKey: alertURL,
                    QuickActions.TabTitleKey: title]
                QuickActions.sharedInstance.addDynamicApplicationShortcutItemOfType(.openLastBookmark, withUserData: userData, toApplication: UIApplication.shared)
        }
    }

    fileprivate func addToReadingList(_ notification: UNNotification) {
        if let alertURL = notification.request.content.userInfo[TabSendURLKey] as? String,
            let title = notification.request.content.userInfo[TabSendTitleKey] as? String {
            if let urlToOpen = URL(string: alertURL) {
                NotificationCenter.default.post(name: NSNotification.Name.FSReadingListAddReadingListItem, object: self, userInfo: ["URL": urlToOpen, "Title": title])
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
            if operation == UINavigationControllerOperation.push {
                return BrowserToTrayAnimator()
            } else if operation == UINavigationControllerOperation.pop {
                return TrayToBrowserAnimator()
            } else {
                return nil
            }
    }
}

extension AppDelegate: TabManagerStateDelegate {
    func tabManagerWillStoreTabs(_ tabs: [Tab]) {
        // It is possible that not all tabs have loaded yet, so we filter out tabs with a nil URL.
        let storedTabs: [RemoteTab] = tabs.flatMap( Tab.toTab )

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
        if let action = SentTabAction(rawValue: response.actionIdentifier) {
            viewURLInNewTab(response.notification)
            switch action {
            case .bookmark:
                addBookmark(response.notification)
                break
            case .readingList:
                addToReadingList(response.notification)
                break
            default:
                break
            }
        } else {
            log.error("Unknown notification action received")
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        viewURLInNewTab(notification)
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
            let receivedURLs = serializedTabs.flatMap { item -> URL? in
                guard let tabURL = item["url"] else {
                    return nil
                }
                return URL(string: tabURL)
            }

            if receivedURLs.count > 0 {
                // Remember which URLs we received so we can filter them out later when
                // loading the queued tabs.
                self.receivedURLs = receivedURLs
                
                // If we're in the foreground, load the queued tabs now.
                if application.applicationState == UIApplicationState.active {
                    DispatchQueue.main.async {
                        self.browserViewController.loadQueuedTabs(receivedURLs: self.receivedURLs)
                        self.receivedURLs = nil
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

struct FxALaunchParams {
    var query: [String: String]
}

struct LaunchParams {
    let url: URL?
    let isPrivate: Bool?
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
                    notificationContent.userInfo = [TabSendURLKey: url.absoluteString, TabSendTitleKey: title]
                    notificationContent.categoryIdentifier = "org.mozilla.ios.SentTab.placeholder"

                    // `timeInterval` must be greater than zero
                    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

                    // The identifier for each notification request must be unique in order to be created
                    let requestIdentifier = "\(TabSendCategory).\(url.absoluteString)"
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
