// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

// IMPORTANT!: Please take into consideration when adding new imports to
// this file that it is utilized by external components besides the core
// application (i.e. App Extensions). Introducing new dependencies here
// may have unintended negative consequences for App Extensions such as
// increased startup times which may lead to termination by the OS.

import Common
import Account
import Shared
import Storage
import Sync
import SyncTelemetry
import AuthenticationServices
import MozillaAppServices

public protocol SyncManager {
    var isSyncing: Bool { get }
    var lastSyncFinishTime: Timestamp? { get set }
    var syncDisplayState: SyncDisplayState? { get }

    func syncClients() -> OldSyncResult
    func syncClientsThenTabs() -> OldSyncResult
    func syncHistory() -> OldSyncResult
    func syncNamedCollections(why: OldSyncReason, names: [String]) -> Success
    @discardableResult
    func syncEverything(why: OldSyncReason) -> Success

    func endTimedSyncs()
    func applicationDidBecomeActive()
    func applicationDidEnterBackground()

    @discardableResult
    func onRemovedAccount() -> Success
    @discardableResult
    func onAddedAccount() -> Success
}

/// This exists to pass in external context: e.g., the UIApplication can
/// expose notification functionality in this way.
public protocol SendTabDelegate: AnyObject {
    func openSendTabs(for urls: [URL])
}

typealias SyncFunction = (Prefs, Ready, OldSyncReason) -> OldSyncResult

class ProfileFileAccessor: FileAccessor {
    convenience init(profile: Profile) {
        self.init(localName: profile.localName())
    }

    init(localName: String, logger: Logger = DefaultLogger.shared) {
        let profileDirName = "profile.\(localName)"

        // Bug 1147262: First option is for device, second is for simulator.
        var rootPath: String
        let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier
        if let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: sharedContainerIdentifier) {
            rootPath = url.path
        } else {
            logger.log("Unable to find the shared container. Defaulting profile location to ~/Documents instead.",
                       level: .warning,
                       category: .unlabeled)
            rootPath = (NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0])
        }

        super.init(rootPath: URL(fileURLWithPath: rootPath).appendingPathComponent(profileDirName).path)
    }
}

/**
 * A Profile manages access to the user's data.
 */
protocol Profile: AnyObject {
    var autofill: RustAutofill { get }
    var places: RustPlaces { get }
    var prefs: Prefs { get }
    var queue: TabQueue { get }
    #if !MOZ_TARGET_NOTIFICATIONSERVICE && !MOZ_TARGET_SHARETO && !MOZ_TARGET_CREDENTIAL_PROVIDER
    var searchEngines: SearchEngines { get }
    #endif
    var files: FileAccessor { get }
    var pinnedSites: PinnedSites { get }
    var logins: RustLogins { get }
    var certStore: CertStore { get }
    var recentlyClosedTabs: ClosedTabsStore { get }

#if !MOZ_TARGET_NOTIFICATIONSERVICE
    var readingList: ReadingList { get }
#endif

    var isShutdown: Bool { get }

    /// WARNING: Only to be called as part of the app lifecycle from the AppDelegate
    /// or from App Extension code.
    func shutdown()

    /// WARNING: Only to be called as part of the app lifecycle from the AppDelegate
    /// or from App Extension code.
    func reopen()

    // I got really weird EXC_BAD_ACCESS errors on a non-null reference when I made this a getter.
    // Similar to <http://stackoverflow.com/questions/26029317/exc-bad-access-when-indirectly-accessing-inherited-member-in-swift>.
    func localName() -> String

    // Async call to wait for result
    func hasSyncAccount(completion: @escaping (Bool) -> Void)

    // Do we have an account at all?
    func hasAccount() -> Bool

    // Do we have an account that (as far as we know) is in a syncable state?
    func hasSyncableAccount() -> Bool

    var rustFxA: RustFirefoxAccounts { get }

    func removeAccount()

    func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>>
    func getCachedClientsAndTabs(completion: @escaping ([ClientAndTabs]) -> Void)
    func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>>

    func cleanupHistoryIfNeeded()

    @discardableResult
    func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>>

    func sendItem(_ item: ShareItem, toDevices devices: [RemoteDevice]) -> Success
    func pollCommands(forcePoll: Bool)

    var syncManager: SyncManager! { get }
    func hasSyncedLogins() -> Deferred<Maybe<Bool>>

    func syncCredentialIdentities() -> Deferred<Result<Void, Error>>
    func updateCredentialIdentities() -> Deferred<Result<Void, Error>>
    func clearCredentialStore() -> Deferred<Result<Void, Error>>

    func setCommandArrived()
}

extension Profile {
    func syncCredentialIdentities() -> Deferred<Result<Void, Error>> {
        let deferred = Deferred<Result<Void, Error>>()
        self.clearCredentialStore().upon { clearResult in
            self.updateCredentialIdentities().upon { updateResult in
                switch (clearResult, updateResult) {
                case (.success, .success):
                    deferred.fill(.success(()))
                case (.failure(let error), _):
                    deferred.fill(.failure(error))
                case (_, .failure(let error)):
                    deferred.fill(.failure(error))
                }
            }
        }
        return deferred
    }

    func updateCredentialIdentities() -> Deferred<Result<Void, Error>> {
        let deferred = Deferred<Result<Void, Error>>()
        self.logins.listLogins().upon { loginResult in
            switch loginResult {
            case let .failure(error):
                deferred.fill(.failure(error))
            case let .success(logins):

                self.populateCredentialStore(
                        identities: logins.map(\.passwordCredentialIdentity)
                ).upon(deferred.fill)
            }
        }
        return deferred
    }

    func populateCredentialStore(identities: [ASPasswordCredentialIdentity]) -> Deferred<Result<Void, Error>> {
        let deferred = Deferred<Result<Void, Error>>()
        ASCredentialIdentityStore.shared.saveCredentialIdentities(identities) { (success, error) in
            if success {
                deferred.fill(.success(()))
            } else if let err = error {
                deferred.fill(.failure(err))
            }
        }
        return deferred
    }

