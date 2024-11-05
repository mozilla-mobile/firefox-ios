// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Foundation
import Shared
import Storage
import Sync
import XCTest

@testable import Client

import enum MozillaAppServices.SyncReason
import struct MozillaAppServices.SyncResult

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

final class MockTabQueue: TabQueue {
    var queuedTabs = [ShareItem]()
    var getQueuedTabsCalled = 0
    var addToQueueCalled = 0
    var clearQueuedTabsCalled = 0

    func addToQueue(_ tab: ShareItem) -> Success {
        addToQueueCalled += 1
        return succeed()
    }

    func getQueuedTabs(completion: @escaping ([ShareItem]) -> Void) {
        getQueuedTabsCalled += 1
        return completion(queuedTabs)
    }

    func clearQueuedTabs() -> Success {
        clearQueuedTabsCalled += 1
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

    public var files: FileAccessor
    public var syncManager: ClientSyncManager!
    public var firefoxSuggest: RustFirefoxSuggestProtocol?

    fileprivate let name: String = "mockaccount"

    private let directory: String
    private let databasePrefix: String

    init(databasePrefix: String = "mock", firefoxSuggest: RustFirefoxSuggestProtocol? = nil) {
        files = MockFiles()
        syncManager = ClientSyncManagerSpy()
        self.databasePrefix = databasePrefix
        self.firefoxSuggest = firefoxSuggest

        do {
            directory = try files.getAndEnsureDirectory()
        } catch {
            XCTFail("Could not create directory at root path: \(error)")
            fatalError("Could not create directory at root path: \(error)")
        }
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

    public lazy var queue: TabQueue = {
        return MockTabQueue()
    }()

    public lazy var isChinaEdition: Bool = {
        return Locale.current.identifier == "zh_CN"
    }()

    public lazy var certStore: CertStore = {
        return CertStore()
    }()

    public lazy var searchEnginesManager: SearchEnginesManager = {
        return SearchEnginesManager(prefs: self.prefs, files: self.files)
    }()

    public lazy var prefs: Prefs = {
        return MockProfilePrefs()
    }()

    public lazy var autofill: RustAutofill = {
        let autofillDbPath = URL(
            fileURLWithPath: directory,
            isDirectory: true
        ).appendingPathComponent("autofill.db").path
        return RustAutofill(databasePath: autofillDbPath)
    }()

    public lazy var readingList: ReadingList = {
        return SQLiteReadingList(db: self.readingListDB)
    }()

    public lazy var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()

    public lazy var logins: RustLogins = {
        let newLoginsDatabasePath = URL(
            fileURLWithPath: directory,
            isDirectory: true
        ).appendingPathComponent("\(databasePrefix)_loginsPerField.db").path
        try? files.remove("\(databasePrefix)_loginsPerField.db")

        let logins = RustLogins(databasePath: newLoginsDatabasePath)
        _ = logins.reopenIfClosed()

        return logins
    }()

    lazy var database: BrowserDB = {
        BrowserDB(filename: "\(databasePrefix).db", schema: BrowserSchema(), files: files)
    }()

    lazy var readingListDB: BrowserDB = {
        BrowserDB(filename: "\(databasePrefix)_ReadingList.db", schema: ReadingListSchema(), files: files)
    }()

    public lazy var places: RustPlaces = {
        let placesDatabasePath = URL(
            fileURLWithPath: directory,
            isDirectory: true
        ).appendingPathComponent("\(databasePrefix)_places.db").path
        try? files.remove("\(databasePrefix)_places.db")

        let places = RustPlaces(databasePath: placesDatabasePath)
        _ = places.reopenIfClosed()

        return places
    }()

    public lazy var tabs: RustRemoteTabs = {
        let tabsDbPath = URL(
            fileURLWithPath: directory,
            isDirectory: true
        ).appendingPathComponent("\(databasePrefix)_tabs.db").path
        let tabs = RustRemoteTabs(databasePath: tabsDbPath)

        return tabs
    }()

    fileprivate lazy var legacyPlaces: PinnedSites = {
        BrowserDBSQLite(database: self.database, prefs: MockProfilePrefs())
    }()

    public lazy var pinnedSites: PinnedSites = {
        legacyPlaces
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

    public func getCachedClientsAndTabs(completion: @escaping ([ClientAndTabs]?) -> Void) {
        completion(mockClientAndTabs)
    }

    public func getClientsAndTabs(completion: @escaping ([ClientAndTabs]?) -> Void) {
        completion(mockClientAndTabs)
    }

    public func cleanupHistoryIfNeeded() {}

    public func storeTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        return deferMaybe(0)
    }

    public func addTabToCommandQueue(_ deviceId: String, url: URL) {
        return
    }

    public func removeTabFromCommandQueue(_ deviceId: String, url: URL) {
        return
    }

    public func flushTabCommands(toDeviceId: String?) {
        return
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
