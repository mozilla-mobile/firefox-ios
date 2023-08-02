// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client
import Foundation
import Account
import Shared
import Storage
import Sync
import XCTest

public typealias ClientSyncManager = Client.SyncManager

open class ClientSyncManagerSpy: ClientSyncManager {
    open var isSyncing = false
    open var lastSyncFinishTime: Timestamp?
    open var syncDisplayState: SyncDisplayState?

    private var mockDeclinedEngines: [String]?
    private var mockEngineEnabled = false
    private var emptySyncResult = deferMaybe(SyncResult(status: .ok,
                                                        successful: [],
                                                        failures: [:],
                                                        persistedState: "",
                                                        declined: nil,
                                                        nextSyncAllowedAt: nil,
                                                        telemetryJson: nil))

    open func syncTabs() -> Deferred<Maybe<SyncResult>> { return emptySyncResult }
    open func syncHistory() -> Deferred<Maybe<SyncResult>> { return emptySyncResult }
    open func syncEverything(why: SyncReason) -> Success { return succeed() }
    open func updateCreditCardAutofillStatus(value: Bool) {}

    var syncNamedCollectionsCalled = 0
    open func syncNamedCollections(why: SyncReason, names: [String]) -> Success {
        syncNamedCollectionsCalled += 1
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

    open func onAddedAccount() -> Success {
        return succeed()
    }
    open func onRemovedAccount() -> Success {
        return succeed()
    }
    open func checkCreditCardEngineEnablement() -> Bool {
        guard let mockDeclinedEngines = mockDeclinedEngines,
              !mockDeclinedEngines.isEmpty,
              mockDeclinedEngines.contains("creditcards") else {
            return mockEngineEnabled
        }
        return false
    }

    func setMockDeclinedEngines(_ engines: [String]?) {
        mockDeclinedEngines = engines
    }

    func setMockEngineEnabled(_ enabled: Bool) {
        mockEngineEnabled = enabled
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

class MockFiles: FileAccessor {
    init() {
        let docPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        super.init(rootPath: (docPath as NSString).appendingPathComponent("testing"))
    }
}

open class MockProfile: Client.Profile {
    public var rustFxA: RustFirefoxAccounts {
        return RustFirefoxAccounts.shared
    }

    // Read/Writeable properties for mocking
    public var places: RustPlaces
    public var tabs: RustRemoteTabs
    public var files: FileAccessor
    public var logins: RustLogins
    public var syncManager: ClientSyncManager!

    fileprivate var legacyPlaces: PinnedSites

    public var pinnedSites: PinnedSites

    var database: BrowserDB
    var readingListDB: BrowserDB

    fileprivate let name: String = "mockaccount"

    init(databasePrefix: String = "mock") {
        files = MockFiles()
        syncManager = ClientSyncManagerSpy()

        let oldLoginsDatabasePath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("\(databasePrefix)_logins.db").path
        try? files.remove("\(databasePrefix)_logins.db")

        let newLoginsDatabasePath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("\(databasePrefix)_loginsPerField.db").path
        try? files.remove("\(databasePrefix)_loginsPerField.db")

        logins = RustLogins(sqlCipherDatabasePath: oldLoginsDatabasePath, databasePath: newLoginsDatabasePath)
        _ = logins.reopenIfClosed()
        database = BrowserDB(filename: "\(databasePrefix).db", schema: BrowserSchema(), files: files)
        readingListDB = BrowserDB(filename: "\(databasePrefix)_ReadingList.db", schema: ReadingListSchema(), files: files)
        let placesDatabasePath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("\(databasePrefix)_places.db").path
        try? files.remove("\(databasePrefix)_places.db")

        places = RustPlaces(databasePath: placesDatabasePath)
        _ = places.reopenIfClosed()

        let tabsDbPath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("\(databasePrefix)_tabs.db").path

        tabs = RustRemoteTabs(databasePath: tabsDbPath)

        legacyPlaces = BrowserDBSQLite(database: self.database, prefs: MockProfilePrefs())

        pinnedSites = legacyPlaces
    }

    public func localName() -> String {
        return name
    }

    public func reopen() {
        isShutdown = false

        database.reopenIfClosed()
        _ = logins.reopenIfClosed()
        _ = places.reopenIfClosed()
        _ = tabs.reopenIfClosed()
    }

    public func shutdown() {
        isShutdown = true

        database.forceClose()
        _ = logins.forceClose()
        _ = places.forceClose()
        _ = tabs.forceClose()
    }

    public var isShutdown = false

    lazy public var queue: TabQueue = {
        return MockTabQueue()
    }()

    lazy public var metadata: Metadata = {
        return SQLiteMetadata(db: self.database)
    }()

    lazy public var isChinaEdition: Bool = {
        return Locale.current.identifier == "zh_CN"
    }()

    lazy public var certStore: CertStore = {
        return CertStore()
    }()

    lazy public var searchEngines: SearchEngines = {
        return SearchEngines(prefs: self.prefs, files: self.files)
    }()

    lazy public var prefs: Prefs = {
        return MockProfilePrefs()
    }()

    lazy var autofillDbPath = URL(fileURLWithPath: (try! files.getAndEnsureDirectory()), isDirectory: true).appendingPathComponent("autofill.db").path
    lazy public var autofill = RustAutofill(databasePath: autofillDbPath)

    lazy public var readingList: ReadingList = {
        return SQLiteReadingList(db: self.readingListDB)
    }()

    lazy public var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()

    public func hasSyncAccount(completion: @escaping (Bool) -> Void) {
        completion(hasSyncableAccountMock)
    }

    public func hasAccount() -> Bool {
        return hasSyncableAccountMock
    }

    var hasSyncableAccountMock = true
    public func hasSyncableAccount() -> Bool {
        return hasSyncableAccountMock
    }

    public func flushAccount() {}

    public func removeAccount() {
        self.syncManager.onRemovedAccount()
    }

    public func getCachedClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return deferMaybe(mockClientAndTabs)
    }

    public func getClientsAndTabs() -> Deferred<Maybe<[ClientAndTabs]>> {
        return deferMaybe([])
    }

    var mockClientAndTabs = [ClientAndTabs]()

    public func getCachedClientsAndTabs(completion: @escaping ([ClientAndTabs]) -> Void) {
        completion(mockClientAndTabs)
    }

    public func cleanupHistoryIfNeeded() {}

    public func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    public func sendItem(_ item: ShareItem, toDevices devices: [RemoteDevice]) -> Success {
        return succeed()
    }

    public func setCommandArrived() {
        return
    }

    public func pollCommands(forcePoll: Bool) {
        return
    }

    public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }
}
