// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

@testable import Client
import Foundation
import Account
import Shared
import Storage
import Sync
import XCTest

open class MockSyncManager: SyncManager {
    open var isSyncing = false
    open var lastSyncFinishTime: Timestamp?
    open var syncDisplayState: SyncDisplayState?

    open func hasSyncedHistory() -> Deferred<Maybe<Bool>> {
        deferMaybe(true)
    }

    private func completedWithStats(collection: String) -> Deferred<Maybe<SyncStatus>> {
        deferMaybe(SyncStatus.completed(SyncEngineStatsSession(collection: collection)))
    }

    open func syncClients() -> SyncResult {
        completedWithStats(collection: "mock_clients")
    }
    open func syncClientsThenTabs() -> SyncResult {
        completedWithStats(collection: "mock_clientsandtabs")
    }
    open func syncHistory() -> SyncResult {
        completedWithStats(collection: "mock_history")
    }
    open func syncLogins() -> SyncResult {
        completedWithStats(collection: "mock_logins")
    }
    open func syncBookmarks() -> SyncResult {
        completedWithStats(collection: "mock_bookmarks")
    }
    open func syncEverything(why: SyncReason) -> Success {
        succeed()
    }
    open func syncNamedCollections(why: SyncReason, names: [String]) -> Success {
        succeed()
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
        succeed()
    }
    open func onRemovedAccount() -> Success {
        succeed()
    }

    open func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        deferMaybe(true)
    }
}

open class MockTabQueue: TabQueue {
    open func addToQueue(_ tab: ShareItem) -> Success {
        succeed()
    }

    open func getQueuedTabs() -> Deferred<Maybe<Cursor<ShareItem>>> {
        deferMaybe(ArrayCursor<ShareItem>(data: []))
    }

    open func clearQueuedTabs() -> Success {
        succeed()
    }
}

class MockFiles: FileAccessor {
    init() {
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        super.init(rootPath: (docPath as NSString).appendingPathComponent("testing"))
    }
}

open class MockProfile: Client.Profile {
    public var rustFxA: RustFirefoxAccounts {
        RustFirefoxAccounts.shared
    }

    // Read/Writeable properties for mocking
    public var recommendations: HistoryRecommendations
    public var places: RustPlaces
    public var tabs: RustRemoteTabs
    public var files: FileAccessor
    public var history: BrowserHistory & SyncableHistory & ResettableSyncStorage
    public var logins: RustLogins
    public var syncManager: SyncManager!

    fileprivate var legacyPlaces: BrowserHistory & Favicons & SyncableHistory & ResettableSyncStorage & HistoryRecommendations

    var db: BrowserDB
    var readingListDB: BrowserDB

    fileprivate let name: String = "mockaccount"

    init(databasePrefix: String = "mock") {
        files = MockFiles()
        syncManager = MockSyncManager()

        let oldLoginsDatabasePath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("\(databasePrefix)_logins.db").path
        try? files.remove("\(databasePrefix)_logins.db")

        let newLoginsDatabasePath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("\(databasePrefix)_loginsPerField.db").path
        try? files.remove("\(databasePrefix)_loginsPerField.db")

        logins = RustLogins(sqlCipherDatabasePath: oldLoginsDatabasePath, databasePath: newLoginsDatabasePath)
        _ = logins.reopenIfClosed()
        db = BrowserDB(filename: "\(databasePrefix).db", schema: BrowserSchema(), files: files)
        readingListDB = BrowserDB(filename: "\(databasePrefix)_ReadingList.db", schema: ReadingListSchema(), files: files)
        let placesDatabasePath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("\(databasePrefix)_places.db").path
        places = RustPlaces(databasePath: placesDatabasePath)

        let tabsDbPath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("\(databasePrefix)_tabs.db").path

        tabs = RustRemoteTabs(databasePath: tabsDbPath)

        legacyPlaces = SQLiteHistory(db: self.db, prefs: MockProfilePrefs())
        recommendations = legacyPlaces
        history = legacyPlaces
    }

    public func localName() -> String {
        name
    }

    public func _reopen() {
        isShutdown = false

        db.reopenIfClosed()
        _ = logins.reopenIfClosed()
        _ = places.reopenIfClosed()
        _ = tabs.reopenIfClosed()
    }

    public func _shutdown() {
        isShutdown = true

        db.forceClose()
        _ = logins.forceClose()
        _ = places.forceClose()
        _ = tabs.forceClose()
    }

    public var isShutdown: Bool = false

    public var favicons: Favicons {
        self.legacyPlaces
    }

    lazy public var queue: TabQueue = {
        MockTabQueue()
    }()

    lazy public var metadata: Metadata = {
        SQLiteMetadata(db: self.db)
    }()

    lazy public var isChinaEdition: Bool = {
        Locale.current.identifier == "zh_CN"
    }()

    lazy public var certStore: CertStore = {
        CertStore()
    }()

    lazy public var searchEngines: SearchEngines = {
        SearchEngines(prefs: self.prefs, files: self.files)
    }()

    lazy public var prefs: Prefs = {
        MockProfilePrefs()
    }()

    lazy public var readingList: ReadingList = {
        SQLiteReadingList(db: self.readingListDB)
    }()

    lazy public var recentlyClosedTabs: ClosedTabsStore = {
        ClosedTabsStore(prefs: self.prefs)
    }()

    internal lazy var remoteClientsAndTabs: RemoteClientsAndTabs = {
        SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    fileprivate lazy var syncCommands: SyncCommands = {
        SQLiteRemoteClientsAndTabs(db: self.db)
    }()

    public func hasAccount() -> Bool {
        true
    }

    var hasSyncableAccountMock: Bool = true
    public func hasSyncableAccount() -> Bool {
        hasSyncableAccountMock
    }

    public func flushAccount() {}

    public func removeAccount() {
        self.syncManager.onRemovedAccount()
    }

    public func getClients() -> Deferred<Maybe<[RemoteClient]>> {
        deferMaybe([])
    }

    public func getCachedClients() -> Deferred<Maybe<[RemoteClient]>> {
        deferMaybe([])
    }

    public func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        deferMaybe([])
    }

    var mockClientAndTabs = [ClientAndTabs]()
    public func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        deferMaybe(mockClientAndTabs)
    }

    public func cleanupHistoryIfNeeded() {}

    public func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        deferMaybe(0)
    }

    public func sendItem(_ item: ShareItem, toDevices devices: [RemoteDevice]) -> Success {
        succeed()
    }

    public func sendQueuedSyncEvents() {}
}
