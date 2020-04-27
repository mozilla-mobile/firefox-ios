/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

// IMPORTANT!: Please take into consideration when adding new imports to
// this file that it is utilized by external components besides the core
// application (i.e. App Extensions). Introducing new dependencies here
// may have unintended negative consequences for App Extensions such as
// increased startup times which may lead to termination by the OS.
import Account
import Shared
import Storage
import Sync
import XCGLogger
import SwiftKeychainWrapper

// Import these dependencies ONLY for the main `Client` application target.
#if MOZ_TARGET_CLIENT
    import SwiftyJSON
    import SyncTelemetry
#endif

private let log = Logger.syncLogger

public let ProfileRemoteTabsSyncDelay: TimeInterval = 0.1

public protocol SyncManager {
    var isSyncing: Bool { get }
    var lastSyncFinishTime: Timestamp? { get set }
    var syncDisplayState: SyncDisplayState? { get }

    func hasSyncedHistory() -> Deferred<Maybe<Bool>>
    func hasSyncedLogins() -> Deferred<Maybe<Bool>>

    func syncClients() -> SyncResult
    func syncClientsThenTabs() -> SyncResult
    func syncHistory() -> SyncResult
    func syncLogins() -> SyncResult
    func syncBookmarks() -> SyncResult
    @discardableResult func syncEverything(why: SyncReason) -> Success
    func syncNamedCollections(why: SyncReason, names: [String]) -> Success

    // The simplest possible approach.
    func beginTimedSyncs()
    func endTimedSyncs()
    func applicationDidEnterBackground()
    func applicationDidBecomeActive()

    func onNewProfile()
    @discardableResult func onRemovedAccount() -> Success
    @discardableResult func onAddedAccount() -> Success
}

typealias SyncFunction = (SyncDelegate, Prefs, Ready, SyncReason) -> SyncResult

class ProfileFileAccessor: FileAccessor {
    convenience init(profile: Profile) {
        self.init(localName: profile.localName())
    }

    init(localName: String) {
        let profileDirName = "profile.\(localName)"

        // Bug 1147262: First option is for device, second is for simulator.
        var rootPath: String
        let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedContainerIdentifier) {
            rootPath = url.path
        } else {
            log.error("Unable to find the shared container. Defaulting profile location to ~/Documents instead.")
            rootPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        }

        super.init(rootPath: URL(fileURLWithPath: rootPath).appendingPathComponent(profileDirName).path)
    }
}

class CommandStoringSyncDelegate: SyncDelegate {
    let profile: Profile

    init(profile: Profile) {
        self.profile = profile
    }

    public func displaySentTab(for url: URL, title: String, from deviceName: String?) {
        let item = ShareItem(url: url.absoluteString, title: title, favicon: nil)
        _ = self.profile.queue.addToQueue(item)
    }
}

/**
 * A Profile manages access to the user's data.
 */
protocol Profile: AnyObject {
    var places: RustPlaces { get }
    var prefs: Prefs { get }
    var queue: TabQueue { get }
    var searchEngines: SearchEngines { get }
    var files: FileAccessor { get }
    var history: BrowserHistory & SyncableHistory & ResettableSyncStorage { get }
    var metadata: Metadata { get }
    var recommendations: HistoryRecommendations { get }
    var favicons: Favicons { get }
    var logins: RustLogins { get }
    var certStore: CertStore { get }
    var recentlyClosedTabs: ClosedTabsStore { get }
    var panelDataObservers: PanelDataObservers { get }

    #if !MOZ_TARGET_NOTIFICATIONSERVICE
        var readingList: ReadingList { get }
    #endif

    var isShutdown: Bool { get }

    /// WARNING: Only to be called as part of the app lifecycle from the AppDelegate
    /// or from App Extension code.
    func _shutdown()

    /// WARNING: Only to be called as part of the app lifecycle from the AppDelegate
    /// or from App Extension code.
    func _reopen()

    // I got really weird EXC_BAD_ACCESS errors on a non-null reference when I made this a getter.
    // Similar to <http://stackoverflow.com/questions/26029317/exc-bad-access-when-indirectly-accessing-inherited-member-in-swift>.
    func localName() -> String

    // Do we have an account at all?
    func hasAccount() -> Bool

    // Do we have an account that (as far as we know) is in a syncable state?
    func hasSyncableAccount() -> Bool

    var rustFxA: RustFirefoxAccounts { get }

    func removeAccount()

    func getClients() -> Deferred<Maybe<[RemoteClient]>>
    func getCachedClients()-> Deferred<Maybe<[RemoteClient]>>
    func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>>
    func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>>

    func cleanupHistoryIfNeeded()

    @discardableResult func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>>

    func sendItem(_ item: ShareItem, toDevices devices: [RemoteDevice]) -> Success

    var syncManager: SyncManager! { get }
}

fileprivate let PrefKeyClientID = "PrefKeyClientID"
extension Profile {
    var clientID: String {
        let clientID: String
        if let id = prefs.stringForKey(PrefKeyClientID) {
            clientID = id
        } else {
            clientID = UUID().uuidString
            prefs.setString(clientID, forKey: PrefKeyClientID)
        }
        return clientID
    }
    
    // Returns false for when there is no account available and true if the account
    // is not verified or has no password attached to it
//    var accountNeedsUserAction: Bool {
//        guard let account = self.getAccount() else { return false }
//        let actionNeeded = account.actionNeeded
//        let needsVerification = actionNeeded == FxAActionNeeded.needsPassword || actionNeeded == FxAActionNeeded.needsVerification
//
//        return needsVerification
//    }
}