    func clearCredentialStore() -> Deferred<Result<Void, Error>> {
        let deferred = Deferred<Result<Void, Error>>()

        ASCredentialIdentityStore.shared.removeAllCredentialIdentities { (success, error) in
            if success {
                deferred.fill(.success(()))
            } else if let err = error {
                deferred.fill(.failure(err))
            }
        }

        return deferred
    }
}

open class BrowserProfile: Profile {
    private let logger: Logger
    fileprivate let name: String
    fileprivate let keychain: MZKeychainWrapper
    var isShutdown = false

    internal let files: FileAccessor

    let database: BrowserDB
    let readingListDB: BrowserDB
    var syncManager: SyncManager!

    var sendTabDelegate: SendTabDelegate?
    var useRustSyncManager = false

    /**
     * N.B., BrowserProfile is used from our extensions, often via a pattern like
     *
     *   BrowserProfile(…).foo.saveSomething(…)
     *
     * This can break if BrowserProfile's initializer does async work that
     * subsequently — and asynchronously — expects the profile to stick around:
     * see Bug 1218833. Be sure to only perform synchronous actions here.
     *
     * A SentTabDelegate can be provided in this initializer, or once the profile is initialized.
     * However, if we provide it here, it's assumed that we're initializing it from the application.
     */
    init(localName: String,
         sendTabDelegate: SendTabDelegate? = nil,
         rustSyncManagerEnabled: Bool = false,
         creditCardAutofillEnabled: Bool = false,
         clear: Bool = false,
         logger: Logger = DefaultLogger.shared) {
        logger.log("Initing profile \(localName) on thread \(Thread.current).",
                   level: .debug,
                   category: .setup)
        self.name = localName
        self.files = ProfileFileAccessor(localName: localName)
        self.keychain = MZKeychainWrapper.sharedClientAppContainerKeychain
        self.logger = logger
        self.sendTabDelegate = sendTabDelegate

        if clear {
            do {
                // Remove the contents of the directory…
                try self.files.removeFilesInDirectory()
                // …then remove the directory itself.
                try self.files.remove("")
            } catch {
                logger.log("Cannot clear profile: \(error)",
                           level: .info,
                           category: .setup)
            }
        }

        // If the profile dir doesn't exist yet, this is first run (for this profile). The check is made here
        // since the DB handles will create new DBs under the new profile folder.
        let isNewProfile = !files.exists("")

        // Set up our database handles.
        self.database = BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
        self.readingListDB = BrowserDB(filename: "ReadingList.db", schema: ReadingListSchema(), files: files)

        if isNewProfile {
            logger.log("New profile. Removing old Keychain/Prefs data.",
                       level: .info,
                       category: .setup)
            MZKeychainWrapper.wipeKeychain()
            prefs.clearAll()
        }

        // Set up logging from Rust.
        if !RustLog.shared.tryEnable({ (level, tag, message) -> Bool in
            let logString = "[RUST][\(tag ?? "no-tag")] \(message)"

            switch level {
            case .trace:
                break
            case .debug:
                logger.log(logString,
                           level: .debug,
                           category: .sync)
            case .info:
                logger.log(logString,
                           level: .info,
                           category: .sync)
            case .warn:
                logger.log(logString,
                           level: .warning,
                           category: .sync)
            case .error:
                logger.log(logString,
                           level: .warning,
                           category: .sync)
            }

            return true
        }) {
            logger.log("Unable to enable logging from Rust",
                       level: .warning,
                       category: .setup)
        }

        // By default, filter logging from Rust below `.info` level.
        try? RustLog.shared.setLevelFilter(filter: .info)

        // Set to true if either the Nimbus flag is enabled or RustSyncManager has been
        // used before. Using these two values to check whether RustSyncManager has been
        // used will prevent BrowserSyncManager being used after upgrading to RustSyncManager
        // in the event the Nimbus experiment is ended prematurely.
        self.useRustSyncManager = rustSyncManagerEnabled ||
            self.prefs.boolForKey(PrefsKeys.HasRustSyncManagerEverBeenUsed) ?? false

        // Initiating the sync manager has to happen prior to the databases being opened,
        // because opening them can trigger events to which the SyncManager listens.
        if self.useRustSyncManager {
            let msg = "Setting `syncManager` property to `RustSyncManager"
            logger.log(msg, level: .debug, category: .sync)

            self.syncManager = RustSyncManager(profile: self,
                                               creditCardAutofillEnabled: creditCardAutofillEnabled)

            // Setting this pref to true in the event this is the first time
            // RustSyncManager is being used. If it's been used before setting this pref
            // to true does no harm.
            self.prefs.setBool(true, forKey: PrefsKeys.HasRustSyncManagerEverBeenUsed)
        } else {
            let msg = "Setting `syncManager` property to `BrowserSyncManager"
            logger.log(msg, level: .debug, category: .sync)

            self.syncManager = BrowserSyncManager(profile: self)
        }

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(self, selector: #selector(onLocationChange), name: .OnLocationChange, object: nil)
        notificationCenter.addObserver(self, selector: #selector(onPageMetadataFetched), name: .OnPageMetadataFetched, object: nil)

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

        // Create the "Downloads" folder in the documents directory.
        if let downloadsPath = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("Downloads").path {
            try? FileManager.default.createDirectory(atPath: downloadsPath, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func reopen() {
        logger.log("Reopening profile.",
                   level: .debug,
                   category: .storage)
        isShutdown = false

        database.reopenIfClosed()
        _ = logins.reopenIfClosed()
        // it's possible we are going through a history migration
        // lets make sure that if the places connection is already open
        // we don't try to reopen it
        if !places.isOpen {
            _ = places.reopenIfClosed()
        }
        _ = tabs.reopenIfClosed()
        _ = autofill.reopenIfClosed()
    }

    func shutdown() {
        logger.log("Shutting down profile.",
                   level: .debug,
                   category: .storage)
        isShutdown = true

        database.forceClose()
        _ = logins.forceClose()
        _ = places.forceClose()
        _ = tabs.forceClose()
        _ = autofill.forceClose()
    }

    @objc
    func onLocationChange(notification: NSNotification) {
        if let v = notification.userInfo!["visitType"] as? Int,
           let visitType = VisitType(rawValue: v),
           let url = notification.userInfo!["url"] as? URL, !isIgnoredURL(url),
           let title = notification.userInfo!["title"] as? NSString {
            // Only record local vists if the change notification originated from a non-private tab
            if !(notification.userInfo!["isPrivate"] as? Bool ?? false) {
                let result = self.places.applyObservation(
                    visitObservation: VisitObservation(
                        url: url.description,
                        title: title as String,
                        visitType: VisitTransition.fromVisitType(visitType: visitType)
                    )
                )
                result.upon { result in
                    guard result.isSuccess else {
                        self.logger.log(result.failureValue?.localizedDescription ?? "Unknown error adding history visit",
                                        level: .warning,
                                        category: .sync)
                        return
                    }
                }
            }
        } else {
            logger.log("Ignoring location change",
                       level: .debug,
                       category: .lifecycle)
        }
    }

    @objc
    func onPageMetadataFetched(notification: NSNotification) {
        let isPrivate = notification.userInfo?["isPrivate"] as? Bool ?? true
        guard !isPrivate else {
            logger.log("Private mode - Ignoring page metadata.",
                       level: .debug,
                       category: .lifecycle)
            return
        }
        guard let pageURL = notification.userInfo?["tabURL"] as? URL,
              let pageMetadata = notification.userInfo?["pageMetadata"] as? PageMetadata else {
            logger.log("Metadata notification doesn't contain any metadata!",
                       level: .debug,
                       category: .lifecycle)
            return
        }
        let defaultMetadataTTL: UInt64 = 3 * 24 * 60 * 60 * 1000 // 3 days for the metadata to live
        self.metadata.storeMetadata(pageMetadata, forPageURL: pageURL, expireAt: defaultMetadataTTL + Date.now())
    }

    deinit {
        self.syncManager.endTimedSyncs()
    }

    func localName() -> String {
        return name
    }

    lazy var queue: TabQueue = {
        withExtendedLifetime(self.legacyPlaces) {
            return SQLiteQueue(db: self.database)
        }
    }()

    /**
     * Any other class that needs to access any one of these should ensure
     * that this is initialized first.
     */
    private lazy var legacyPlaces: PinnedSites  = {
        return BrowserDBSQLite(database: self.database, prefs: self.prefs)
    }()

    var pinnedSites: PinnedSites {
        return self.legacyPlaces
    }

    lazy var metadata: Metadata = {
        return SQLiteMetadata(db: self.database)
    }()

    lazy var placesDbPath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("places.db").path
    lazy var browserDbPath =  URL(fileURLWithPath: (try! self.files.getAndEnsureDirectory())).appendingPathComponent("browser.db").path
    lazy var places = RustPlaces(databasePath: self.placesDbPath)

    public func migrateHistoryToPlaces(callback: @escaping (HistoryMigrationResult) -> Void, errCallback: @escaping (Error?) -> Void) {
        guard FileManager.default.fileExists(atPath: browserDbPath) else {
            // This is the user's first run of the app, they don't have a browserDB, so lets report a successful
            // migration with zero visits
            callback(HistoryMigrationResult(numTotal: 0, numSucceeded: 0, numFailed: 0, totalDuration: 0))
            return
        }
        let lastSyncTimestamp = Int64(syncManager.lastSyncFinishTime ?? 0)
        places.migrateHistory(
            dbPath: browserDbPath,
            lastSyncTimestamp: lastSyncTimestamp,
            completion: callback,
            errCallback: errCallback
        )
    }

    lazy var tabsDbPath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("tabs.db").path

    lazy var tabs = RustRemoteTabs(databasePath: tabsDbPath)

    lazy var autofillDbPath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("autofill.db").path

    lazy var autofill = RustAutofill(databasePath: autofillDbPath)

    #if !MOZ_TARGET_NOTIFICATIONSERVICE && !MOZ_TARGET_SHARETO && !MOZ_TARGET_CREDENTIAL_PROVIDER
    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs, files: self.files)
    }()
    #endif

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
        return SQLiteRemoteClientsAndTabs(db: self.database)
    }()

    lazy var certStore: CertStore = {
        return CertStore()
    }()

    lazy var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()

    // This function exists to service the `FxaPushMessengerHandler.handle` function and
    // will be removed after the rust sync manager experiment is complete
    public func getClient(fxaDeviceId: String) -> Deferred<Maybe<RemoteClient?>> {
        if useRustSyncManager {
            let msg = "Retrieving client records from rust tabs component"
            logger.log(msg, level: .debug, category: .sync)

            return tabs.getClient(fxaDeviceId: fxaDeviceId)
        } else {
            let msg = "Retrieving client records from BrowserDB clients table"
            logger.log(msg, level: .debug, category: .sync)

            return remoteClientsAndTabs.getClient(fxaDeviceId: fxaDeviceId)
        }
    }

    // This function exists to service the `TabPeekViewController.setState` function and
    // will be removed after the rust sync manager experiment is complete
    public func getClientGUIDs(completion: @escaping (Set<GUID>) -> Void) {
        if useRustSyncManager {
            let msg = "Retrieving client GUIDs from rust tabs component"
            logger.log(msg, level: .debug, category: .sync)

            tabs.getClientGUIDs { (result, error) in
                guard let guids = result else { return }
                completion(guids)
            }
        } else {
            let msg = "Retrieving client GUIDs from BrowserDB clients table"
            logger.log(msg, level: .debug, category: .sync)

            remoteClientsAndTabs.getClientGUIDs().upon { result in
                guard let guids = result.successValue else { return }
                completion(guids)
            }
        }
    }

    func getRustTabsWithClients() -> Deferred<Maybe<[ClientAndTabs]>> {
        logger.log("Getting all tabs and clients", level: .debug, category: .tabs)

        guard let accountManager = self.rustFxA.accountManager.peek(),
              let state = accountManager.deviceConstellation()?.state()
        else {
            return deferMaybe([])
        }

        let remoteDeviceIds: [String] = state.remoteDevices.compactMap {
            guard $0.capabilities.contains(.sendTab) else { return nil }
            return $0.id
        }

        let clientAndTabs = tabs.getRemoteClients(remoteDeviceIds: remoteDeviceIds)
        return clientAndTabs
    }

    func getTabsWithNativeClients() -> Deferred<Maybe<[ClientAndTabs]>> {
        // Retrieving tabs with clients is handled differently depending on whether the
        // rust sync manager component is being used. The `BrowserSyncManager` class syncs
        // tabs with the rust tabs component and clients with the `ClientSynchronizer`
        // class. So in order to ensure accurate tabs with clients data is returned while
        // using these classes for syncing, tab records are pulled from the component's
        // database table and filtered by the client records in the iOS BrowserDB database
        // table.

        // The new `RustSyncManager` class has no reliance on the `ClientSynchronizer` or
        // the clients table. So when it's being used tabs with clients can be pulled from
        // the tab component's database table and filtered by the remote devices in the
        // user's device constellation. Once the sync manager experiment is complete this
        // will be the way this data is retrieved unconditionally.
        if useRustSyncManager {
            let msg = "Retrieving tabs with clients and filtering on remote devices"
            logger.log(msg, level: .debug, category: .sync)

            return getRustTabsWithClients()
        } else {
            let msg = "Retrieving tabs with clients and filtering on BrowserDB clients table"
            logger.log(msg, level: .debug, category: .sync)

            return tabs.getAll().bind { tabsResult in
                guard tabsResult.failureValue == nil else {
                    return deferMaybe(tabsResult.failureValue!)
                }
                guard let clientRemoteTabs = tabsResult.successValue else {
                    return deferMaybe([])
                }

                return self.remoteClientsAndTabs.getClients().bind { result in
                    guard result.failureValue == nil else { return deferMaybe(result.failureValue!)}
                    guard let clients = result.successValue else { return deferMaybe([]) }

                    let clientAndTabs: [ClientAndTabs] = clientRemoteTabs.map { record in
                        // We check if the application services clientId matches any
                        // client GUID. If a client is found we return a record, otherwise
                        // we continue to the next application services record.
                        let localClient = clients
                                            .first(where: { $0.guid == record.clientId })

                        if let client = localClient {
                            return record.toClientAndTabs(client: client)
                        }
                        let msg = "Could not find client data for appservices client ID \(record.clientId)."
                        self.logger.log(msg, level: .debug, category: .tabs)
                        return nil
                    }.compactMap { $0 }

                    return deferMaybe(clientAndTabs)
                }
            }
        }
    }

    public func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return self.syncManager.syncClientsThenTabs()
        >>> { self.getTabsWithNativeClients() }
    }

    public func getCachedClientsAndTabs(completion: @escaping ([ClientAndTabs]) -> Void) {
        let defferedResponse = self.getTabsWithNativeClients()
        defferedResponse.upon { result in
            completion(result.successValue ?? [])
        }
    }

    public func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return self.getTabsWithNativeClients()
    }

