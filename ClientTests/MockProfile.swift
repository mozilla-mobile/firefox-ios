/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import Client
import Foundation
import Account
import ReadingList
import Shared
import Storage
import Sync
import XCTest
import Deferred

open class MockSyncManager: SyncManager {
    open var isSyncing = false
    open var lastSyncFinishTime: Timestamp?
    open var syncDisplayState: SyncDisplayState?

    open func hasSyncedHistory() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }

    private func completedWithStats(collection: String) -> Deferred<Maybe<SyncStatus>> {
        return deferMaybe(SyncStatus.completed(SyncEngineStatsSession(collection: collection)))
    }
    
    open func syncClients() -> SyncResult { return completedWithStats(collection: "mock_clients") }
    open func syncClientsThenTabs() -> SyncResult { return completedWithStats(collection: "mock_clientsandtabs") }
    open func syncHistory() -> SyncResult { return completedWithStats(collection: "mock_history") }
    open func syncLogins() -> SyncResult { return completedWithStats(collection: "mock_logins") }
    open func syncEverything(why: SyncReason) -> Success {
        return succeed()
    }

    open func beginTimedSyncs() {}
    open func endTimedSyncs() {}
    open func applicationDidBecomeActive() {
        self.beginTimedSyncs()
    }
    open func applicationDidEnterBackground() {
        self.endTimedSyncs()
    }

    open func onNewProfile() {
    }

    open func onAddedAccount() -> Success {
        return succeed()
    }
    open func onRemovedAccount(_ account: FirefoxAccount?) -> Success {
        return succeed()
    }

    open func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }
}

open class MockTabQueue: TabQueue {
    open func addToQueue(_ tab: ShareItem) -> Success {
        return succeed()
    }

    open func getQueuedTabs() -> Deferred<Maybe<Cursor<ShareItem>>> {
        return deferMaybe(ArrayCursor<ShareItem>(data: []))
    }

    open func clearQueuedTabs() -> Success {
        return succeed()
    }
}

open class MockProfile: Profile {
    fileprivate let name: String = "mockaccount"

    public func localName() -> String {
        return name
    }

    public func reopen() {
    }

    public func shutdown() {
    }

    public var isShutdown: Bool = false

    fileprivate var dbCreated = false
    lazy var db: BrowserDB = {
        self.dbCreated = true
        let db = BrowserDB(filename: "mock.db", files: self.files)
        db.attachDB(named: "metadata.db", as: AttachedDatabaseMetadata)
        return db
    }()

    /**
     * Favicons, history, and bookmarks are all stored in one intermeshed
     * collection of tables.
     */
    fileprivate lazy var places: BrowserHistory & Favicons & SyncableHistory & ResettableSyncStorage & HistoryRecommendations = {
        return SQLiteHistory(db: self.db, prefs: MockProfilePrefs())
    }()

    public var favicons: Favicons {
        return self.places
    }

    lazy public var queue: TabQueue = {
        return MockTabQueue()
    }()

    public var history: BrowserHistory & SyncableHistory & ResettableSyncStorage {
        return self.places
    }

    public var recommendations: HistoryRecommendations {
        return self.places
    }

    lazy public var metadata: Metadata = {
        return SQLiteMetadata(db: self.db)
    }()

    lazy public var isChinaEdition: Bool = {
        return Locale.current.identifier == "zh_CN"
    }()

    lazy public var syncManager: SyncManager = {
        return MockSyncManager()
    }()

    lazy public var certStore: CertStore = {
        return CertStore()
    }()

    lazy public var bookmarks: BookmarksModelFactorySource & KeywordSearchSource & SyncableBookmarks & LocalItemSource & MirrorItemSource & ShareToDestination = {
        // Make sure the rest of our tables are initialized before we try to read them!
        // This expression is for side-effects only.
        let p = self.places

        return MergedSQLiteBookmarks(db: self.db)
    }()

    lazy public var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs, files: self.files)
    }()

    lazy public var prefs: Prefs = {
        return MockProfilePrefs()
    }()

    lazy public var files: FileAccessor = {
        return ProfileFileAccessor(profile: self)
    }()

    lazy public var readingList: ReadingListService? = {
        return ReadingListService(profileStoragePath: self.files.rootPath as String)
    }()

    lazy public var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()

    internal lazy var remoteClientsAndTabs: RemoteClientsAndTabs = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    fileprivate lazy var syncCommands: SyncCommands = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    lazy public var logins: BrowserLogins & SyncableLogins & ResettableSyncStorage = {
        return MockLogins(files: self.files)
    }()

    public let accountConfiguration: FirefoxAccountConfiguration = ProductionFirefoxAccountConfiguration()
    var account: FirefoxAccount?

    public func hasAccount() -> Bool {
        return account != nil
    }

    public func hasSyncableAccount() -> Bool {
        return account?.actionNeeded == FxAActionNeeded.none
    }

    public func getAccount() -> FirefoxAccount? {
        return account
    }

    public func setAccount(_ account: FirefoxAccount) {
        self.account = account
        self.syncManager.onAddedAccount()
    }

    public func flushAccount() {}

    public func removeAccount() {
        let old = self.account
        self.account = nil
        self.syncManager.onRemovedAccount(old)
    }

    public func getClients() -> Deferred<Maybe<[RemoteClient]>> {
        return deferMaybe([])
    }

    public func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return deferMaybe([])
    }

    public func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return deferMaybe([])
    }

    public func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    public func sendItems(_ items: [ShareItem], toClients clients: [RemoteClient]) {
    }
}
