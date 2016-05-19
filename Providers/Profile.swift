/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Alamofire
import Foundation
import Account
import ReadingList
import Shared
import Storage
import Sync
import XCGLogger
import SwiftKeychainWrapper
import Deferred

private let log = Logger.syncLogger

public let NotificationProfileDidStartSyncing = "NotificationProfileDidStartSyncing"
public let NotificationProfileDidFinishSyncing = "NotificationProfileDidFinishSyncing"
public let ProfileRemoteTabsSyncDelay: NSTimeInterval = 0.1

public protocol SyncManager {
    var isSyncing: Bool { get }
    var lastSyncFinishTime: Timestamp? { get set }

    func hasSyncedHistory() -> Deferred<Maybe<Bool>>
    func hasSyncedLogins() -> Deferred<Maybe<Bool>>

    func syncClients() -> SyncResult
    func syncClientsThenTabs() -> SyncResult
    func syncHistory() -> SyncResult
    func syncLogins() -> SyncResult
    func syncEverything() -> Success

    // The simplest possible approach.
    func beginTimedSyncs()
    func endTimedSyncs()
    func applicationDidEnterBackground()
    func applicationDidBecomeActive()

    func onNewProfile()
    func onRemovedAccount(account: FirefoxAccount?) -> Success
    func onAddedAccount() -> Success
}

typealias EngineIdentifier = String
typealias SyncFunction = (SyncDelegate, Prefs, Ready) -> SyncResult
private typealias EngineStatus = (EngineIdentifier, SyncStatus)

class ProfileFileAccessor: FileAccessor {
    convenience init(profile: Profile) {
        self.init(localName: profile.localName())
    }

    init(localName: String) {
        let profileDirName = "profile.\(localName)"

        // Bug 1147262: First option is for device, second is for simulator.
        var rootPath: NSString
        if let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier(), url = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(sharedContainerIdentifier), path = url.path {
            rootPath = path as NSString
        } else {
            log.error("Unable to find the shared container. Defaulting profile location to ~/Documents instead.")
            rootPath = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)[0]) as NSString
        }

        super.init(rootPath: rootPath.stringByAppendingPathComponent(profileDirName))
    }
}

class CommandStoringSyncDelegate: SyncDelegate {
    let profile: Profile

    init() {
        profile = BrowserProfile(localName: "profile", app: nil)
    }

    func displaySentTabForURL(URL: NSURL, title: String) {
        let item = ShareItem(url: URL.absoluteString, title: title, favicon: nil)
        self.profile.queue.addToQueue(item)
    }
}

/**
 * This exists because the Sync code is extension-safe, and thus doesn't get
 * direct access to UIApplication.sharedApplication, which it would need to
 * display a notification.
 * This will also likely be the extension point for wipes, resets, and
 * getting access to data sources during a sync.
 */

let TabSendURLKey = "TabSendURL"
let TabSendTitleKey = "TabSendTitle"
let TabSendCategory = "TabSendCategory"

enum SentTabAction: String {
    case View = "TabSendViewAction"
    case Bookmark = "TabSendBookmarkAction"
    case ReadingList = "TabSendReadingListAction"
}

class BrowserProfileSyncDelegate: SyncDelegate {
    let app: UIApplication

    init(app: UIApplication) {
        self.app = app
    }

    // SyncDelegate
    func displaySentTabForURL(URL: NSURL, title: String) {
        // check to see what the current notification settings are and only try and send a notification if
        // the user has agreed to them
        if let currentSettings = app.currentUserNotificationSettings() {
            if currentSettings.types.rawValue & UIUserNotificationType.Alert.rawValue != 0 {
                if Logger.logPII {
                    log.info("Displaying notification for URL \(URL.absoluteString)")
                }

                let notification = UILocalNotification()
                notification.fireDate = NSDate()
                notification.timeZone = NSTimeZone.defaultTimeZone()
                notification.alertBody = String(format: NSLocalizedString("New tab: %@: %@", comment:"New tab [title] [url]"), title, URL.absoluteString)
                notification.userInfo = [TabSendURLKey: URL.absoluteString, TabSendTitleKey: title]
                notification.alertAction = nil
                notification.category = TabSendCategory

                app.presentLocalNotificationNow(notification)
            }
        }
    }
}

/**
 * A Profile manages access to the user's data.
 */
protocol Profile: class {
    var bookmarks: protocol<BookmarksModelFactorySource, ShareToDestination, SyncableBookmarks, LocalItemSource, MirrorItemSource> { get }
    // var favicons: Favicons { get }
    var prefs: Prefs { get }
    var queue: TabQueue { get }
    var searchEngines: SearchEngines { get }
    var files: FileAccessor { get }
    var history: protocol<BrowserHistory, SyncableHistory, ResettableSyncStorage> { get }
    var favicons: Favicons { get }
    var readingList: ReadingListService? { get }
    var logins: protocol<BrowserLogins, SyncableLogins, ResettableSyncStorage> { get }
    var certStore: CertStore { get }

    func shutdown()

    // I got really weird EXC_BAD_ACCESS errors on a non-null reference when I made this a getter.
    // Similar to <http://stackoverflow.com/questions/26029317/exc-bad-access-when-indirectly-accessing-inherited-member-in-swift>.
    func localName() -> String