open class BrowserProfile: Profile {
    fileprivate let name: String
    fileprivate let keychain: KeychainWrapper
    var isShutdown = false

    internal let files: FileAccessor

    let db: BrowserDB
    let readingListDB: BrowserDB
    var syncManager: SyncManager!

    private static var loginsKey: String {
        let key = "sqlcipher.key.logins.db"
        let keychain = KeychainWrapper.sharedAppContainerKeychain
        keychain.ensureStringItemAccessibility(.afterFirstUnlock, forKey: key)
        if keychain.hasValue(forKey: key), let secret = keychain.string(forKey: key) {
            return secret
        }

        let Length: UInt = 256
        let secret = Bytes.generateRandomBytes(Length).base64EncodedString
        keychain.set(secret, forKey: key, withAccessibility: .afterFirstUnlock)
        return secret
    }

    var syncDelegate: SyncDelegate?

    /**
     * N.B., BrowserProfile is used from our extensions, often via a pattern like
     *
     *   BrowserProfile(…).foo.saveSomething(…)
     *
     * This can break if BrowserProfile's initializer does async work that
     * subsequently — and asynchronously — expects the profile to stick around:
     * see Bug 1218833. Be sure to only perform synchronous actions here.
     *
     * A SyncDelegate can be provided in this initializer, or once the profile is initialized.
     * However, if we provide it here, it's assumed that we're initializing it from the application.
     */
    init(localName: String, syncDelegate: SyncDelegate? = nil, clear: Bool = false) {
        log.debug("Initing profile \(localName) on thread \(Thread.current).")
        self.name = localName
        self.files = ProfileFileAccessor(localName: localName)
        self.keychain = KeychainWrapper.sharedAppContainerKeychain
        self.syncDelegate = syncDelegate

        if clear {
            do {
                // Remove the contents of the directory…
                try self.files.removeFilesInDirectory()
                // …then remove the directory itself.
                try self.files.remove("")
            } catch {
                log.info("Cannot clear profile: \(error)")
            }
        }

        // If the profile dir doesn't exist yet, this is first run (for this profile). The check is made here
        // since the DB handles will create new DBs under the new profile folder.
        let isNewProfile = !files.exists("")

        // Set up our database handles.
        self.db = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        self.readingListDB = BrowserDB(filename: "ReadingList.db", schema: ReadingListSchema(), files: files)

        if isNewProfile {
            log.info("New profile. Removing old Keychain/Prefs data.")
            KeychainWrapper.wipeKeychain()
            prefs.clearAll()
        }

        // Log SQLite compile_options.
        // db.sqliteCompileOptions() >>== { compileOptions in
        //     log.debug("SQLite compile_options:\n\(compileOptions.joined(separator: "\n"))")
        // }

        // Set up logging from Rust.
        if !RustLog.shared.tryEnable({ (level, tag, message) -> Bool in
            let logString = "[RUST][\(tag ?? "no-tag")] \(message)"

            switch level {
            case .trace:
                if Logger.logPII {
                    log.verbose(logString)
                }
            case .debug:
                log.debug(logString)
            case .info:
                log.info(logString)
            case .warn:
                log.warning(logString)
            case .error:
                Sentry.shared.sendWithStacktrace(message: logString, tag: .rustLog, severity: .error)
                log.error(logString)
            }

            return true
        }) {
            log.error("ERROR: Unable to enable logging from Rust")
        }

        // By default, filter logging from Rust below `.info` level.
        try? RustLog.shared.setLevelFilter(filter: .info)

        // This has to happen prior to the databases being opened, because opening them can trigger
        // events to which the SyncManager listens.
        self.syncManager = BrowserSyncManager(profile: self)

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self, selector: #selector(onLocationChange), name: .OnLocationChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(onPageMetadataFetched), name: .OnPageMetadataFetched, object: nil)

        // Always start by needing invalidation.
        // This is the same as self.history.setTopSitesNeedsInvalidation, but without the
        // side-effect of instantiating SQLiteHistory (and thus BrowserDB) on the main thread.
        prefs.setBool(false, forKey: PrefsKeys.KeyTopSitesCacheIsValid)

        if AppInfo.isChinaEdition {

            // Set the default homepage.
            prefs.setString(PrefsDefaults.ChineseHomePageURL, forKey: PrefsKeys.KeyDefaultHomePageURL)

            if prefs.stringForKey(PrefsKeys.KeyNewTab) == nil {
                prefs.setString(PrefsDefaults.ChineseHomePageURL, forKey: PrefsKeys.NewTabCustomUrlPrefKey)
                prefs.setString(PrefsDefaults.ChineseNewTabDefault, forKey: PrefsKeys.KeyNewTab)
            }

            if prefs.stringForKey(PrefsKeys.HomePageTab) == nil {
                prefs.setString(PrefsDefaults.ChineseHomePageURL, forKey: PrefsKeys.HomeButtonHomePageURL)
                prefs.setString(PrefsDefaults.ChineseNewTabDefault, forKey: PrefsKeys.HomePageTab)
            }
        } else {
            // Remove the default homepage. This does not change the user's preference,
            // just the behaviour when there is no homepage.
            prefs.removeObjectForKey(PrefsKeys.KeyDefaultHomePageURL)
        }

        // Hide the "__leanplum.sqlite" file in the documents directory.
        if var leanplumFile = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("__leanplum.sqlite"), FileManager.default.fileExists(atPath: leanplumFile.path) {
            let isHidden = (try? leanplumFile.resourceValues(forKeys: [.isHiddenKey]))?.isHidden ?? false
            if !isHidden {
                var resourceValues = URLResourceValues()
                resourceValues.isHidden = true
                try? leanplumFile.setResourceValues(resourceValues)
            }
        }

        // Create the "Downloads" folder in the documents directory.
        if let downloadsPath = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Downloads").path {
            try? FileManager.default.createDirectory(atPath: downloadsPath, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func _reopen() {
        log.debug("Reopening profile.")
        isShutdown = false

        if !places.isOpen && !RustFirefoxAccounts.shared.accountManager.hasAccount() {
            places.migrateBookmarksIfNeeded(fromBrowserDB: db)
        }

        db.reopenIfClosed()
        _ = logins.reopenIfClosed()
        _ = places.reopenIfClosed()
    }

    func _shutdown() {
        log.debug("Shutting down profile.")
        isShutdown = true

        db.forceClose()
        _ = logins.forceClose()
        _ = places.forceClose()
    }

    @objc
    func onLocationChange(notification: NSNotification) {
        if let v = notification.userInfo!["visitType"] as? Int,
           let visitType = VisitType(rawValue: v),
           let url = notification.userInfo!["url"] as? URL, !isIgnoredURL(url),
           let title = notification.userInfo!["title"] as? NSString {
            // Only record local vists if the change notification originated from a non-private tab
            if !(notification.userInfo!["isPrivate"] as? Bool ?? false) {
                // We don't record a visit if no type was specified -- that means "ignore me".
                let site = Site(url: url.absoluteString, title: title as String)
                let visit = SiteVisit(site: site, date: Date.nowMicroseconds(), type: visitType)
                history.addLocalVisit(visit)
            }

            history.setTopSitesNeedsInvalidation()
        } else {
            log.debug("Ignoring navigation.")
        }
    }

    @objc
    func onPageMetadataFetched(notification: NSNotification) {
        let isPrivate = notification.userInfo?["isPrivate"] as? Bool ?? true
        guard !isPrivate else {
            log.debug("Private mode - Ignoring page metadata.")
            return
        }
        guard let pageURL = notification.userInfo?["tabURL"] as? URL,
              let pageMetadata = notification.userInfo?["pageMetadata"] as? PageMetadata else {
            log.debug("Metadata notification doesn't contain any metadata!")
            return
        }
        let defaultMetadataTTL: UInt64 = 3 * 24 * 60 * 60 * 1000 // 3 days for the metadata to live
        self.metadata.storeMetadata(pageMetadata, forPageURL: pageURL, expireAt: defaultMetadataTTL + Date.now())
    }

    deinit {
        log.debug("Deiniting profile \(self.localName()).")
        self.syncManager.endTimedSyncs()
    }

    func localName() -> String {
        return name
    }

    lazy var queue: TabQueue = {
        withExtendedLifetime(self.history) {
            return SQLiteQueue(db: self.db)
        }
    }()

    /**
     * Favicons, history, and tabs are all stored in one intermeshed
     * collection of tables.
     *
     * Any other class that needs to access any one of these should ensure
     * that this is initialized first.
     */
    fileprivate lazy var legacyPlaces: BrowserHistory & Favicons & SyncableHistory & ResettableSyncStorage & HistoryRecommendations  = {
        return SQLiteHistory(db: self.db, prefs: self.prefs)
    }()

    var favicons: Favicons {
        return self.legacyPlaces
    }

    var history: BrowserHistory & SyncableHistory & ResettableSyncStorage {
        return self.legacyPlaces
    }

    lazy var panelDataObservers: PanelDataObservers = {
        return PanelDataObservers(profile: self)
    }()

    lazy var metadata: Metadata = {
        return SQLiteMetadata(db: self.db)
    }()

    var recommendations: HistoryRecommendations {
        return self.legacyPlaces
    }

    lazy var placesDbPath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("places.db").path

    lazy var places = RustPlaces(databasePath: placesDbPath)

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs, files: self.files)
    }()

