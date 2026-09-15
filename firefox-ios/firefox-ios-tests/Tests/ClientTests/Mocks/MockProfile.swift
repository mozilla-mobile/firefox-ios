// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Account
import Foundation
import Shared
import Storage
import XCTest
import Common

@testable import Client

import enum MozillaAppServices.SyncReason
import struct MozillaAppServices.SyncResult
import class MozillaAppServices.RemoteSettingsService

public typealias ClientSyncManager = Client.SyncManager

open class ClientSyncManagerSpy: ClientSyncManager, @unchecked Sendable {
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

    var syncNamedCollectionsCalled = 0
    open func syncNamedCollections(why: SyncReason, names: [String]) -> Deferred<Maybe<SyncResult>> {
        syncNamedCollectionsCalled += 1
        return emptySyncResult
    }
    var syncPostSyncSettingsChangeCalled = 0
    open func syncPostSyncSettingsChange(why: SyncReason, names: [String]) {
        syncPostSyncSettingsChangeCalled += 1
    }
    open func reportOpenSyncSettingsMenuTelemetry() {}
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

final class MockTabQueue: TabQueue, @unchecked Sendable {
    var queuedTabs = [ShareItem]()
    var getQueuedTabsCalled = 0
    var addToQueueCalled = 0
    var clearQueuedTabsCalled = 0

    func addToQueue(_ tab: ShareItem) -> Success {
        addToQueueCalled += 1
        return succeed()
    }

    func getQueuedTabs(completion: @MainActor @escaping ([ShareItem]) -> Void) {
        Task { @MainActor in
            completion(queuedTabs)
            getQueuedTabsCalled += 1
        }
    }

    func clearQueuedTabs() -> Success {
        clearQueuedTabsCalled += 1
        return succeed()
    }
}

/// Runs `body` with a fresh profile, then shuts it down and removes its directory, so
/// cleanup does not depend on when ARC releases the profile.
func withMockProfile<T>(_ body: (MockProfile) async throws -> T) async throws -> T {
    let profile = MockProfile()
    defer {
        profile.removeDirectory()
    }
    return try await body(profile)
}

extension XCTestCase {
    /// The XCTest form of `withMockProfile`: shutdown and directory removal run in teardown.
    func makeProfile(
        firefoxSuggest: RustFirefoxSuggestProtocol? = nil,
        injectedPinnedSites: MockablePinnedSites? = nil
    ) -> MockProfile {
        let profile = MockProfile(firefoxSuggest: firefoxSuggest, injectedPinnedSites: injectedPinnedSites)
        addTeardownBlock {
            profile.removeDirectory()
        }
        return profile
    }
}

// TODO: FXIOS-12610 Profile should be refactored so it is **not** `Sendable`.
final class MockProfile: Client.Profile, @unchecked Sendable {
    public var rustFxA: RustFirefoxAccounts {
        return RustFirefoxAccounts.shared
    }

    // Read/Writeable properties for mocking

    public var files: FileAccessor { temporaryFiles }
    public let syncManager: ClientSyncManager?
    public let firefoxSuggest: RustFirefoxSuggestProtocol?
    public let remoteSettingsService: RemoteSettingsService
    public let mockNotificationCenter: NotificationProtocol = MockNotificationCenter()

    fileprivate let name = "mockaccount"

    private let temporaryFiles = TemporaryFiles(ownsRoot: true)
    private let databases = DatabaseRegistry()
    private let injectedPinnedSites: MockablePinnedSites?

    init(
        firefoxSuggest: RustFirefoxSuggestProtocol? = nil,
        remoteSettingsService: RemoteSettingsService = RemoteSettingsService(unsafeFromHandle: 0),
        injectedPinnedSites: MockablePinnedSites? = nil
    ) {
        syncManager = ClientSyncManagerSpy()
        self.firefoxSuggest = firefoxSuggest
        self.remoteSettingsService = remoteSettingsService
        self.injectedPinnedSites = injectedPinnedSites
    }

    deinit {
        shutdown()
    }

    public func localName() -> String {
        return name
    }

    public func reopen() {
        databases.reopen()
    }

    public func shutdown() {
        databases.shutdown()
    }

    public var isShutdown: Bool { databases.isShutdown }

    /// Whether Places has created its database, checked without initializing the lazy `places`.
    var hasCreatedPlacesDatabase: Bool {
        temporaryFiles.exists("places.db")
    }

    fileprivate func removeDirectory() {
        shutdown()
        temporaryFiles.removeRoot()
    }

    public lazy var queue: TabQueue = {
        return MockTabQueue()
    }()

    public lazy var isChinaEdition: Bool = {
        return Locale.current.identifier == "zh_CN"
    }()

    public lazy var certStore: CertStore = {
        return CertStore()
    }()

    public lazy var prefs: Prefs = {
        return MockProfilePrefs()
    }()

    public lazy var autofill: RustAutofill = databases.trackLifecycle(
        of: RustAutofill(databasePath: temporaryFiles.pathEnsuringRoot(for: "autofill.db"))
    )

    public lazy var readingList: ReadingList = {
        return SQLiteReadingList(db: self.readingListDB)
    }()

    public lazy var recentlyClosedTabs: ClosedTabsStore = {
        return ClosedTabsStore(prefs: self.prefs)
    }()

    public lazy var logins: RustLogins = databases.trackLifecycle(
        of: RustLogins(databasePath: temporaryFiles.pathEnsuringRoot(for: "loginsPerField.db"))
    )

    lazy var database: BrowserDB = databases.trackLifecycle(
        of: BrowserDB(filename: "browser.db", schema: BrowserSchema(), files: files)
    )

    lazy var readingListDB: BrowserDB = databases.trackLifecycle(
        of: BrowserDB(filename: "ReadingList.db", schema: ReadingListSchema(), files: files)
    )

    public lazy var places: RustPlaces = databases.trackLifecycle(
        of: RustPlaces(databasePath: temporaryFiles.pathEnsuringRoot(for: "places.db"),
                       notificationCenter: mockNotificationCenter)
    )

    public lazy var tabs: RustRemoteTabs = databases.trackLifecycle(
        of: RustRemoteTabs(databasePath: temporaryFiles.pathEnsuringRoot(for: "tabs.db"))
    )

    fileprivate lazy var legacyPlaces: PinnedSites = {
        BrowserDBSQLite(database: self.database, prefs: MockProfilePrefs())
    }()

    public lazy var pinnedSites: PinnedSites = {
        injectedPinnedSites ?? legacyPlaces
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
        self.syncManager?.onRemovedAccount()
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

    var storeAndSyncTabsCalled = 0
    public func storeAndSyncTabs(_ tabs: [RemoteTab]) -> Deferred<Maybe<Int>> {
        storeAndSyncTabsCalled += 1
        return deferMaybe(0)
    }

    public func addTabToCommandQueue(_ deviceId: String, url: URL) {
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