    // URLs and account configuration.
    var accountConfiguration: FirefoxAccountConfiguration { get }

    // Do we have an account at all?
    func hasAccount() -> Bool

    // Do we have an account that (as far as we know) is in a syncable state?
    func hasSyncableAccount() -> Bool

    func getAccount() -> FirefoxAccount?
    func removeAccount()
    func setAccount(account: FirefoxAccount)

    func getClients() -> Deferred<Maybe<[RemoteClient]>>
    func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>>
    func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>>

    func storeTabs(tabs: [RemoteTab]) -> Deferred<Maybe<Int>>

    func sendItems(items: [ShareItem], toClients clients: [RemoteClient])

    var syncManager: SyncManager { get }
}

public class BrowserProfile: Profile {
    private let name: String
    internal let files: FileAccessor

    weak private var app: UIApplication?

    /**
     * N.B., BrowserProfile is used from our extensions, often via a pattern like
     *
     *   BrowserProfile(…).foo.saveSomething(…)
     *
     * This can break if BrowserProfile's initializer does async work that
     * subsequently — and asynchronously — expects the profile to stick around:
     * see Bug 1218833. Be sure to only perform synchronous actions here.
     */
    init(localName: String, app: UIApplication?, clear: Bool = false) {
        log.debug("Initing profile \(localName) on thread \(NSThread.currentThread()).")
        self.name = localName
        self.files = ProfileFileAccessor(localName: localName)
        self.app = app

        if clear {
            do {
                try NSFileManager.defaultManager().removeItemAtPath(self.files.rootPath as String)
            } catch {
                log.info("Cannot clear profile: \(error)")
            }
        }

        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: #selector(BrowserProfile.onLocationChange(_:)), name: NotificationOnLocationChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(BrowserProfile.onProfileDidFinishSyncing(_:)), name: NotificationProfileDidFinishSyncing, object: nil)
        notificationCenter.addObserver(self, selector: #selector(BrowserProfile.onPrivateDataClearedHistory(_:)), name: NotificationPrivateDataClearedHistory, object: nil)


        if let baseBundleIdentifier = AppInfo.baseBundleIdentifier() {
            KeychainWrapper.serviceName = baseBundleIdentifier
        } else {
            log.error("Unable to get the base bundle identifier. Keychain data will not be shared.")
        }

        // If the profile dir doesn't exist yet, this is first run (for this profile).
        if !files.exists("") {
            log.info("New profile. Removing old account metadata.")
            self.removeAccountMetadata()
            self.syncManager.onNewProfile()
            self.removeExistingAuthenticationInfo()
            prefs.clearAll()
        }

        // Always start by needing invalidation.
        // This is the same as self.history.setTopSitesNeedsInvalidation, but without the
        // side-effect of instantiating SQLiteHistory (and thus BrowserDB) on the main thread.
        prefs.setBool(false, forKey: PrefsKeys.KeyTopSitesCacheIsValid)

        // on first run, check if this is the China edition, and set the default position of the homepage button
        if let _ = prefs.boolForKey(PrefsKeys.KeyHomePageButtonIsInMenu) where isChinaEdition {
            prefs.setBool(false, forKey: PrefsKeys.KeyHomePageButtonIsInMenu)
        }

        if isChinaEdition {
            prefs.setString(PrefsDefaults.ChineseHomePageURL, forKey: PrefsKeys.KeyDefaultHomePageURL)
        } else {
            prefs.removeObjectForKey(PrefsKeys.KeyDefaultHomePageURL)
        }
    }

    // Extensions don't have a UIApplication.
    convenience init(localName: String) {
        self.init(localName: localName, app: nil)
    }

    func shutdown() {
        log.debug("Shutting down profile.")

        if self.dbCreated {
            db.forceClose()
        }

        if self.loginsDBCreated {
            loginsDB.forceClose()
        }
    }

    @objc
    func onLocationChange(notification: NSNotification) {
        if let v = notification.userInfo!["visitType"] as? Int,
           let visitType = VisitType(rawValue: v),
           let url = notification.userInfo!["url"] as? NSURL where !isIgnoredURL(url),
           let title = notification.userInfo!["title"] as? NSString {
            // Only record local vists if the change notification originated from a non-private tab
            if !(notification.userInfo!["isPrivate"] as? Bool ?? false) {
                // We don't record a visit if no type was specified -- that means "ignore me".
                let site = Site(url: url.absoluteString, title: title as String)
                let visit = SiteVisit(site: site, date: NSDate.nowMicroseconds(), type: visitType)
                history.addLocalVisit(visit)
            }

            history.setTopSitesNeedsInvalidation()
        } else {
            log.debug("Ignoring navigation.")
        }
    }

    // These selectors run on which ever thread sent the notifications (not the main thread)
    @objc
    func onProfileDidFinishSyncing(notification: NSNotification) {
        history.setTopSitesNeedsInvalidation()
    }

    @objc
    func onPrivateDataClearedHistory(notification: NSNotification) {
        // Immediately invalidate the top sites cache
        history.refreshTopSitesCache()
    }

    deinit {
        log.debug("Deiniting profile \(self.localName).")
        self.syncManager.endTimedSyncs()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationOnLocationChange, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationPrivateDataClearedHistory, object: nil)
    }

