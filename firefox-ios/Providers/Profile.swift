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
import AuthenticationServices

import class MozillaAppServices.MZKeychainWrapper
import enum MozillaAppServices.Level
import enum MozillaAppServices.SyncReason
import enum MozillaAppServices.VisitType
import func MozillaAppServices.setLogger
import func MozillaAppServices.setMaxLevel
import struct MozillaAppServices.HistoryMigrationResult
import struct MozillaAppServices.SyncParams
import struct MozillaAppServices.SyncResult
import struct MozillaAppServices.VisitObservation
import struct MozillaAppServices.PendingCommand

public protocol SyncManager {
    var isSyncing: Bool { get }
    var lastSyncFinishTime: Timestamp? { get set }
    var syncDisplayState: SyncDisplayState? { get }

    func syncTabs() -> Deferred<Maybe<SyncResult>>
    func syncHistory() -> Deferred<Maybe<SyncResult>>
    func syncNamedCollections(why: SyncReason, names: [String]) -> Success
    @discardableResult
    func syncEverything(why: SyncReason) -> Success

    func endTimedSyncs()
    func applicationDidBecomeActive()
    func applicationDidEnterBackground()
    func checkCreditCardEngineEnablement() -> Bool

    @discardableResult
    func onRemovedAccount() -> Success
    @discardableResult
    func onAddedAccount() -> Success
    func updateCreditCardAutofillStatus(value: Bool)
}

/// This exists to pass in external context: e.g., the UIApplication can
/// expose notification functionality in this way.
public protocol FxACommandsDelegate: AnyObject {
    func openSendTabs(for urls: [URL])
    func closeTabs(for urls: [URL])
}

class ProfileFileAccessor: FileAccessor {
    convenience init(profile: Profile) {
        self.init(localName: profile.localName())
    }

