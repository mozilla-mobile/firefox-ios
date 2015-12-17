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

public class MockSyncManager: SyncManager {
    public var isSyncing = false
    public var lastSyncFinishTime: Timestamp? = nil

    public func hasSyncedHistory() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }

    public func syncClients() -> SyncResult { return deferMaybe(.Completed) }
    public func syncClientsThenTabs() -> SyncResult { return deferMaybe(.Completed) }
    public func syncHistory() -> SyncResult { return deferMaybe(.Completed) }
    public func syncLogins() -> SyncResult { return deferMaybe(.Completed) }
    public func syncEverything() -> Success {
        return succeed()
    }

    public func beginTimedSyncs() {}
    public func endTimedSyncs() {}
    public func applicationDidBecomeActive() {
        self.beginTimedSyncs()
    }
    public func applicationDidEnterBackground() {
        self.endTimedSyncs()
    }

    public func onNewProfile() {
    }

    public func onAddedAccount() -> Success {
        return succeed()
    }
    public func onRemovedAccount(account: FirefoxAccount?) -> Success {
        return succeed()
    }

    public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }
}

public class MockTabQueue: TabQueue {
    public func addToQueue(tab: ShareItem) -> Success {
        return succeed()
    }

    public func getQueuedTabs() -> Deferred<Maybe<Cursor<ShareItem>>> {
        return deferMaybe(ArrayCursor<ShareItem>(data: []))
    }

    public func clearQueuedTabs() -> Success {
        return succeed()
    }
}

public class MockProfile: Profile {
    private let name: String = "mockaccount"

    func localName() -> String {
        return name
    }

    func shutdown() {
    }

    private var dbCreated = false
    lazy var db: BrowserDB = {
        self.dbCreated = true
        return BrowserDB(filename: "mock.db", files: self.files)
    }()

    /**
     * Favicons, history, and bookmarks are all stored in one intermeshed
     * collection of tables.
     */
    private lazy var places: protocol<BrowserHistory, Favicons, SyncableHistory, ResettableSyncStorage> = {
        return SQLiteHistory(db: self.db, prefs: MockProfilePrefs())!
    }()

    var favicons: Favicons {
        return self.places
    }

    lazy var queue: TabQueue = {
        return MockTabQueue()
    }()

    var history: protocol<BrowserHistory, SyncableHistory, ResettableSyncStorage> {
        return self.places
    }

    lazy var syncManager: SyncManager = {
        return MockSyncManager()
    }()

    lazy var bookmarks: protocol<BookmarksModelFactory, ShareToDestination, SyncableBookmarks> = {
        // Make sure the rest of our tables are initialized before we try to read them!
        // This expression is for side-effects only.
        let p = self.places

        return MergedSQLiteBookmarks(db: self.db)
    }()

    lazy var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs)
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

    internal lazy var remoteClientsAndTabs: RemoteClientsAndTabs = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    private lazy var syncCommands: SyncCommands = {
        return SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    lazy var logins: protocol<BrowserLogins, SyncableLogins, ResettableSyncStorage> = {
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

    func setAccount(account: FirefoxAccount) {
        self.account = account
        self.syncManager.onAddedAccount()
    }

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

    func storeTabs(tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    func sendItems(items: [ShareItem], toClients clients: [RemoteClient]) {
    }
}