    func localName() -> String {
        return name
    }

    lazy var queue: TabQueue = {
        withExtendedLifetime(self.history) {
            return SQLiteQueue(db: self.db)
        }
    }()

    private var dbCreated = false
    var db: BrowserDB {
        struct Singleton {
            static var token: dispatch_once_t = 0
            static var instance: BrowserDB!
        }
        dispatch_once(&Singleton.token) {
            Singleton.instance = BrowserDB(filename: "browser.db", files: self.files)
            self.dbCreated = true
        }
        return Singleton.instance
    }

    /**
     * Favicons, history, and bookmarks are all stored in one intermeshed
     * collection of tables.
     *
     * Any other class that needs to access any one of these should ensure
     * that this is initialized first.
     */
    private lazy var places: protocol<BrowserHistory, Favicons, SyncableHistory, ResettableSyncStorage> = {
        return SQLiteHistory(db: self.db, prefs: self.prefs)!
    }()

    var favicons: Favicons {
        return self.places
    }

    var history: protocol<BrowserHistory, SyncableHistory, ResettableSyncStorage> {
        return self.places
    }

    lazy var bookmarks: protocol<BookmarksModelFactorySource, ShareToDestination, SyncableBookmarks, LocalItemSource, MirrorItemSource> = {
        // Make sure the rest of our tables are initialized before we try to read them!
        // This expression is for side-effects only.
        withExtendedLifetime(self.places) {
            return MergedSQLiteBookmarks(db: self.db)
        }
    }()

