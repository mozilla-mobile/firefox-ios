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
    open var lastSyncFinishTime: Timestamp? = nil
    open var syncDisplayState: SyncDisplayState?

    open func hasSyncedHistory() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }

    open func syncClients() -> SyncResult { return deferMaybe(.Completed) }
    open func syncClientsThenTabs() -> SyncResult { return deferMaybe(.Completed) }
    open func syncHistory() -> SyncResult { return deferMaybe(.Completed) }
    open func syncLogins() -> SyncResult { return deferMaybe(.Completed) }
    open func syncEverything() -> Success {
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

    func localName() -> String {
        return name
    }

    func reopen() {
    }

    func shutdown() {
    }

    var isShutdown: Bool = false

    fileprivate var dbCreated = false
    lazy var db: BrowserDB = {
        self.dbCreated = true
        return BrowserDB(filename: "mock.db", files: self.files)
    }()

    /**
     * Favicons, history, and bookmarks are all stored in one intermeshed
     * collection of tables.
     */
    fileprivate lazy var places: BrowserHistory & Favicons & SyncableHistory & ResettableSyncStorage & HistoryRecommendations = {
        return SQLiteHistory(db: self.db, prefs: MockProfilePrefs())
    }()

    var favicons: Favicons {
        return self.places
    }

    lazy var queue: TabQueue = {
        return MockTabQueue()
    }()

    var history: BrowserHistory & SyncableHistory & ResettableSyncStorage {
        return self.places
    }

    var recommendations: HistoryRecommendations {
        return self.places
    }

    lazy var metadata: Metadata = {
        return SQLiteMetadata(db: self.db)
    }()

    lazy var isChinaEdition: Bool = {
        return Locale.current.identifier == "zh_CN"
    }()

    lazy var syncManager: SyncManager = {
        return MockSyncManager()
    }()

    lazy var certStore: CertStore = {
        return CertStore()
    }()

    lazy var bookmarks: BookmarksModelFactorySource & KeywordSearchSource & SyncableBookmarks & LocalItemSource & MirrorItemSource & ShareToDestination = {
        // Make sure the rest of our tables are initialized before we try to read them!
        // This expression is for side-effects only.
        let p = self.places

        return MergedSQLiteBookmarks(db: self.db)
    }()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs, files: self.files)
    }()

    lazy var prefs: Prefs = {
        return MockProfilePrefs()
    }()

    lazy var files: FileAccessor = {
        return ProfileFileAccessor(profile: self)
    }()

    lazy var readingList: ReadingListService? = {
        return ReadingListService(profileStoragePath: self.files.rootPath as String)
    }()

    lazy var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()

    internal lazy var remoteClientsAndTabs: RemoteClientsAndTabs = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    fileprivate lazy var syncCommands: SyncCommands = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    lazy var logins: BrowserLogins & SyncableLogins & ResettableSyncStorage = {
        return MockLogins(files: self.files)
    }()

    let accountConfiguration: FirefoxAccountConfiguration = ProductionFirefoxAccountConfiguration()
    var account: FirefoxAccount? = nil

    func hasAccount() -> Bool {
        return account != nil
    }

    func hasSyncableAccount() -> Bool {
        return account?.actionNeeded == FxAActionNeeded.None
    }

    func getAccount() -> FirefoxAccount? {
        return account
    }

    func setAccount(_ account: FirefoxAccount) {
        self.account = account
        self.syncManager.onAddedAccount()
    }

    func flushAccount() {}

    func removeAccount() {
        let old = self.account
        self.account = nil
        self.syncManager.onRemovedAccount(old)
    }

    func getClients() -> Deferred<Maybe<[RemoteClient]>> {
        return deferMaybe([])
    }

    func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return deferMaybe([])
    }

    func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return deferMaybe([])
    }

    func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    func sendItems(_ items: [ShareItem], toClients clients: [RemoteClient]) {
    }
}