    init(localName: String, logger: Logger = DefaultLogger.shared) {
        let profileDirName = "profile.\(localName)"

        // Bug 1147262: First option is for device, second is for simulator.
        var rootPath: String
        let sharedContainerIdentifier = AppInfo.sharedContainerIdentifier
        if let url = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: sharedContainerIdentifier
        ) {
            rootPath = url.path
        } else {
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
    var searchEnginesManager: SearchEnginesManager { get }
    #endif
    var files: FileAccessor { get }
    var pinnedSites: PinnedSites { get }
    var logins: RustLogins { get }
    var firefoxSuggest: RustFirefoxSuggestProtocol? { get }
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

    // I got really weird EXC_BAD_ACCESS errors on a non-null reference when I made this a getter. Similar to
    // <http://stackoverflow.com/questions/26029317/exc-bad-access-when-indirectly-accessing-inherited-member-in-swift>
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
    func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>>

    func getClientsAndTabs(completion: @escaping ([ClientAndTabs]?) -> Void)
    func getCachedClientsAndTabs(completion: @escaping ([ClientAndTabs]?) -> Void)

    func cleanupHistoryIfNeeded()

    @discardableResult
    func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>>

    func addTabToCommandQueue(_ deviceId: String, url: URL)
    func removeTabFromCommandQueue(_ deviceId: String, url: URL)
    func flushTabCommands(toDeviceId: String?)

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
    private lazy var directory: String = {
        do {
            return try self.files.getAndEnsureDirectory()
        } catch {
            logger.log("Could not create directory at root path: \(error)",
                       level: .fatal,
                       category: .setup)
            fatalError("Could not create directory at root path: \(error)")
        }
    }()
    fileprivate let name: String
    fileprivate let keychain: MZKeychainWrapper
    var isShutdown = false

    internal let files: FileAccessor

    let database: BrowserDB
    let readingListDB: BrowserDB
    var syncManager: SyncManager!

    var fxaCommandsDelegate: FxACommandsDelegate?

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
         fxaCommandsDelegate: FxACommandsDelegate? = nil,
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
        self.fxaCommandsDelegate = fxaCommandsDelegate

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
        self.database = BrowserDB(
            filename: "browser.db",
            schema: BrowserSchema(),
            files: files
        )
        self.readingListDB = BrowserDB(
            filename: "ReadingList.db",
            schema: ReadingListSchema(),
            files: files
        )

        if isNewProfile {
            logger.log("New profile. Removing old Keychain/Prefs data.",
                       level: .info,
                       category: .setup)
            MZKeychainWrapper.wipeKeychain()
            prefs.clearAll()
        }

        setLogger(logger: ForwardOnLog(logger: self.logger))
        setMaxLevel(level: Level.info)

        // Initiating the sync manager has to happen prior to the databases being opened,
        // because opening them can trigger events to which the SyncManager listens.
        self.syncManager = RustSyncManager(profile: self,
                                           creditCardAutofillEnabled: creditCardAutofillEnabled)

        let notificationCenter = NotificationCenter.default

        notificationCenter.addObserver(
            self,
            selector: #selector(onLocationChange),
            name: .OnLocationChange,
            object: nil
        )

        // Remove the default homepage. This does not change the user's preference,
        // just the behaviour when there is no homepage.
        prefs.removeObjectForKey(PrefsKeys.KeyDefaultHomePageURL)

        // Create the "Downloads" folder in the documents directory.
        if let downloadsPath = try? FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("Downloads").path {
            try? FileManager.default.createDirectory(
                atPath: downloadsPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        AppEventQueue.signal(event: .profileInitialized)
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
        let v = notification.userInfo!["visitType"] as? Int
        let visitType = VisitType.fromRawValue(rawValue: v)
        if let url = notification.userInfo!["url"] as? URL, !isIgnoredURL(url),
        let title = notification.userInfo!["title"] as? NSString {
            // Only record local vists if the change notification originated from a non-private tab
            if !(notification.userInfo!["isPrivate"] as? Bool ?? false) {
                let result = self.places.applyObservation(
                    visitObservation: VisitObservation(
                        url: url.description,
                        title: title as String,
                        visitType: visitType
                    )
                )
                result.upon { result in
                    guard result.isSuccess else {
                        self.logger.log(
                            result.failureValue?.localizedDescription ?? "Unknown error adding history visit",
                            level: .warning,
                            category: .sync
                        )
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

    lazy var browserDbPath = URL(
        fileURLWithPath: directory
    ).appendingPathComponent("browser.db").path
    lazy var placesDbPath = URL(
        fileURLWithPath: directory,
        isDirectory: true
    ).appendingPathComponent("places.db").path
    lazy var places = RustPlaces(databasePath: self.placesDbPath)

    public func migrateHistoryToPlaces(
        callback: @escaping (HistoryMigrationResult) -> Void,
        errCallback: @escaping (Error?) -> Void
    ) {
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

    lazy var tabsDbPath = URL(
        fileURLWithPath: directory,
        isDirectory: true
    ).appendingPathComponent("tabs.db").path

    lazy var tabs = RustRemoteTabs(databasePath: tabsDbPath)

    lazy var autofillDbPath = URL(
        fileURLWithPath: directory,
        isDirectory: true
    ).appendingPathComponent("autofill.db").path

    lazy var autofill = RustAutofill(databasePath: autofillDbPath)

    #if !MOZ_TARGET_NOTIFICATIONSERVICE && !MOZ_TARGET_SHARETO && !MOZ_TARGET_CREDENTIAL_PROVIDER
    lazy var searchEnginesManager: SearchEnginesManager = {
        return SearchEnginesManager(prefs: self.prefs, files: self.files)
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

    lazy var certStore: CertStore = {
        return CertStore()
    }()

    lazy var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()

    func retrieveTabData() -> Deferred<Maybe<[ClientAndTabs]>> {
        logger.log("Getting all tabs and clients", level: .debug, category: .tabs)

        guard let accountManager = self.rustFxA.accountManager,
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

    public func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return self.syncManager.syncTabs() >>> { self.retrieveTabData() }
    }

    public func getClientsAndTabs(completion: @escaping ([ClientAndTabs]?) -> Void) {
        let deferredResponse = self.syncManager.syncTabs() >>> { self.retrieveTabData() }
        deferredResponse.upon { result in
            completion(result.successValue)
        }
    }

    public func getCachedClientsAndTabs(completion: @escaping ([ClientAndTabs]?) -> Void) {
        let defferedResponse = self.retrieveTabData()
        defferedResponse.upon { result in
            completion(result.successValue)
        }
    }

    public func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return self.retrieveTabData()
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
    }

    func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return self.tabs.setLocalTabs(localTabs: tabs)
    }

    func addTabToCommandQueue(_ deviceId: String, url: URL) {
        tabs.addRemoteCommand(deviceId: deviceId, url: url)
    }

    func removeTabFromCommandQueue(_ deviceId: String, url: URL) {
        tabs.removeRemoteCommand(deviceId: deviceId, url: url)
    }

    public func sendItem(_ item: ShareItem, toDevices devices: [RemoteDevice]) -> Success {
        let deferred = Success()
        if let accountManager = RustFirefoxAccounts.shared.accountManager {
            guard let constellation = accountManager.deviceConstellation() else {
                deferred.fill(Maybe(failure: NoAccountError()))
                return deferred
            }
            devices.forEach {
                if let id = $0.id {
                    constellation.sendEventToDevice(
                        targetDeviceId: id,
                        e: .sendTab(title: item.title ?? "", url: item.url)
                    )
                }
            }
            self.sendQueuedSyncEvents()
            deferred.fill(Maybe(success: ()))
        }
        return deferred
    }

    public func flushTabCommands(toDeviceId: String?) {
        guard let deviceId = toDeviceId,
            let constellation = RustFirefoxAccounts.shared.accountManager?.deviceConstellation() else {
            return
        }

        // send all unsent close tab commands
        self.tabs.getUnsentCommandUrlsByDeviceId(deviceId: deviceId) { urls in
            constellation.sendEventToDevice(targetDeviceId: deviceId,
                                            e: .closeTabs(urls: urls)) { result in
                switch result {
                case .success:
                    // mark all pending tab commands as sent
                    self.tabs.setPendingCommandsSent(deviceId: deviceId)
                case .failure(.tabsNotClosed(let urls)):
                    // mark pending tab commands as sent excluding unsentUrls
                    self.tabs.setPendingCommandsSent(deviceId: deviceId, unsentCommandUrls: urls)
                default:
                    // technically this should not be possible here as a non-tabsNotClosed error would
                    // result after a sendTab sendEventToDevice call but we are covering this case to
                    // make the compiler happy
                    break
                }
            }
        }
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
        if let lastPoll = lastPoll,
           lastPoll != 0,
           lastPoll < now,
           !forcePoll,
           now - lastPoll < AppConstants.fxaCommandsInterval {
            return
        }
        self.prefs.setTimestamp(now, forKey: PrefsKeys.PollCommandsTimestamp)
        if let accountManager = self.rustFxA.accountManager {
            accountManager.deviceConstellation()?.pollForCommands { commands in
                guard let commands = try? commands.get() else { return }

                var receivedTabURLs: [URL] = []
                var closedTabURLs: [URL] = []
                for command in commands {
                    switch command {
                    case .tabReceived(_, let tabData):
                        if let urlString = tabData.entries.last?.url, let url = URL(string: urlString) {
                            receivedTabURLs.append(url)
                        }
                    case .tabsClosed(sender: _, let closeTabPayload):
                        closedTabURLs.append(contentsOf: closeTabPayload.urls.compactMap { URL(string: $0) })
                    }
                }
                if !receivedTabURLs.isEmpty {
                    self.fxaCommandsDelegate?.openSendTabs(for: receivedTabURLs)
                }

                if !closedTabURLs.isEmpty {
                    self.fxaCommandsDelegate?.closeTabs(for: closedTabURLs)
                }
            }
        }
    }

    lazy var logins: RustLogins = {
        let databasePath = URL(
            fileURLWithPath: directory,
            isDirectory: true
        ).appendingPathComponent("loginsPerField.db").path
        return RustLogins(databasePath: databasePath)
    }()

    lazy var firefoxSuggest: RustFirefoxSuggestProtocol? = {
        do {
            let cacheFileURL = try FileManager.default.url(
                for: .cachesDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("suggest.db", isDirectory: false)
            return try RustFirefoxSuggest(
                dataPath: URL(fileURLWithPath: directory, isDirectory: true).appendingPathComponent("suggest-data.db").path,
                cachePath: cacheFileURL.path
            )
        } catch {
            logger.log("Failed to open Firefox Suggest database: \(error.localizedDescription)",
                       level: .warning,
                       category: .storage)
            return nil
        }
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
        logger.log("Removing sync account", level: .debug, category: .sync)

        RustFirefoxAccounts.shared.disconnect()

        // Not available in extensions
        #if !MOZ_TARGET_NOTIFICATIONSERVICE && !MOZ_TARGET_SHARETO && !MOZ_TARGET_CREDENTIAL_PROVIDER
        unregisterRemoteNotifications()
        #endif

        // remove Account Metadata
        prefs.removeObjectForKey(PrefsKeys.KeyLastRemoteTabSyncTime)

        // Save the keys that will be restored
        let rustAutofillKey = RustAutofillEncryptionKeys()
        let creditCardKey = keychain.string(forKey: rustAutofillKey.ccKeychainKey)
        let rustLoginsKeys = RustLoginEncryptionKeys()
        let perFieldKey = keychain.string(forKey: rustLoginsKeys.loginPerFieldKeychainKey)
        // Remove all items, removal is not key-by-key specific (due to the risk of failing to delete something),
        // simply restore what is needed.
        keychain.removeAllKeys()

        if let perFieldKey = perFieldKey {
            keychain.set(
                perFieldKey,
                forKey: rustLoginsKeys.loginPerFieldKeychainKey,
                withAccessibility: .afterFirstUnlock
            )
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
    @available(
        iOSApplicationExtension,
        unavailable,
        message: "UIApplication.shared is unavailable in application extensions"
    )
    private func unregisterRemoteNotifications() {
        Task {
            do {
                let autopush = try await Autopush(files: files)
                // unsubscribe returns a boolean telling the caller if the subscription was already
                // unsubscribed, we ignore it because regardless the subscription is gone.
                _ = try await autopush.unsubscribe(scope: RustFirefoxAccounts.pushScope)
            } catch let error {
                logger.log("Unable to unsubscribe account push subscription",
                           level: .warning,
                           category: .sync,
                           description: error.localizedDescription
                )
            }
        }
        if let application = UIApplication.value(forKeyPath: #keyPath(UIApplication.shared)) as? UIApplication {
            application.unregisterForRemoteNotifications()
        }
    }

    class NoAccountError: MaybeErrorType {
        var description = "No account."
    }
}