    lazy var mirrorBookmarks: protocol<BookmarkBufferStorage, BufferItemSource> = {
        // Yeah, this is lazy. Sorry.
        return self.bookmarks as! MergedSQLiteBookmarks
    }()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs)
    }()

    func makePrefs() -> Prefs {
        return NSUserDefaultsPrefs(prefix: self.localName())
    }

    lazy var prefs: Prefs = {
        return self.makePrefs()
    }()

    lazy var readingList: ReadingListService? = {
        return ReadingListService(profileStoragePath: self.files.rootPath as String)
    }()

    lazy var remoteClientsAndTabs: protocol<RemoteClientsAndTabs, ResettableSyncStorage, AccountRemovalDelegate> = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    lazy var syncManager: SyncManager = {
        return BrowserSyncManager(profile: self)
    }()

    lazy var certStore: CertStore = {
        return CertStore()
    }()

    private func getSyncDelegate() -> SyncDelegate {
        if let app = self.app {
            return BrowserProfileSyncDelegate(app: app)
        }
        return CommandStoringSyncDelegate()
    }

    public func getClients() -> Deferred<Maybe<[RemoteClient]>> {
        return self.syncManager.syncClients()
           >>> { self.remoteClientsAndTabs.getClients() }
    }

    public func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return self.syncManager.syncClientsThenTabs()
           >>> { self.remoteClientsAndTabs.getClientsAndTabs() }
    }

    public func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return self.remoteClientsAndTabs.getClientsAndTabs()
    }

    func storeTabs(tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return self.remoteClientsAndTabs.insertOrUpdateTabs(tabs)
    }

    public func sendItems(items: [ShareItem], toClients clients: [RemoteClient]) {
        let commands = items.map { item in
            SyncCommand.fromShareItem(item, withAction: "displayURI")
        }
        self.remoteClientsAndTabs.insertCommands(commands, forClients: clients) >>> { self.syncManager.syncClients() }
    }

    lazy var logins: protocol<BrowserLogins, SyncableLogins, ResettableSyncStorage> = {
        return SQLiteLogins(db: self.loginsDB)
    }()

    // This is currently only used within the dispatch_once block in loginsDB, so we don't
    // have to worry about races giving us two keys. But if this were ever to be used
    // elsewhere, it'd be unsafe, so we wrap this in a dispatch_once, too.
    private var loginsKey: String? {
        let key = "sqlcipher.key.logins.db"
        struct Singleton {
            static var token: dispatch_once_t = 0
            static var instance: String!
        }
        dispatch_once(&Singleton.token) {
            if KeychainWrapper.hasValueForKey(key) {
                let value = KeychainWrapper.stringForKey(key)
                Singleton.instance = value
            } else {
                let Length: UInt = 256
                let secret = Bytes.generateRandomBytes(Length).base64EncodedString
                KeychainWrapper.setString(secret, forKey: key)
                Singleton.instance = secret
            }
        }
        return Singleton.instance
    }

    private var loginsDBCreated = false
    private lazy var loginsDB: BrowserDB = {
        struct Singleton {
            static var token: dispatch_once_t = 0
            static var instance: BrowserDB!
        }
        dispatch_once(&Singleton.token) {
            Singleton.instance = BrowserDB(filename: "logins.db", secretKey: self.loginsKey, files: self.files)
            self.loginsDBCreated = true
        }
        return Singleton.instance
    }()

    var isChinaEdition: Bool {
        let locale = NSLocale.currentLocale()
        return prefs.boolForKey("useChinaSyncService") ?? (locale.localeIdentifier == "zh_CN")
    }

    var accountConfiguration: FirefoxAccountConfiguration {
        if isChinaEdition {
            return ChinaEditionFirefoxAccountConfiguration()
        }
        return ProductionFirefoxAccountConfiguration()
    }

    private lazy var account: FirefoxAccount? = {
        if let dictionary = KeychainWrapper.objectForKey(self.name + ".account") as? [String: AnyObject] {
            return FirefoxAccount.fromDictionary(dictionary)
        }
        return nil
    }()

    func hasAccount() -> Bool {
        return account != nil
    }

    func hasSyncableAccount() -> Bool {
        return account?.actionNeeded == FxAActionNeeded.None
    }

    func getAccount() -> FirefoxAccount? {
        return account
    }

    func removeAccountMetadata() {
        self.prefs.removeObjectForKey(PrefsKeys.KeyLastRemoteTabSyncTime)
        KeychainWrapper.removeObjectForKey(self.name + ".account")
    }

    func removeExistingAuthenticationInfo() {
        KeychainWrapper.setAuthenticationInfo(nil)
    }

    func removeAccount() {
        let old = self.account
        removeAccountMetadata()
        self.account = nil

        // Tell any observers that our account has changed.
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationFirefoxAccountChanged, object: nil)

        // Trigger cleanup. Pass in the account in case we want to try to remove
        // client-specific data from the server.
        self.syncManager.onRemovedAccount(old)

        // Deregister for remote notifications.
        app?.unregisterForRemoteNotifications()
    }

    func setAccount(account: FirefoxAccount) {
        KeychainWrapper.setObject(account.asDictionary(), forKey: name + ".account")
        self.account = account

        // register for notifications for the account
        registerForNotifications()

        // tell any observers that our account has changed
        let userInfo = [NotificationUserInfoKeyHasSyncableAccount: hasSyncableAccount()]
        NSNotificationCenter.defaultCenter().postNotificationName(NotificationFirefoxAccountChanged, object: nil, userInfo: userInfo)

        self.syncManager.onAddedAccount()
    }

    func registerForNotifications() {
        let viewAction = UIMutableUserNotificationAction()
        viewAction.identifier = SentTabAction.View.rawValue
        viewAction.title = NSLocalizedString("View", comment: "View a URL - https://bugzilla.mozilla.org/attachment.cgi?id=8624438, https://bug1157303.bugzilla.mozilla.org/attachment.cgi?id=8624440")
        viewAction.activationMode = UIUserNotificationActivationMode.Foreground
        viewAction.destructive = false
        viewAction.authenticationRequired = false

        let bookmarkAction = UIMutableUserNotificationAction()
        bookmarkAction.identifier = SentTabAction.Bookmark.rawValue
        bookmarkAction.title = NSLocalizedString("Bookmark", comment: "Bookmark a URL - https://bugzilla.mozilla.org/attachment.cgi?id=8624438, https://bug1157303.bugzilla.mozilla.org/attachment.cgi?id=8624440")
        bookmarkAction.activationMode = UIUserNotificationActivationMode.Foreground
        bookmarkAction.destructive = false
        bookmarkAction.authenticationRequired = false

        let readingListAction = UIMutableUserNotificationAction()
        readingListAction.identifier = SentTabAction.ReadingList.rawValue
        readingListAction.title = NSLocalizedString("Add to Reading List", comment: "Add URL to the reading list - https://bugzilla.mozilla.org/attachment.cgi?id=8624438, https://bug1157303.bugzilla.mozilla.org/attachment.cgi?id=8624440")
        readingListAction.activationMode = UIUserNotificationActivationMode.Foreground
        readingListAction.destructive = false
        readingListAction.authenticationRequired = false

        let sentTabsCategory = UIMutableUserNotificationCategory()
        sentTabsCategory.identifier = TabSendCategory
        sentTabsCategory.setActions([readingListAction, bookmarkAction, viewAction], forContext: UIUserNotificationActionContext.Default)

        sentTabsCategory.setActions([bookmarkAction, viewAction], forContext: UIUserNotificationActionContext.Minimal)

        app?.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: UIUserNotificationType.Alert, categories: [sentTabsCategory]))
        app?.registerForRemoteNotifications()
    }

    // Extends NSObject so we can use timers.
    class BrowserSyncManager: NSObject, SyncManager {
        // We shouldn't live beyond our containing BrowserProfile, either in the main app or in
        // an extension.
        // But it's possible that we'll finish a side-effect sync after we've ditched the profile
        // as a whole, so we hold on to our Prefs, potentially for a little while longer. This is
        // safe as a strong reference, because there's no cycle.
        unowned private let profile: BrowserProfile
        private let prefs: Prefs

        let FifteenMinutes = NSTimeInterval(60 * 15)
        let OneMinute = NSTimeInterval(60)

        private var syncTimer: NSTimer? = nil

        private var backgrounded: Bool = true
        func applicationDidEnterBackground() {
            self.backgrounded = true
            self.endTimedSyncs()
        }

        func applicationDidBecomeActive() {
            self.backgrounded = false

            guard self.profile.hasSyncableAccount() else {
                return
            }

            self.beginTimedSyncs()

            // Sync now if it's been more than our threshold.
            let now = NSDate.now()
            let then = self.lastSyncFinishTime ?? 0
            let since = now - then
            log.debug("\(since)msec since last sync.")
            if since > SyncConstants.SyncOnForegroundMinimumDelayMillis {
                self.syncEverythingSoon()
            }
        }

        /**
         * Locking is managed by syncSeveral. Make sure you take and release these
         * whenever you do anything Sync-ey.
         */
        private let syncLock = NSRecursiveLock()

        var isSyncing: Bool {
            syncLock.lock()
            defer { syncLock.unlock() }
            return !(syncReducer?.isFilled ?? true)
        }

        // The dispatch queue for coordinating syncing and resetting the database.
        private let syncQueue = dispatch_queue_create("com.mozilla.firefox.sync", DISPATCH_QUEUE_SERIAL)

        private typealias EngineResults = [(EngineIdentifier, SyncStatus)]
        private typealias EngineTasks = [(EngineIdentifier, SyncFunction)]

        // Used as a task queue for syncing.
        private var syncReducer: AsyncReducer<EngineResults, EngineTasks>?

        private func beginSyncing() {
            notifySyncing(NotificationProfileDidStartSyncing)
        }

        private func endSyncing() {
            syncLock.lock()
            defer { syncLock.unlock() }
            log.info("Ending all queued syncs.")
            notifySyncing(NotificationProfileDidFinishSyncing)
            syncReducer = nil
        }

        private func notifySyncing(notification: String) {
            NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: notification, object: nil))
        }

        init(profile: BrowserProfile) {
            self.profile = profile
            self.prefs = profile.prefs

            super.init()

            let center = NSNotificationCenter.defaultCenter()
            center.addObserver(self, selector: #selector(BrowserSyncManager.onDatabaseWasRecreated(_:)), name: NotificationDatabaseWasRecreated, object: nil)
            center.addObserver(self, selector: #selector(BrowserSyncManager.onLoginDidChange(_:)), name: NotificationDataLoginDidChange, object: nil)
            center.addObserver(self, selector: #selector(BrowserSyncManager.onFinishSyncing(_:)), name: NotificationProfileDidFinishSyncing, object: nil)
            center.addObserver(self, selector: #selector(BrowserSyncManager.onBookmarkBufferValidated(_:)), name: NotificationBookmarkBufferValidated, object: nil)
        }

        func onBookmarkBufferValidated(notification: NSNotification) {
            // We don't send this ad hoc telemetry on the release channel.
            guard AppConstants.BuildChannel != AppBuildChannel.Release else {
                return
            }

            guard profile.prefs.boolForKey("settings.sendUsageData") ?? true else {
                log.debug("Profile isn't sending usage data. Not sending bookmark event.")
                return
            }

            guard let validations = (notification.object as? Box<[String: Bool]>)?.value else {
                log.warning("Notification didn't have validations.")
                return
            }

            let attempt: Int32 = self.prefs.intForKey("bookmarkvalidationattempt") ?? 1
            self.prefs.setInt(attempt + 1, forKey: "bookmarkvalidationattempt")

            // Capture the buffer count ASAP, not in the delayed op, because the merge could wipe it!
            let bufferRows = (self.profile.bookmarks as? MergedSQLiteBookmarks)?.synchronousBufferCount()

            self.doInBackgroundAfter(millis: 300) {
                self.profile.remoteClientsAndTabs.getClientGUIDs() >>== { clients in
                    // We would love to include the version and OS etc. of each remote client,
                    // but we don't store that information. For now, just do a count.
                    let clientCount = clients.count

                    let id = DeviceInfo.clientIdentifier(self.prefs)
                    let ping = makeAdHocBookmarkMergePing(NSBundle.mainBundle(), clientID: id, attempt: attempt, bufferRows: bufferRows, valid: validations, clientCount: clientCount)
                    let payload = ping.toString()

                    log.debug("Payload is: \(payload)")
                    guard let body = payload.dataUsingEncoding(NSUTF8StringEncoding) else {
                        log.debug("Invalid JSON!")
                        return
                    }

                    let url = "https://mozilla-anonymous-sync-metrics.moo.mx/post/bookmarkvalidation".asURL!
                    let request = NSMutableURLRequest(URL: url)
                    request.HTTPMethod = "POST"
                    request.HTTPBody = body
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                    Alamofire.Manager.sharedInstance.request(request).response { (request, response, data, error) in
                        log.debug("Bookmark validation upload response: \(response?.statusCode ?? -1).")
                    }
                }
            }
        }

        deinit {
            // Remove 'em all.
            let center = NSNotificationCenter.defaultCenter()
            center.removeObserver(self, name: NotificationDatabaseWasRecreated, object: nil)
            center.removeObserver(self, name: NotificationDataLoginDidChange, object: nil)
            center.removeObserver(self, name: NotificationProfileDidFinishSyncing, object: nil)
            center.removeObserver(self, name: NotificationBookmarkBufferValidated, object: nil)
        }

        private func handleRecreationOfDatabaseNamed(name: String?) -> Success {
            let loginsCollections = ["passwords"]
            let browserCollections = ["bookmarks", "history", "tabs"]

            switch name ?? "<all>" {
            case "<all>":
                return self.locallyResetCollections(loginsCollections + browserCollections)
            case "logins.db":
                return self.locallyResetCollections(loginsCollections)
            case "browser.db":
                return self.locallyResetCollections(browserCollections)
            default:
                log.debug("Unknown database \(name).")
                return succeed()
            }
        }

        func doInBackgroundAfter(millis millis: Int64, _ block: dispatch_block_t) {
            let delay = millis * Int64(NSEC_PER_MSEC)
            let when = dispatch_time(DISPATCH_TIME_NOW, delay)
            let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
            dispatch_after(when, queue, block)
        }

        @objc
        func onDatabaseWasRecreated(notification: NSNotification) {
            log.debug("Database was recreated.")
            let name = notification.object as? String
            log.debug("Database was \(name).")

            // We run this in the background after a few hundred milliseconds;
            // it doesn't really matter when it runs, so long as it doesn't
            // happen in the middle of a sync.

            let resetDatabase = {
                return self.handleRecreationOfDatabaseNamed(name) >>== {
                    log.debug("Reset of \(name) done")
                }
            }

            self.doInBackgroundAfter(millis: 300) {
                self.syncLock.lock()
                defer { self.syncLock.unlock() }
                // If we're syncing already, then wait for sync to end,
                // then reset the database on the same serial queue.
                if let reducer = self.syncReducer where !reducer.isFilled {
                    reducer.terminal.upon { _ in
                        dispatch_async(self.syncQueue, resetDatabase)
                    }
                } else {
                    // Otherwise, reset the database on the sync queue now
                    // Sync can't start while this is still going on.
                    dispatch_async(self.syncQueue, resetDatabase)
                }
            }
        }

        // Simple in-memory rate limiting.
        var lastTriggeredLoginSync: Timestamp = 0
        @objc func onLoginDidChange(notification: NSNotification) {
            log.debug("Login did change.")
            if (NSDate.now() - lastTriggeredLoginSync) > OneMinuteInMilliseconds {
                lastTriggeredLoginSync = NSDate.now()

                // Give it a few seconds.
                let when: dispatch_time_t = dispatch_time(DISPATCH_TIME_NOW, SyncConstants.SyncDelayTriggered)

                // Trigger on the main queue. The bulk of the sync work runs in the background.
                let greenLight = self.greenLight()
                dispatch_after(when, dispatch_get_main_queue()) {
                    if greenLight() {
                        self.syncLogins()
                    }
                }
            }
        }

        var lastSyncFinishTime: Timestamp? {
            get {
                return self.prefs.timestampForKey(PrefsKeys.KeyLastSyncFinishTime)
            }

            set(value) {
                if let value = value {
                    self.prefs.setTimestamp(value, forKey: PrefsKeys.KeyLastSyncFinishTime)
                } else {
                    self.prefs.removeObjectForKey(PrefsKeys.KeyLastSyncFinishTime)
                }
            }
        }

        @objc func onFinishSyncing(notification: NSNotification) {
            self.lastSyncFinishTime = NSDate.now()
        }

        var prefsForSync: Prefs {
            return self.prefs.branch("sync")
        }

        func onAddedAccount() -> Success {
            // Only sync if we're green lit. This makes sure that we don't sync unverified accounts.
            guard self.profile.hasSyncableAccount() else { return succeed() }

            self.beginTimedSyncs()
            return self.syncEverything()
        }

        func locallyResetCollections(collections: [String]) -> Success {
            return walk(collections, f: self.locallyResetCollection)
        }

        func locallyResetCollection(collection: String) -> Success {
            switch collection {
            case "bookmarks":
                return BufferingBookmarksSynchronizer.resetSynchronizerWithStorage(self.profile.bookmarks, basePrefs: self.prefsForSync, collection: "bookmarks")

            case "clients":
                fallthrough
            case "tabs":
                // Because clients and tabs share storage, and thus we wipe data for both if we reset either,
                // we reset the prefs for both at the same time.
                return TabsSynchronizer.resetClientsAndTabsWithStorage(self.profile.remoteClientsAndTabs, basePrefs: self.prefsForSync)

            case "history":
                return HistorySynchronizer.resetSynchronizerWithStorage(self.profile.history, basePrefs: self.prefsForSync, collection: "history")
            case "passwords":
                return LoginsSynchronizer.resetSynchronizerWithStorage(self.profile.logins, basePrefs: self.prefsForSync, collection: "passwords")

            case "forms":
                log.debug("Requested reset for forms, but this client doesn't sync them yet.")
                return succeed()
            case "addons":
                log.debug("Requested reset for addons, but this client doesn't sync them.")
                return succeed()
            case "prefs":
                log.debug("Requested reset for prefs, but this client doesn't sync them.")
                return succeed()
            default:
                log.warning("Asked to reset collection \(collection), which we don't know about.")
                return succeed()
            }
        }

        func onNewProfile() {
            SyncStateMachine.clearStateFromPrefs(self.prefsForSync)
        }

        func onRemovedAccount(account: FirefoxAccount?) -> Success {
            let profile = self.profile

            // Run these in order, because they might write to the same DB!
            let remove = [
                profile.history.onRemovedAccount,
                profile.remoteClientsAndTabs.onRemovedAccount,
                profile.logins.onRemovedAccount,
                profile.bookmarks.onRemovedAccount,
            ]

            let clearPrefs: () -> Success = {
                withExtendedLifetime(self) {
                    // Clear prefs after we're done clearing everything else -- just in case
                    // one of them needs the prefs and we race. Clear regardless of success
                    // or failure.

                    // This will remove keys from the Keychain if they exist, as well
                    // as wiping the Sync prefs.
                    SyncStateMachine.clearStateFromPrefs(self.prefsForSync)
                }
                return succeed()
            }

            return accumulate(remove) >>> clearPrefs
        }

        private func repeatingTimerAtInterval(interval: NSTimeInterval, selector: Selector) -> NSTimer {
            return NSTimer.scheduledTimerWithTimeInterval(interval, target: self, selector: selector, userInfo: nil, repeats: true)
        }

        func beginTimedSyncs() {
            if self.syncTimer != nil {
                log.debug("Already running sync timer.")
                return
            }

            let interval = FifteenMinutes
            let selector = #selector(BrowserSyncManager.syncOnTimer)
            log.debug("Starting sync timer.")
            self.syncTimer = repeatingTimerAtInterval(interval, selector: selector)
        }

        /**
         * The caller is responsible for calling this on the same thread on which it called
         * beginTimedSyncs.
         */
        func endTimedSyncs() {
            if let t = self.syncTimer {
                log.debug("Stopping sync timer.")
                self.syncTimer = nil
                t.invalidate()
            }
        }

        private func syncClientsWithDelegate(delegate: SyncDelegate, prefs: Prefs, ready: Ready) -> SyncResult {
            log.debug("Syncing clients to storage.")
            let clientSynchronizer = ready.synchronizer(ClientsSynchronizer.self, delegate: delegate, prefs: prefs)
            return clientSynchronizer.synchronizeLocalClients(self.profile.remoteClientsAndTabs, withServer: ready.client, info: ready.info)
        }

        private func syncTabsWithDelegate(delegate: SyncDelegate, prefs: Prefs, ready: Ready) -> SyncResult {
            let storage = self.profile.remoteClientsAndTabs
            let tabSynchronizer = ready.synchronizer(TabsSynchronizer.self, delegate: delegate, prefs: prefs)
            return tabSynchronizer.synchronizeLocalTabs(storage, withServer: ready.client, info: ready.info)
        }

        private func syncHistoryWithDelegate(delegate: SyncDelegate, prefs: Prefs, ready: Ready) -> SyncResult {
            log.debug("Syncing history to storage.")
            let historySynchronizer = ready.synchronizer(HistorySynchronizer.self, delegate: delegate, prefs: prefs)
            return historySynchronizer.synchronizeLocalHistory(self.profile.history, withServer: ready.client, info: ready.info, greenLight: self.greenLight())
        }

        private func syncLoginsWithDelegate(delegate: SyncDelegate, prefs: Prefs, ready: Ready) -> SyncResult {
            log.debug("Syncing logins to storage.")
            let loginsSynchronizer = ready.synchronizer(LoginsSynchronizer.self, delegate: delegate, prefs: prefs)
            return loginsSynchronizer.synchronizeLocalLogins(self.profile.logins, withServer: ready.client, info: ready.info)
        }

        private func mirrorBookmarksWithDelegate(delegate: SyncDelegate, prefs: Prefs, ready: Ready) -> SyncResult {
            log.debug("Synchronizing server bookmarks to storage.")
            let bookmarksMirrorer = ready.synchronizer(BufferingBookmarksSynchronizer.self, delegate: delegate, prefs: prefs)
            return bookmarksMirrorer.synchronizeBookmarksToStorage(self.profile.bookmarks, usingBuffer: self.profile.mirrorBookmarks, withServer: ready.client, info: ready.info, greenLight: self.greenLight())
        }

        func takeActionsOnEngineStateChanges<T: EngineStateChanges>(changes: T) -> Deferred<Maybe<T>> {
            var needReset = Set<String>(changes.collectionsThatNeedLocalReset())
            needReset.unionInPlace(changes.enginesDisabled())
            needReset.unionInPlace(changes.enginesEnabled())
            if needReset.isEmpty {
                log.debug("No collections need reset. Moving on.")
                return deferMaybe(changes)
            }

            // needReset needs at most one of clients and tabs, because we reset them
            // both if either needs reset. This is strictly an optimization to avoid
            // doing duplicate work.
            if needReset.contains("clients") {
                if needReset.remove("tabs") != nil {
                    log.debug("Already resetting clients (and tabs); not bothering to also reset tabs again.")
                }
            }

            return walk(Array(needReset), f: self.locallyResetCollection)
               >>> effect(changes.clearLocalCommands)
               >>> always(changes)
        }

        /**
         * Runs the single provided synchronization function and returns its status.
         */
        private func sync(label: EngineIdentifier, function: SyncFunction) -> SyncResult {
            return syncSeveral([(label, function)]) >>== { statuses in
                let status = statuses.find { label == $0.0 }?.1
                return deferMaybe(status ?? .NotStarted(.Unknown))
            }
        }

        /**
         * Convenience method for syncSeveral([(EngineIdentifier, SyncFunction)])
         */
        private func syncSeveral(synchronizers: (EngineIdentifier, SyncFunction)...) -> Deferred<Maybe<[(EngineIdentifier, SyncStatus)]>> {
            return syncSeveral(synchronizers)
        }

        /**
         * Runs each of the provided synchronization functions with the same inputs.
         * Returns an array of IDs and SyncStatuses at least length as the input.
         * The statuses returned will be a superset of the ones that are requested here.
         * While a sync is ongoing, each engine from successive calls to this method will only be called once.
         */
        private func syncSeveral(synchronizers: [(EngineIdentifier, SyncFunction)]) -> Deferred<Maybe<[(EngineIdentifier, SyncStatus)]>> {
            syncLock.lock()
            defer { syncLock.unlock() }

            if (!isSyncing) {
                // A sync isn't already going on, so start another one.
                let reducer = AsyncReducer<EngineResults, EngineTasks>(initialValue: [], queue: syncQueue) { (statuses, synchronizers)  in
                    let done = Set(statuses.map { $0.0 })
                    let remaining = synchronizers.filter { !done.contains($0.0) }
                    if remaining.isEmpty {
                        log.info("Nothing left to sync")
                        return deferMaybe(statuses)
                    }

                    return self.syncWith(remaining) >>== { deferMaybe(statuses + $0) }
                }
                reducer.terminal >>> self.endSyncing

                // The actual work of synchronizing doesn't start until we append
                // the synchronizers to the reducer below.
                self.syncReducer = reducer
                self.beginSyncing()
            }

            do {
                return try syncReducer!.append(synchronizers)
            } catch let error {
                log.error("Synchronizers appended after sync was finished. This is a bug. \(error)")
                let statuses = synchronizers.map {
                    ($0.0, SyncStatus.NotStarted(.Unknown))
                }
                return deferMaybe(statuses)
            }
        }

        // This SHOULD NOT be called directly: use syncSeveral instead.
        private func syncWith(synchronizers: [(EngineIdentifier, SyncFunction)]) -> Deferred<Maybe<[(EngineIdentifier, SyncStatus)]>> {
            guard let account = self.profile.account else {
                log.info("No account to sync with.")
                let statuses = synchronizers.map {
                    ($0.0, SyncStatus.NotStarted(.NoAccount))
                }
                return deferMaybe(statuses)
            }

            log.info("Syncing \(synchronizers.map { $0.0 })")
            let authState = account.syncAuthState
            let delegate = self.profile.getSyncDelegate()
            let readyDeferred = SyncStateMachine(prefs: self.prefsForSync).toReady(authState)

            let function: (SyncDelegate, Prefs, Ready) -> Deferred<Maybe<[EngineStatus]>> = { delegate, syncPrefs, ready in
                let thunks = synchronizers.map { (i, f) in
                    return { () -> Deferred<Maybe<EngineStatus>> in
                        log.debug("Syncing \(i)…")
                        return f(delegate, syncPrefs, ready) >>== { deferMaybe((i, $0)) }
                    }
                }
                return accumulate(thunks)
            }

            return readyDeferred >>== self.takeActionsOnEngineStateChanges >>== { ready in
                function(delegate, self.prefsForSync, ready)
            }
        }

        func syncEverything() -> Success {
            return self.syncSeveral(
                ("clients", self.syncClientsWithDelegate),
                ("tabs", self.syncTabsWithDelegate),
                ("logins", self.syncLoginsWithDelegate),
                ("bookmarks", self.mirrorBookmarksWithDelegate),
                ("history", self.syncHistoryWithDelegate)
            ) >>> succeed
        }

        func syncEverythingSoon() {
            self.doInBackgroundAfter(millis: SyncConstants.SyncOnForegroundAfterMillis) {
                log.debug("Running delayed startup sync.")
                self.syncEverything()
            }
        }

        @objc func syncOnTimer() {
            self.syncEverything()
        }

        func hasSyncedHistory() -> Deferred<Maybe<Bool>> {
            return self.profile.history.hasSyncedHistory()
        }

        func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
            return self.profile.logins.hasSyncedLogins()
        }

        func syncClients() -> SyncResult {
            // TODO: recognize .NotStarted.
            return self.sync("clients", function: syncClientsWithDelegate)
        }

        func syncClientsThenTabs() -> SyncResult {
            return self.syncSeveral(
                ("clients", self.syncClientsWithDelegate),
                ("tabs", self.syncTabsWithDelegate)
            ) >>== { statuses in
                let status = statuses.find { "tabs" == $0.0 }
                return deferMaybe(status!.1)
            }
        }

        func syncLogins() -> SyncResult {
            return self.sync("logins", function: syncLoginsWithDelegate)
        }

        func syncHistory() -> SyncResult {
            // TODO: recognize .NotStarted.
            return self.sync("history", function: syncHistoryWithDelegate)
        }

        func mirrorBookmarks() -> SyncResult {
            return self.sync("bookmarks", function: mirrorBookmarksWithDelegate)
        }

        /**
         * Return a thunk that continues to return true so long as an ongoing sync
         * should continue.
         */
        func greenLight() -> () -> Bool {
            let start = NSDate.now()

            // Give it one minute to run before we stop.
            let stopBy = start + OneMinuteInMilliseconds
            log.debug("Checking green light. Backgrounded: \(self.backgrounded).")
            return {
                NSDate.now() < stopBy &&
                self.profile.hasSyncableAccount()
            }
        }
    }
}