    func makePrefs() -> Prefs {
        return NSUserDefaultsPrefs(prefix: self.localName())
    }

    lazy var prefs: Prefs = {
        return self.makePrefs()
    }()

    lazy var readingList: ReadingList = {
        return SQLiteReadingList(db: self.readingListDB)
    }()

    lazy var remoteClientsAndTabs: RemoteClientsAndTabs & ResettableSyncStorage & AccountRemovalDelegate & RemoteDevices = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    lazy var certStore: CertStore = {
        return CertStore()
    }()

    lazy var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()

    open func getSyncDelegate() -> SyncDelegate {
        return syncDelegate ?? CommandStoringSyncDelegate(profile: self)
    }

    public func getClients() -> Deferred<Maybe<[RemoteClient]>> {
        return self.syncManager.syncClients()
           >>> { self.remoteClientsAndTabs.getClients() }
    }

    public func getCachedClients()-> Deferred<Maybe<[RemoteClient]>> {
        return self.remoteClientsAndTabs.getClients()
    }

    public func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return self.syncManager.syncClientsThenTabs()
           >>> { self.remoteClientsAndTabs.getClientsAndTabs() }
    }

    public func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return self.remoteClientsAndTabs.getClientsAndTabs()
    }

    public func cleanupHistoryIfNeeded() {
        recommendations.cleanupHistoryIfNeeded()
    }

    func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return self.remoteClientsAndTabs.insertOrUpdateTabs(tabs)
    }

    public func sendItem(_ item: ShareItem, toDevices devices: [RemoteDevice]) -> Success {
        guard let constellation = RustFirefoxAccounts.shared.accountManager.deviceConstellation() else {
            return deferMaybe(NoAccountError())
        }
        devices.forEach {
            if let id = $0.id, let title = item.title {
                constellation.sendEventToDevice(targetDeviceId: id, e: .sendTab(title: title, url: item.url))
            }
        }
        return succeed()
    }

    lazy var logins: RustLogins = {
        let databasePath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("logins.db").path

        let salt: String
        let key = "sqlcipher.key.logins.salt"
        let keychain = KeychainWrapper.sharedAppContainerKeychain
        keychain.ensureStringItemAccessibility(.afterFirstUnlock, forKey: key)
        if keychain.hasValue(forKey: key), let val = keychain.string(forKey: key) {
            salt = val
        } else {
            salt = RustLogins.setupPlaintextHeaderAndGetSalt(databasePath: databasePath, encryptionKey: BrowserProfile.loginsKey)
            keychain.set(salt, forKey: key, withAccessibility: .afterFirstUnlock)
        }

        return RustLogins(databasePath: databasePath, encryptionKey: BrowserProfile.loginsKey, salt: salt)
    }()

    func hasAccount() -> Bool {
        return rustFxA.accountManager.hasAccount()
    }

    func hasSyncableAccount() -> Bool {
        return hasAccount() && !rustFxA.accountManager.accountNeedsReauth()
    }

    var rustFxA: RustFirefoxAccounts {
        return RustFirefoxAccounts.shared
    }

    func removeAccount() {
        RustFirefoxAccounts.shared.disconnect()

        // Profile exists in extensions, UIApp is unavailable there, make this code run for the main app only
        if let application = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication {
            application.unregisterForRemoteNotifications()
        }

        // remove Account Metadata
        prefs.removeObjectForKey(PrefsKeys.KeyLastRemoteTabSyncTime)
        keychain.removeAllKeys()

        // Tell any observers that our account has changed.
        NotificationCenter.default.post(name: .FirefoxAccountChanged, object: nil)

        // Trigger cleanup. Pass in the account in case we want to try to remove
        // client-specific data from the server.
        self.syncManager.onRemovedAccount()
    }

    class NoAccountError: MaybeErrorType {
        var description = "No account."
    }

    // Extends NSObject so we can use timers.
    public class BrowserSyncManager: NSObject, SyncManager, CollectionChangedNotifier {
        // We shouldn't live beyond our containing BrowserProfile, either in the main app or in
        // an extension.
        // But it's possible that we'll finish a side-effect sync after we've ditched the profile
        // as a whole, so we hold on to our Prefs, potentially for a little while longer. This is
        // safe as a strong reference, because there's no cycle.
        unowned fileprivate let profile: BrowserProfile
        fileprivate let prefs: Prefs
        fileprivate var constellationStateUpdate: Any?

        let FifteenMinutes = TimeInterval(60 * 15)
        let OneMinute = TimeInterval(60)

        fileprivate var syncTimer: Timer?

        fileprivate var backgrounded: Bool = true
        public func applicationDidEnterBackground() {
            self.backgrounded = true
            self.endTimedSyncs()
        }

        deinit {
            if let c = constellationStateUpdate {
                NotificationCenter.default.removeObserver(c)
            }
        }

        public func applicationDidBecomeActive() {
            self.backgrounded = false

            guard self.profile.hasSyncableAccount() else {
                return
            }

            self.beginTimedSyncs()

            // Sync now if it's been more than our threshold.
            let now = Date.now()
            let then = self.lastSyncFinishTime ?? 0
            guard now >= then else {
                log.debug("Time was modified since last sync.")
                self.syncEverythingSoon()
                return
            }
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
        fileprivate let syncLock = NSRecursiveLock()

        public var isSyncing: Bool {
            syncLock.lock()
            defer { syncLock.unlock() }
            return syncDisplayState != nil && syncDisplayState! == .inProgress
        }

        public var syncDisplayState: SyncDisplayState?

        // The dispatch queue for coordinating syncing and resetting the database.
        fileprivate let syncQueue = DispatchQueue(label: "com.mozilla.firefox.sync")

        fileprivate typealias EngineResults = [(EngineIdentifier, SyncStatus)]
        fileprivate typealias EngineTasks = [(EngineIdentifier, SyncFunction)]

        // Used as a task queue for syncing.
        fileprivate var syncReducer: AsyncReducer<EngineResults, EngineTasks>?

        fileprivate func beginSyncing() {
            notifySyncing(notification: .ProfileDidStartSyncing)
        }

        fileprivate func endSyncing(_ result: SyncOperationResult) {
            // loop through statuses and fill sync state
            syncLock.lock()
            defer { syncLock.unlock() }
            log.info("Ending all queued syncs.")

            syncDisplayState = SyncStatusResolver(engineResults: result.engineResults).resolveResults()

            #if MOZ_TARGET_CLIENT
                if canSendUsageData() {
                    SyncPing.from(result: result,
                                  remoteClientsAndTabs: profile.remoteClientsAndTabs,
                                  prefs: prefs,
                                  why: .schedule) >>== { SyncTelemetry.send(ping: $0, docType: .sync) }
                } else {
                    log.debug("Profile isn't sending usage data. Not sending sync status event.")
                }
            #endif

            // Dont notify if we are performing a sync in the background. This prevents more db access from happening
            if !self.backgrounded {
                notifySyncing(notification: .ProfileDidFinishSyncing)
            }
            syncReducer = nil
        }

        func canSendUsageData() -> Bool {
            return profile.prefs.boolForKey(AppConstants.PrefSendUsageData) ?? true
        }

        private func notifySyncing(notification: Notification.Name) {
            NotificationCenter.default.post(name: notification, object: syncDisplayState?.asObject())
        }

        init(profile: BrowserProfile) {
            self.profile = profile
            self.prefs = profile.prefs

            super.init()

            let center = NotificationCenter.default

            center.addObserver(self, selector: #selector(onDatabaseWasRecreated), name: .DatabaseWasRecreated, object: nil)
            center.addObserver(self, selector: #selector(onLoginDidChange), name: .DataLoginDidChange, object: nil)
            center.addObserver(self, selector: #selector(onStartSyncing), name: .ProfileDidStartSyncing, object: nil)
            center.addObserver(self, selector: #selector(onFinishSyncing), name: .ProfileDidFinishSyncing, object: nil)
        }

        // TODO: Do we still need this/do we need to do this for our new DB too?
        private func handleRecreationOfDatabaseNamed(name: String?) -> Success {
            let browserCollections = ["history", "tabs"]
            let dbName = name ?? "<all>"
            switch dbName {
            case "<all>", "browser.db":
                return self.locallyResetCollections(browserCollections)
            default:
                log.debug("Unknown database \(dbName).")
                return succeed()
            }
        }

        func doInBackgroundAfter(_ millis: Int64, _ block: @escaping () -> Void) {
            let queue = DispatchQueue.global(qos: DispatchQoS.background.qosClass)
            //Pretty ambiguous here. I'm thinking .now was DispatchTime.now() and not Date.now()
            queue.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(millis)), execute: block)
        }

        @objc
        func onDatabaseWasRecreated(notification: NSNotification) {
            log.debug("Database was recreated.")
            let name = notification.object as? String
            log.debug("Database was \(name ?? "nil").")

            // We run this in the background after a few hundred milliseconds;
            // it doesn't really matter when it runs, so long as it doesn't
            // happen in the middle of a sync.

            let resetDatabase = {
                return self.handleRecreationOfDatabaseNamed(name: name) >>== {
                    log.debug("Reset of \(name ?? "nil") done")
                }
            }

            self.doInBackgroundAfter(300) {
                self.syncLock.lock()
                defer { self.syncLock.unlock() }
                // If we're syncing already, then wait for sync to end,
                // then reset the database on the same serial queue.
                if let reducer = self.syncReducer, !reducer.isFilled {
                    reducer.terminal.upon { _ in
                        self.syncQueue.async(execute: resetDatabase)
                    }
                } else {
                    // Otherwise, reset the database on the sync queue now
                    // Sync can't start while this is still going on.
                    self.syncQueue.async(execute: resetDatabase)
                }
            }
        }

        // Simple in-memory rate limiting.
        var lastTriggeredLoginSync: Timestamp = 0
        @objc func onLoginDidChange(_ notification: NSNotification) {
            log.debug("Login did change.")
            if (Date.now() - lastTriggeredLoginSync) > OneMinuteInMilliseconds {
                lastTriggeredLoginSync = Date.now()

                // Give it a few seconds.
                // Trigger on the main queue. The bulk of the sync work runs in the background.
                let greenLight = self.greenLight()
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(SyncConstants.SyncDelayTriggered)) {
                    if greenLight() {
                        self.syncLogins()
                    }
                }
            }
        }

        public var lastSyncFinishTime: Timestamp? {
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

        @objc func onStartSyncing(_ notification: NSNotification) {
            syncLock.lock()
            defer { syncLock.unlock() }
            syncDisplayState = .inProgress
        }

        @objc func onFinishSyncing(_ notification: NSNotification) {
            syncLock.lock()
            defer { syncLock.unlock() }
            if let syncState = syncDisplayState, syncState == .good {
                self.lastSyncFinishTime = Date.now()
            }
        }

        var prefsForSync: Prefs {
            return self.prefs.branch("sync")
        }

        public func onAddedAccount() -> Success {
            // Only sync if we're green lit. This makes sure that we don't sync unverified accounts.
            guard self.profile.hasSyncableAccount() else { return succeed() }

            self.beginTimedSyncs()
            return self.syncEverything(why: .didLogin)
        }

        func locallyResetCollections(_ collections: [String]) -> Success {
            return walk(collections, f: self.locallyResetCollection)
        }

        func locallyResetCollection(_ collection: String) -> Success {
            switch collection {
            case "bookmarks":
                return self.profile.places.resetBookmarksMetadata()
            case "clients":
                fallthrough
            case "tabs":
                // Because clients and tabs share storage, and thus we wipe data for both if we reset either,
                // we reset the prefs for both at the same time.
                return TabsSynchronizer.resetClientsAndTabsWithStorage(self.profile.remoteClientsAndTabs, basePrefs: self.prefsForSync)

            case "history":
                return HistorySynchronizer.resetSynchronizerWithStorage(self.profile.history, basePrefs: self.prefsForSync, collection: "history")
            case "passwords":
                return self.profile.logins.reset()
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

        public func onNewProfile() {
            SyncStateMachine.clearStateFromPrefs(self.prefsForSync)
        }

        public func onRemovedAccount() -> Success {
            let profile = self.profile

            // Run these in order, because they might write to the same DB!
            let remove = [
                profile.history.onRemovedAccount,
                profile.remoteClientsAndTabs.onRemovedAccount,
                profile.logins.reset,
                profile.places.resetBookmarksMetadata,
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

        fileprivate func repeatingTimerAtInterval(_ interval: TimeInterval, selector: Selector) -> Timer {
            return Timer.scheduledTimer(timeInterval: interval, target: self, selector: selector, userInfo: nil, repeats: true)
        }

        public func beginTimedSyncs() {
            if self.syncTimer != nil {
                log.debug("Already running sync timer.")
                return
            }

            let interval = FifteenMinutes
            let selector = #selector(syncOnTimer)
            log.debug("Starting sync timer.")
            self.syncTimer = repeatingTimerAtInterval(interval, selector: selector)
        }

        /**
         * The caller is responsible for calling this on the same thread on which it called
         * beginTimedSyncs.
         */
        public func endTimedSyncs() {
            if let t = self.syncTimer {
                log.debug("Stopping sync timer.")
                self.syncTimer = nil
                t.invalidate()
            }
        }

        fileprivate func syncClientsWithDelegate(_ delegate: SyncDelegate, prefs: Prefs, ready: Ready, why: SyncReason) -> SyncResult {
            log.debug("Syncing clients to storage.")

            if constellationStateUpdate == nil {
                constellationStateUpdate = NotificationCenter.default.addObserver(forName: .constellationStateUpdate, object: nil, queue: .main) { [weak self] notification in
                    guard let state = self?.profile.rustFxA.accountManager.deviceConstellation()?.state() else {
                        return
                    }
                    guard let self = self else { return }
                    let devices = state.remoteDevices.map { d -> RemoteDevice in
                        let t = "\(d.deviceType)"
                        return RemoteDevice(id: d.id, name: d.displayName, type: t, isCurrentDevice: d.isCurrentDevice, lastAccessTime: d.lastAccessTime, availableCommands: nil)
                    }
                    let _ = self.profile.remoteClientsAndTabs.replaceRemoteDevices(devices)
                }
            }

            let clientSynchronizer = ready.synchronizer(ClientsSynchronizer.self, delegate: delegate, prefs: prefs, why: why)
            return clientSynchronizer.synchronizeLocalClients(self.profile.remoteClientsAndTabs, withServer: ready.client, info: ready.info, notifier: self) >>== { result in
                guard case .completed = result else {
                    return deferMaybe(result)
                }
                log.debug("Updating FxA devices list.")

                self.profile.rustFxA.accountManager.deviceConstellation()?.refreshState()
                return deferMaybe(result)
            }
        }

        fileprivate func syncTabsWithDelegate(_ delegate: SyncDelegate, prefs: Prefs, ready: Ready, why: SyncReason) -> SyncResult {
            let storage = self.profile.remoteClientsAndTabs
            let tabSynchronizer = ready.synchronizer(TabsSynchronizer.self, delegate: delegate, prefs: prefs, why: why)
            return tabSynchronizer.synchronizeLocalTabs(storage, withServer: ready.client, info: ready.info)
        }

        fileprivate func syncHistoryWithDelegate(_ delegate: SyncDelegate, prefs: Prefs, ready: Ready, why: SyncReason) -> SyncResult {
            log.debug("Syncing history to storage.")
            let historySynchronizer = ready.synchronizer(HistorySynchronizer.self, delegate: delegate, prefs: prefs, why: why)
            return historySynchronizer.synchronizeLocalHistory(self.profile.history, withServer: ready.client, info: ready.info, greenLight: self.greenLight())
        }

        public class ScopedKeyError: MaybeErrorType {
            public var description = "No key data found for scope."
        }
        
        public class SyncUnlockGetURLError: MaybeErrorType {
            public var description = "Failed to get token server endpoint url."
        }

        fileprivate func syncUnlockInfo() -> Deferred<Maybe<SyncUnlockInfo>> {
            let d = Deferred<Maybe<SyncUnlockInfo>>()
            RustFirefoxAccounts.shared.accountManager.getAccessToken(scope: OAuthScope.oldSync) { result in
                guard let accessTokenInfo = try? result.get(), let key = accessTokenInfo.key else {
                    d.fill(Maybe(failure: ScopedKeyError()))
                    return
                }

                RustFirefoxAccounts.shared.accountManager.getTokenServerEndpointURL() { result in
                    guard case .success(let tokenServerEndpointURL) = result else {
                        d.fill(Maybe(failure: SyncUnlockGetURLError()))
                        return
                    }

                    d.fill(Maybe(success: SyncUnlockInfo(kid: key.kid, fxaAccessToken: accessTokenInfo.token, syncKey: key.k, tokenserverURL: tokenServerEndpointURL.absoluteString)))
                }
            }
            return d
        }

        fileprivate func syncLoginsWithDelegate(_ delegate: SyncDelegate, prefs: Prefs, ready: Ready, why: SyncReason) -> SyncResult {
            log.debug("Syncing logins to storage.")
            return syncUnlockInfo().bind({ result in
                guard let syncUnlockInfo = result.successValue else {
                    return deferMaybe(SyncStatus.notStarted(.unknown))
                }

                return self.profile.logins.sync(unlockInfo: syncUnlockInfo).bind({ result in
                    guard result.isSuccess else {
                        return deferMaybe(SyncStatus.notStarted(.unknown))
                    }

                    let syncEngineStatsSession = SyncEngineStatsSession(collection: "logins")
                    return deferMaybe(SyncStatus.completed(syncEngineStatsSession))
                })
            })
        }

        fileprivate func syncBookmarksWithDelegate(_ delegate: SyncDelegate, prefs: Prefs, ready: Ready, why: SyncReason) -> SyncResult {
            log.debug("Syncing bookmarks to storage.")
            return syncUnlockInfo().bind({ result in
                guard let syncUnlockInfo = result.successValue else {
                    return deferMaybe(SyncStatus.notStarted(.unknown))
                }

                return self.profile.places.syncBookmarks(unlockInfo: syncUnlockInfo).bind({ result in
                    guard result.isSuccess else {
                        return deferMaybe(SyncStatus.notStarted(.unknown))
                    }

                    let syncEngineStatsSession = SyncEngineStatsSession(collection: "bookmarks")
                    return deferMaybe(SyncStatus.completed(syncEngineStatsSession))
                })
            })
        }

        func takeActionsOnEngineStateChanges<T: EngineStateChanges>(_ changes: T) -> Deferred<Maybe<T>> {
            var needReset = Set<String>(changes.collectionsThatNeedLocalReset())
            needReset.formUnion(changes.enginesDisabled())
            needReset.formUnion(changes.enginesEnabled())
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
        fileprivate func sync(_ label: EngineIdentifier, function: @escaping SyncFunction) -> SyncResult {
            return syncSeveral(why: .user, synchronizers: [(label, function)]) >>== { statuses in
                let status = statuses.find { label == $0.0 }?.1
                return deferMaybe(status ?? .notStarted(.unknown))
            }
        }

        /**
         * Convenience method for syncSeveral([(EngineIdentifier, SyncFunction)])
         */
        private func syncSeveral(why: SyncReason, synchronizers: (EngineIdentifier, SyncFunction)...) -> Deferred<Maybe<[(EngineIdentifier, SyncStatus)]>> {
            return syncSeveral(why: why, synchronizers: synchronizers)
        }

        /**
         * Runs each of the provided synchronization functions with the same inputs.
         * Returns an array of IDs and SyncStatuses at least length as the input.
         * The statuses returned will be a superset of the ones that are requested here.
         * While a sync is ongoing, each engine from successive calls to this method will only be called once.
         */
        fileprivate func syncSeveral(why: SyncReason, synchronizers: [(EngineIdentifier, SyncFunction)]) -> Deferred<Maybe<[(EngineIdentifier, SyncStatus)]>> {
            syncLock.lock()
            defer { syncLock.unlock() }

            let fxa = RustFirefoxAccounts.shared.accountManager
            guard let profile = fxa.accountProfile(), let deviceID = fxa.deviceConstellation()?.state()?.localDevice?.id else {
                return deferMaybe(NoAccountError())
            }

            // TODO: we should check if we can sync!

            // TODO: Invoke `account.commandsClient.fetchMissedRemoteCommands()` to
            // catch any missed FxA commands at time of Sync?

            if !isSyncing {
                // TODO: needs lots of clean-up
                let uid = profile.uid
                // A sync isn't already going on, so start another one.
                let statsSession = SyncOperationStatsSession(why: why, uid: uid, deviceID: deviceID)
                let reducer = AsyncReducer<EngineResults, EngineTasks>(initialValue: [], queue: syncQueue) { (statuses, synchronizers)  in
                    let done = Set(statuses.map { $0.0 })
                    let remaining = synchronizers.filter { !done.contains($0.0) }
                    if remaining.isEmpty {
                        log.info("Nothing left to sync")
                        return deferMaybe(statuses)
                    }

                    return self.syncWith(synchronizers: remaining, statsSession: statsSession, why: why) >>== { deferMaybe(statuses + $0) }
                }

                reducer.terminal.upon { results in
                    let result = SyncOperationResult(
                        engineResults: results,
                        stats: statsSession.hasStarted() ? statsSession.end() : nil
                    )
                    self.endSyncing(result)
                }

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
                    ($0.0, SyncStatus.notStarted(.unknown))
                }
                return deferMaybe(statuses)
            }
        }

        func engineEnablementChangesForAccount() -> [String: Bool]? {
            var enginesEnablements: [String: Bool] = [:]
            // We just created the account, the user went through the Choose What to Sync screen on FxA.
            if let declined = UserDefaults.standard.stringArray(forKey: "fxa.cwts.declinedSyncEngines") {
                declined.forEach { enginesEnablements[$0] = false }
                UserDefaults.standard.removeObject(forKey: "fxa.cwts.declinedSyncEngines")
            } else {
                // Bundle in authState the engines the user activated/disabled since the last sync.
                TogglableEngines.forEach { engine in
                    let stateChangedPref = "engine.\(engine).enabledStateChanged"
                    if let _ = self.prefsForSync.boolForKey(stateChangedPref),
                        let enabled = self.prefsForSync.boolForKey("engine.\(engine).enabled") {
                        enginesEnablements[engine] = enabled
                        self.prefsForSync.setObject(nil, forKey: stateChangedPref)
                    }
                }
            }
            return enginesEnablements
        }

        // This SHOULD NOT be called directly: use syncSeveral instead.
        fileprivate func syncWith(synchronizers: [(EngineIdentifier, SyncFunction)],
                                  statsSession: SyncOperationStatsSession, why: SyncReason) -> Deferred<Maybe<[(EngineIdentifier, SyncStatus)]>> {
            log.info("Syncing \(synchronizers.map { $0.0 })")
            var authState = RustFirefoxAccounts.shared.syncAuthState
            let delegate = self.profile.getSyncDelegate()
            // TODO
            if let enginesEnablements = self.engineEnablementChangesForAccount(),
               !enginesEnablements.isEmpty {
                authState.enginesEnablements = enginesEnablements
                log.debug("engines to enable: \(enginesEnablements.compactMap { $0.value ? $0.key : nil })")
                log.debug("engines to disable: \(enginesEnablements.compactMap { !$0.value ? $0.key : nil })")
            }

            // TODO
//            authState?.clientName = account.deviceName

            let readyDeferred = SyncStateMachine(prefs: self.prefsForSync).toReady(authState)

            let function: (SyncDelegate, Prefs, Ready) -> Deferred<Maybe<[EngineStatus]>> = { delegate, syncPrefs, ready in
                let thunks = synchronizers.map { (i, f) in
                    return { () -> Deferred<Maybe<EngineStatus>> in
                        log.debug("Syncing \(i)…")
                        return f(delegate, syncPrefs, ready, why) >>== { deferMaybe((i, $0)) }
                    }
                }
                return accumulate(thunks)
            }

            return readyDeferred.bind { readyResult in
                guard let success = readyResult.successValue else {
                    return deferMaybe(readyResult.failureValue!)
                }
                return self.takeActionsOnEngineStateChanges(success) >>== { ready in
                    let updateEnginePref: ((String, Bool) -> Void) = { engine, enabled in
                        self.prefsForSync.setBool(enabled, forKey: "engine.\(engine).enabled")
                    }
                    ready.engineConfiguration?.enabled.forEach { updateEnginePref($0, true) }
                    ready.engineConfiguration?.declined.forEach { updateEnginePref($0, false) }

                    statsSession.start()
                    return function(delegate, self.prefsForSync, ready)
                }
            }
        }

        @discardableResult public func syncEverything(why: SyncReason) -> Success {
            if RustFirefoxAccounts.shared.accountManager.accountMigrationInFlight() {
                RustFirefoxAccounts.shared.accountManager.retryMigration() { _ in }
                return Success()
            }

            let synchronizers = [
                ("clients", self.syncClientsWithDelegate),
                ("tabs", self.syncTabsWithDelegate),
                ("bookmarks", self.syncBookmarksWithDelegate),
                ("history", self.syncHistoryWithDelegate),
                ("logins", self.syncLoginsWithDelegate)
            ]

            return self.syncSeveral(why: why, synchronizers: synchronizers) >>> succeed
        }

        func syncEverythingSoon() {
            self.doInBackgroundAfter(SyncConstants.SyncOnForegroundAfterMillis) {
                log.debug("Running delayed startup sync.")
                self.syncEverything(why: .startup)
            }
        }

        /**
         * Allows selective sync of different collections, for use by external APIs.
         * Some help is given to callers who use different namespaces (specifically: `passwords` is mapped to `logins`)
         * and to preserve some ordering rules.
         */
        public func syncNamedCollections(why: SyncReason, names: [String]) -> Success {
            // Massage the list of names into engine identifiers.
            let engineIdentifiers = names.map { name -> [EngineIdentifier] in
                switch name {
                case "passwords":
                    return ["logins"]
                case "tabs":
                    return ["clients", "tabs"]
                default:
                    return [name]
                }
            }.flatMap { $0 }

            // By this time, `engineIdentifiers` may have duplicates in. We won't try and dedupe here
            // because `syncSeveral` will do that for us.

            let synchronizers: [(EngineIdentifier, SyncFunction)] = engineIdentifiers.compactMap {
                switch $0 {
                case "clients": return ("clients", self.syncClientsWithDelegate)
                case "tabs": return ("tabs", self.syncTabsWithDelegate)
                case "logins": return ("logins", self.syncLoginsWithDelegate)
                case "bookmarks": return ("bookmarks", self.syncBookmarksWithDelegate)
                case "history": return ("history", self.syncHistoryWithDelegate)
                default: return nil
                }
            }
            return self.syncSeveral(why: why, synchronizers: synchronizers) >>> succeed
        }

        @objc func syncOnTimer() {
            self.syncEverything(why: .scheduled)
        }

        public func hasSyncedHistory() -> Deferred<Maybe<Bool>> {
            return self.profile.history.hasSyncedHistory()
        }

        public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
            return self.profile.logins.hasSyncedLogins()
        }

        public func syncClients() -> SyncResult {
            // TODO: recognize .NotStarted.
            return self.sync("clients", function: syncClientsWithDelegate)
        }

        public func syncClientsThenTabs() -> SyncResult {
            return self.syncSeveral(
                why: .user,
                synchronizers:
                ("clients", self.syncClientsWithDelegate),
                ("tabs", self.syncTabsWithDelegate)) >>== { statuses in
                let status = statuses.find { "tabs" == $0.0 }
                return deferMaybe(status!.1)
            }
        }

        @discardableResult public func syncBookmarks() -> SyncResult {
            return self.sync("bookmarks", function: syncBookmarksWithDelegate)
        }

        @discardableResult public func syncLogins() -> SyncResult {
            return self.sync("logins", function: syncLoginsWithDelegate)
        }

        public func syncHistory() -> SyncResult {
            // TODO: recognize .NotStarted.
            return self.sync("history", function: syncHistoryWithDelegate)
        }

        /**
         * Return a thunk that continues to return true so long as an ongoing sync
         * should continue.
         */
        func greenLight() -> () -> Bool {
            let start = Date.now()

            // Give it two minutes to run before we stop.
            let stopBy = start + (2 * OneMinuteInMilliseconds)
            log.debug("Checking green light. Backgrounded: \(self.backgrounded).")
            return {
                Date.now() < stopBy &&
                self.profile.hasSyncableAccount()
            }
        }

        public func notify(deviceIDs: [GUID], collectionsChanged collections: [String], reason: String) -> Success {
           return succeed()
        }

        public func notifyAll(collectionsChanged collections: [String], reason: String) -> Success {
            return succeed()
        }
    }
}