    public func cleanupHistoryIfNeeded() {
        // We run the cleanup in the background, this is a low priority task
        // that compacts the places db and reduces it's size to be under the limit.
        DispatchQueue.global(qos: .background).async {
            self.places.runMaintenance(dbSizeLimit: AppConstants.databaseSizeLimitInBytes)
        }
    }

    public func sendQueuedSyncEvents() {
        if !hasAccount() {
            // We shouldn't be called at all if the user isn't signed in.
            return
        }
        if syncManager.isSyncing {
            // If Sync is already running, `BrowserSyncManager#endSyncing` will
            // send a ping with the queued events when it's done, so don't send
            // an events-only ping now.
            return
        }
        let sendUsageData = prefs.boolForKey(AppConstants.prefSendUsageData) ?? true
        if sendUsageData {
            SyncPing.fromQueuedEvents(
                prefs: self.prefs,
                why: .schedule
            ) {
                guard let ping = $0 else { return }
                SyncTelemetry.send(ping: ping, docType: .sync)
            }
        }
    }

    func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return self.tabs.setLocalTabs(localTabs: tabs)
    }

    public func sendItem(_ item: ShareItem, toDevices devices: [RemoteDevice]) -> Success {
        let deferred = Success()
        RustFirefoxAccounts.shared.accountManager.uponQueue(.main) { accountManager in
            guard let constellation = accountManager.deviceConstellation() else {
                deferred.fill(Maybe(failure: NoAccountError()))
                return
            }
            devices.forEach {
                if let id = $0.id {
                    constellation.sendEventToDevice(targetDeviceId: id, e: .sendTab(title: item.title ?? "", url: item.url))
                }
            }
            if let json = try? accountManager.gatherTelemetry() {
                let events = FxATelemetry.parseTelemetry(fromJSONString: json)
                events.forEach { $0.record(intoPrefs: self.prefs) }
            }
            self.sendQueuedSyncEvents()
            deferred.fill(Maybe(success: ()))
        }
        return deferred
    }

    public func setCommandArrived() {
        prefs.setTimestamp(0, forKey: PrefsKeys.PollCommandsTimestamp)
    }

    /// Polls for missed send tabs and handles them
    /// The method will not poll FxA if the interval hasn't passed
    /// See AppConstants.fxaCommandsInterval for the interval value
    public func pollCommands(forcePoll: Bool = false) {
        // We should only poll if the interval has passed to not
        // overwhelm FxA
        let lastPoll = self.prefs.timestampForKey(PrefsKeys.PollCommandsTimestamp)
        let now = Date.now()
        if let lastPoll = lastPoll, lastPoll != 0, !forcePoll, now - lastPoll < AppConstants.fxaCommandsInterval {
            return
        }
        self.prefs.setTimestamp(now, forKey: PrefsKeys.PollCommandsTimestamp)
        self.rustFxA.accountManager.upon { accountManager in
            accountManager.deviceConstellation()?.pollForCommands { commands in
                guard let commands = try? commands.get() else { return }
                let urls = commands.compactMap { command in
                    switch command {
                    case .tabReceived(_, let tabData):
                        let url = tabData.entries.last?.url ?? ""
                        return URL(string: url)
                    }
                }
                self.sendTabDelegate?.openSendTabs(for: urls)
            }
        }
    }

    lazy var logins: RustLogins = {
        let sqlCipherDatabasePath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("logins.db").path
        let databasePath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("loginsPerField.db").path

        return RustLogins(sqlCipherDatabasePath: sqlCipherDatabasePath, databasePath: databasePath)
    }()

    func hasSyncAccount(completion: @escaping (Bool) -> Void) {
        rustFxA.hasAccount { hasAccount in
            completion(hasAccount)
        }
    }

    func hasAccount() -> Bool {
        return rustFxA.hasAccount()
    }

    func hasSyncableAccount() -> Bool {
        return hasAccount() && !rustFxA.accountNeedsReauth()
    }

    var rustFxA: RustFirefoxAccounts {
        return RustFirefoxAccounts.shared
    }

    func removeAccount() {
        RustFirefoxAccounts.shared.disconnect()

        // Not available in extensions
        #if !MOZ_TARGET_NOTIFICATIONSERVICE && !MOZ_TARGET_SHARETO && !MOZ_TARGET_CREDENTIAL_PROVIDER
        unregisterRemoteNotifiation()
        #endif

        // remove Account Metadata
        prefs.removeObjectForKey(PrefsKeys.KeyLastRemoteTabSyncTime)

        // Save the keys that will be restored
        let rustAutofillKey = RustAutofillEncryptionKeys()
        let creditCardKey = keychain.string(forKey: rustAutofillKey.ccKeychainKey)
        let rustLoginsKeys = RustLoginEncryptionKeys()
        let perFieldKey = keychain.string(forKey: rustLoginsKeys.loginPerFieldKeychainKey)
        let sqlCipherKey = keychain.string(forKey: rustLoginsKeys.loginsUnlockKeychainKey)
        let sqlCipherSalt = keychain.string(forKey: rustLoginsKeys.loginPerFieldKeychainKey)

        // Remove all items, removal is not key-by-key specific (due to the risk of failing to delete something), simply restore what is needed.
        keychain.removeAllKeys()

        // Restore the keys that are still needed
        if let sqlCipherKey = sqlCipherKey {
            keychain.set(sqlCipherKey, forKey: rustLoginsKeys.loginsUnlockKeychainKey, withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)
        }

        if let sqlCipherSalt = sqlCipherSalt {
            keychain.set(sqlCipherSalt, forKey: rustLoginsKeys.loginsSaltKeychainKey, withAccessibility: MZKeychainItemAccessibility.afterFirstUnlock)
        }

        if let perFieldKey = perFieldKey {
            keychain.set(perFieldKey, forKey: rustLoginsKeys.loginPerFieldKeychainKey, withAccessibility: .afterFirstUnlock)
        }

        if let creditCardKey = creditCardKey {
            keychain.set(creditCardKey, forKey: rustAutofillKey.ccKeychainKey, withAccessibility: .afterFirstUnlock)
        }

        // Tell any observers that our account has changed.
        NotificationCenter.default.post(name: .FirefoxAccountChanged, object: nil)

        // Trigger cleanup. Pass in the account in case we want to try to remove
        // client-specific data from the server.
        self.syncManager.onRemovedAccount()
    }

    public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return logins.hasSyncedLogins()
    }

    // Profile exists in extensions, UIApp is unavailable there, make this code run for the main app only
    @available(iOSApplicationExtension, unavailable, message: "UIApplication.shared is unavailable in application extensions")
    private func unregisterRemoteNotifiation() {
        if let application = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication {
            application.unregisterForRemoteNotifications()
        }
    }

    class NoAccountError: MaybeErrorType {
        var description = "No account."
    }

    // Extends NSObject so we can use timers.
    public class BrowserSyncManager: NSObject, SyncManager {
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

        fileprivate var backgrounded = true
        private let logger: Logger

        deinit {
            if let c = constellationStateUpdate {
                NotificationCenter.default.removeObserver(c)
            }
        }

        public func applicationDidBecomeActive() {
            backgrounded = false

            guard self.profile.hasSyncableAccount() else { return }

            self.beginTimedSyncs()

            // Sync now if it's been more than our threshold.
            let now = Date.now()
            let then = self.lastSyncFinishTime ?? 0
            guard now >= then else {
                logger.log("Time was modified since last sync.",
                           level: .debug,
                           category: .sync)
                self.syncEverythingSoon()
                return
            }
            let since = now - then

            logger.log("\(since)msec since last sync.",
                       level: .debug,
                       category: .sync)
            if since > SyncConstants.SyncOnForegroundMinimumDelayMillis {
                self.syncEverythingSoon()
            }
        }

        public func applicationDidEnterBackground() {
            backgrounded = true
        }

        public var isSyncing: Bool {
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
            logger.log("Ending all queued syncs.",
                       level: .info,
                       category: .sync)

            syncDisplayState = SyncStatusResolver(engineResults: result.engineResults).resolveResults()

            #if MOZ_TARGET_CLIENT
                if canSendUsageData() {
                    SyncPing.from(
                        result: result,
                        remoteClientsAndTabs: profile.remoteClientsAndTabs,
                        prefs: prefs,
                        why: .schedule
                    ) {
                        guard let ping = $0 else { return }
                        SyncTelemetry.send(ping: ping, docType: .sync)
                    }
                } else {
                    logger.log("Profile isn't sending usage data. Not sending sync status event.",
                               level: .debug,
                               category: .sync)
                }
            #endif

            // Don't notify if we are performing a sync in the background. This prevents more db access from happening
            if !self.backgrounded {
                notifySyncing(notification: .ProfileDidFinishSyncing)
            }
            syncReducer = nil
        }

        func canSendUsageData() -> Bool {
            return profile.prefs.boolForKey(AppConstants.prefSendUsageData) ?? true
        }

        private func notifySyncing(notification: Notification.Name) {
            NotificationCenter.default.post(name: notification, object: syncDisplayState?.asObject())
        }

        init(profile: BrowserProfile,
             logger: Logger = DefaultLogger.shared) {
            self.profile = profile
            self.prefs = profile.prefs
            self.logger = logger

            super.init()

            let center = NotificationCenter.default

            center.addObserver(self, selector: #selector(onDatabaseWasRecreated), name: .DatabaseWasRecreated, object: nil)
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
                logger.log("Unknown database \(dbName).",
                           level: .debug,
                           category: .sync)
                return succeed()
            }
        }

        func doInBackgroundAfter(_ millis: Int64, _ block: @escaping () -> Void) {
            let queue = DispatchQueue.global(qos: DispatchQoS.background.qosClass)
            // Pretty ambiguous here. I'm thinking .now was DispatchTime.now() and not Date.now()
            queue.asyncAfter(deadline: DispatchTime.now() + DispatchTimeInterval.milliseconds(Int(millis)), execute: block)
        }

        @objc
        func onDatabaseWasRecreated(notification: NSNotification) {
            let name = notification.object as? String
            logger.log("Database was recreated with \(name ?? "nil").",
                       level: .debug,
                       category: .storage)

            // We run this in the background after a few hundred milliseconds;
            // it doesn't really matter when it runs, so long as it doesn't
            // happen in the middle of a sync.

            let resetDatabase = {
                return self.handleRecreationOfDatabaseNamed(name: name) >>== {
                    self.logger.log("Reset of \(name ?? "nil") done",
                                    level: .debug,
                                    category: .storage)
                }
            }

            self.doInBackgroundAfter(300) {
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

        @objc
        func onStartSyncing(_ notification: NSNotification) {
            syncDisplayState = .inProgress
        }

        @objc
        func onFinishSyncing(_ notification: NSNotification) {
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
                // When tabs and clients were managed in the same database, we reset them together so we're
                // continuting to do that here although it may no longer be necessary

                return self.profile.tabs.resetSync() >>> { ClientsSynchronizer.resetClientsWithStorage(self.profile.remoteClientsAndTabs, basePrefs: self.prefsForSync) }

            case "history":
                return self.profile.places.resetHistoryMetadata()
            case "passwords":
                return self.profile.logins.resetSync()
            case "forms":
                logger.log("Requested reset for forms, but this client doesn't sync them yet.",
                           level: .debug,
                           category: .sync)
                return succeed()
            case "addons":
                logger.log("Requested reset for addons, but this client doesn't sync them yet.",
                           level: .debug,
                           category: .sync)
                return succeed()
            case "prefs":
                logger.log("Requested reset for prefs, but this client doesn't sync them yet.",
                           level: .debug,
                           category: .sync)
                return succeed()
            default:
                logger.log("Asked to reset collection \(collection), which we don't know about.",
                           level: .warning,
                           category: .sync)
                return succeed()
            }
        }

        public func onRemovedAccount() -> Success {
            let profile = self.profile

            // Run these in order, because they might write to the same DB!

            let remove = [
                profile.remoteClientsAndTabs.onRemovedAccount,
                profile.logins.resetSync,
                profile.places.resetBookmarksMetadata,
                profile.places.resetHistoryMetadata,
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

        private func beginTimedSyncs() {
            if self.syncTimer != nil {
                logger.log("Already running sync timer.",
                           level: .debug,
                           category: .sync)
                return
            }

            let interval = FifteenMinutes
            let selector = #selector(syncOnTimer)
            logger.log("Starting sync timer.",
                       level: .info,
                       category: .sync)
            self.syncTimer = repeatingTimerAtInterval(interval, selector: selector)
        }

        /**
         * The caller is responsible for calling this on the same thread on which it called
         * beginTimedSyncs.
         */
        public func endTimedSyncs() {
            if let t = self.syncTimer {
                logger.log("Stopping sync timer.",
                           level: .info,
                           category: .sync)
                self.syncTimer = nil
                t.invalidate()
            }
        }

        fileprivate func syncClientsWithDelegate(prefs: Prefs, ready: Ready, why: OldSyncReason) -> OldSyncResult {
            logger.log("Syncing clients to storage.",
                       level: .info,
                       category: .sync)

            if constellationStateUpdate == nil {
                constellationStateUpdate = NotificationCenter.default.addObserver(forName: .constellationStateUpdate,
                                                                                  object: nil,
                                                                                  queue: .main) { [weak self] notification in
                    guard let accountManager = self?.profile.rustFxA.accountManager.peek(),
                          let state = accountManager.deviceConstellation()?.state(),
                          let self = self else { return }

                    let devices = state.remoteDevices.compactMap { device -> RemoteDevice? in
                        guard device.capabilities.contains(.sendTab) else { return nil }

                        let type = "\(device.deviceType)"
                        let lastAccessTime = device.lastAccessTime == nil ? nil : UInt64(clamping: device.lastAccessTime!)
                        return RemoteDevice(id: device.id,
                                            name: device.displayName,
                                            type: type,
                                            isCurrentDevice: device.isCurrentDevice,
                                            lastAccessTime: lastAccessTime,
                                            availableCommands: nil)
                    }
                    _ = self.profile.remoteClientsAndTabs.replaceRemoteDevices(devices)
                }
            }

            let clientSynchronizer = ready.synchronizer(ClientsSynchronizer.self, prefs: prefs, why: why)
            return clientSynchronizer.synchronizeLocalClients(
                self.profile.remoteClientsAndTabs,
                withServer: ready.client,
                info: ready.info
            ) >>== { result in
                guard case .completed = result, let accountManager = self.profile.rustFxA.accountManager.peek() else {
                    return deferMaybe(result)
                }
                self.logger.log("Updating FxA devices list.",
                                level: .debug,
                                category: .sync)
                accountManager.deviceConstellation()?.refreshState()
                return deferMaybe(result)
            }
        }

        public class ScopedKeyError: MaybeErrorType {
            public var description = "No key data found for scope."
        }

        public class SyncUnlockGetURLError: MaybeErrorType {
            public var description = "Failed to get token server endpoint url."
        }

        public class EncryptionKeyError: MaybeErrorType {
            public var description = "Failed to get stored key."
        }

        public class DeviceIdError: MaybeErrorType {
            public var description = "Failed to get deviceId."
        }

        fileprivate func syncUnlockInfo() -> Deferred<Maybe<SyncUnlockInfo>> {
            let syncUnlockInfo = Deferred<Maybe<SyncUnlockInfo>>()
            profile.rustFxA.accountManager.uponQueue(.main) { accountManager in
                guard let deviceId = accountManager.deviceConstellation()?.state()?.localDevice?.id else {
                    self.logger.log("Device Id could not be retrieved",
                                    level: .warning,
                                    category: .sync)
                    syncUnlockInfo.fill(Maybe(failure: DeviceIdError()))
                    return
                }

                accountManager.getAccessToken(scope: OAuthScope.oldSync) { result in
                    guard let accessTokenInfo = try? result.get(), let key = accessTokenInfo.key else {
                        syncUnlockInfo.fill(Maybe(failure: ScopedKeyError()))
                        return
                    }

                    accountManager.getTokenServerEndpointURL { result in
                        guard case .success(let tokenServerEndpointURL) = result else {
                            syncUnlockInfo.fill(Maybe(failure: SyncUnlockGetURLError()))
                            return
                        }

                        guard let encryptionKey = try? self.profile.logins.getStoredKey() else {
                            self.logger.log("Stored logins encryption could not be retrieved",
                                            level: .warning,
                                            category: .sync)
                            syncUnlockInfo.fill(Maybe(failure: EncryptionKeyError()))
                            return
                        }

                        syncUnlockInfo.fill( Maybe(success: SyncUnlockInfo(
                            kid: key.kid,
                            fxaAccessToken: accessTokenInfo.token,
                            syncKey: key.k,
                            tokenserverURL: tokenServerEndpointURL.absoluteString,
                            loginEncryptionKey: encryptionKey,
                            tabsLocalId: deviceId)))
                    }
                }
            }
            return syncUnlockInfo
        }

        fileprivate func syncLoginsWithDelegate(prefs: Prefs, ready: Ready, why: OldSyncReason) -> OldSyncResult {
            self.logger.log("Syncing logins to storage.",
                            level: .debug,
                            category: .sync)
            return syncUnlockInfo().bind({ result in
                guard let syncUnlockInfo = result.successValue else {
                    return deferMaybe(SyncStatus.notStarted(.unknown))
                }

                return self.profile.logins.syncLogins(unlockInfo: syncUnlockInfo).bind({ [weak self] result in
                    guard result.isSuccess else {
                        return deferMaybe(SyncStatus.notStarted(.unknown))
                    }

                    let syncEngineStatsSession = SyncEngineStatsSession(collection: "logins")
                    self?.profile.syncCredentialIdentities().upon { result in
                        self?.logger.log("Sync credentials result: \(result)",
                                         level: .debug,
                                         category: .sync)
                    }
                    return deferMaybe(SyncStatus.completed(syncEngineStatsSession))
                })
            })
        }

        fileprivate func syncBookmarksWithDelegate(prefs: Prefs, ready: Ready, why: OldSyncReason) -> OldSyncResult {
            logger.log("Syncing bookmarks to storage.",
                       level: .debug,
                       category: .storage)
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

        fileprivate func syncHistoryWithDelegate(prefs: Prefs, ready: Ready, why: OldSyncReason) -> OldSyncResult {
            logger.log("Syncing History to storage.",
                       level: .debug,
                       category: .storage)
            return syncUnlockInfo().bind({ result in
                guard let syncUnlockInfo = result.successValue else {
                    return deferMaybe(SyncStatus.notStarted(.unknown))
                }

                return self.profile.places.syncHistory(unlockInfo: syncUnlockInfo).bind({ result in
                    guard result.isSuccess else {
                        return deferMaybe(SyncStatus.notStarted(.unknown))
                    }

                    let syncEngineStatsSession = SyncEngineStatsSession(collection: "history")
                    return deferMaybe(SyncStatus.completed(syncEngineStatsSession))
                })
            })
        }

        fileprivate func syncTabsWithDelegate(prefs: Prefs, ready: Ready, why: OldSyncReason) -> OldSyncResult {
            logger.log("Syncing tabs to storage.",
                       level: .debug,
                       category: .storage)
            return syncUnlockInfo().bind({ result in
                guard let syncUnlockInfo = result.successValue else {
                    return deferMaybe(SyncStatus.notStarted(.unknown))
                }

                return self.profile.tabs.sync(unlockInfo: syncUnlockInfo).bind({ result in
                    guard result.isSuccess else {
                        return deferMaybe(SyncStatus.notStarted(.unknown))
                    }

                    let syncEngineStatsSession = SyncEngineStatsSession(collection: "tabs")
                    return deferMaybe(SyncStatus.completed(syncEngineStatsSession))
                })
            })
        }

        func takeActionsOnEngineStateChanges<T: EngineStateChanges>(_ changes: T) -> Deferred<Maybe<T>> {
            var needReset = Set<String>(changes.collectionsThatNeedLocalReset())
            needReset.formUnion(changes.enginesDisabled())
            needReset.formUnion(changes.enginesEnabled())
            if needReset.isEmpty {
                logger.log("No collections need reset. Moving on.",
                           level: .debug,
                           category: .sync)
                return deferMaybe(changes)
            }

            // needReset needs at most one of clients and tabs, because we reset them
            // both if either needs reset. This is strictly an optimization to avoid
            // doing duplicate work.
            if needReset.contains("clients") {
                if needReset.remove("tabs") != nil {
                    logger.log("Already resetting clients (and tabs); not bothering to also reset tabs again.",
                               level: .debug,
                               category: .sync)
                }
            }

            return walk(Array(needReset), f: self.locallyResetCollection)
               >>> effect(changes.clearLocalCommands)
               >>> always(changes)
        }

        /**
         * Runs the single provided synchronization function and returns its status.
         */
        fileprivate func sync(_ label: EngineIdentifier, function: @escaping SyncFunction) -> OldSyncResult {
            let syncSeveralItems: OldSyncResult = syncSeveral(why: .user, synchronizers: [(label, function)]) >>== { statuses in
                if let status = statuses.find({ label == $0.0 }) {
                    return deferMaybe(status.1)
                }
                return deferMaybe(.notStarted(.unknown))
            }

            return syncSeveralItems
        }

        /**
         * Convenience method for syncSeveral([(EngineIdentifier, SyncFunction)])
         */
        private func syncSeveral(why: OldSyncReason, synchronizers: (EngineIdentifier, SyncFunction)...) -> Deferred<Maybe<[(EngineIdentifier, SyncStatus)]>> {
            return syncSeveral(why: why, synchronizers: synchronizers)
        }

        func getProfileAndDeviceId() -> (MozillaAppServices.Profile, String)? {
            guard let fxa = RustFirefoxAccounts.shared.accountManager.peek(),
                  let profile = fxa.accountProfile(),
                  let deviceID = fxa.deviceConstellation()?.state()?.localDevice?.id
            else { return nil }

            return (profile, deviceID)
        }

        /**
         * Runs each of the provided synchronization functions with the same inputs.
         * Returns an array of IDs and SyncStatuses at least length as the input.
         * The statuses returned will be a superset of the ones that are requested here.
         * While a sync is ongoing, each engine from successive calls to this method will only be called once.
         */
        fileprivate func syncSeveral(why: OldSyncReason, synchronizers: [(EngineIdentifier, SyncFunction)]) -> Deferred<Maybe<[(EngineIdentifier, SyncStatus)]>> {
            guard let (profile, deviceID) = self.getProfileAndDeviceId() else {
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
                        self.logger.log("Nothing left to sync",
                                        level: .info,
                                        category: .sync)
                        return deferMaybe(statuses)
                    }

                    return self.syncWith(synchronizers: remaining, statsSession: statsSession, why: why) >>== { deferMaybe(statuses + $0) }
                }

                let gleanHelper = GleanSyncOperationHelper()

                reducer.terminal.upon { results in
                    let result = SyncOperationResult(
                        engineResults: results,
                        stats: statsSession.hasStarted() ? statsSession.end() : nil
                    )
                    self.endSyncing(result)
                    gleanHelper.end(result)
                }

                // The actual work of synchronizing doesn't start until we append
                // the synchronizers to the reducer below.
                self.syncReducer = reducer
                self.beginSyncing()
                gleanHelper.start()
            }

            let deferStatuses = { () -> Deferred<Maybe<[(EngineIdentifier, SyncStatus)]>> in
                let statuses = synchronizers.map {
                    ($0.0, SyncStatus.notStarted(.unknown))
                }
                return deferMaybe(statuses)
            }

            guard let syncReducer = syncReducer else {
                return deferStatuses()
            }

            do {
                return try syncReducer.append(synchronizers)
            } catch let error {
                logger.log("Synchronizers appended after sync was finished. This is a bug",
                           level: .warning,
                           category: .sync,
                           description: error.localizedDescription)
                return deferStatuses()
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
                    if self.prefsForSync.boolForKey(stateChangedPref) != nil,
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
                                  statsSession: SyncOperationStatsSession, why: OldSyncReason) -> Deferred<Maybe<[(EngineIdentifier, SyncStatus)]>> {
            logger.log("Syncing \(synchronizers.map { $0.0 })",
                       level: .info,
                       category: .sync)
            var authState = RustFirefoxAccounts.shared.syncAuthState
            if let enginesEnablements = self.engineEnablementChangesForAccount(),
               !enginesEnablements.isEmpty {
                authState.enginesEnablements = enginesEnablements
                logger.log("engines to enable: \(enginesEnablements.compactMap { $0.value ? $0.key : nil })",
                           level: .debug,
                           category: .sync)
                logger.log("engines to disable: \(enginesEnablements.compactMap { !$0.value ? $0.key : nil })",
                           level: .debug,
                           category: .sync)
            }

            let readyDeferred = SyncStateMachine(prefs: self.prefsForSync).toReady(authState)

            let function: (Prefs, Ready) -> Deferred<Maybe<[EngineStatus]>> = {syncPrefs, ready in
                let thunks = synchronizers.map { (i, f) in
                    return { () -> Deferred<Maybe<EngineStatus>> in
                        self.logger.log("Syncing \(i)…",
                                        level: .debug,
                                        category: .sync)
                        return f(syncPrefs, ready, why) >>== { deferMaybe((i, $0)) }
                    }
                }
                return accumulate(thunks)
            }

            return readyDeferred.bind { readyResult in
                guard let success = readyResult.successValue else {
                    return deferMaybe(readyResult.failureValue!)
                }
                return self.takeActionsOnEngineStateChanges(success) >>== { ready in
                    let updateEnginePref: (String, Bool) -> Void = { engine, enabled in
                        self.prefsForSync.setBool(enabled, forKey: "engine.\(engine).enabled")
                    }
                    ready.engineConfiguration?.enabled.forEach { updateEnginePref($0, true) }
                    ready.engineConfiguration?.declined.forEach { updateEnginePref($0, false) }

                    statsSession.start()
                    return function(self.prefsForSync, ready)
                }
            }
        }

        @discardableResult
        public func syncEverything(why: OldSyncReason) -> Success {
            if let accountManager = RustFirefoxAccounts.shared.accountManager.peek(), accountManager.accountMigrationInFlight() {
                accountManager.retryMigration { _ in }
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
                self.logger.log("Running delayed startup sync.",
                                level: .debug,
                                category: .sync)
                self.syncEverything(why: .startup)
            }
        }

        /**
         * Allows selective sync of different collections, for use by external APIs.
         * Some help is given to callers who use different namespaces (specifically: `passwords` is mapped to `logins`)
         * and to preserve some ordering rules.
         */
        public func syncNamedCollections(why: OldSyncReason, names: [String]) -> Success {
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

        @objc
        func syncOnTimer() {
            self.syncEverything(why: .scheduled)
            self.profile.pollCommands()
        }

        public func syncClients() -> OldSyncResult {
            // TODO: recognize .NotStarted.
            return self.sync("clients", function: syncClientsWithDelegate)
        }

        public func syncClientsThenTabs() -> OldSyncResult {
            // Previously we were making two separate `self.sync` calls, each of which
            // made a `self.syncSeveral` call. Because `self.syncSeveral` is meant to batch
            // engine syncs, this caused the second `self.sync` call (for the tabs engine)
            // to be cancelled as the first call for the clients engine was still running.
            // Here we are calling `self.syncSeveral` once for both engines to prevent
            // that from happening so the tabs engine syncing actually occurs.

            return self.syncSeveral(
                why: .user,
                synchronizers:
                ("clients", self.syncClientsWithDelegate),
                ("tabs", self.syncTabsWithDelegate)
            ) >>== { statuses in
                let status = statuses.find { "tabs" == $0.0 }
                return deferMaybe(status!.1)
            }
        }

        public func syncHistory() -> OldSyncResult {
            return self.sync("history", function: syncHistoryWithDelegate)
        }
    }
}
