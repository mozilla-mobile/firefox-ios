/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@testable import MozillaRustComponents
@testable import MozillaAppServices

import Glean
import XCTest

class SyncManagerTelemetryTests: XCTestCase {
    private var now: Int64 = 0

    override func setUp() {
        super.setUp()

        // Due to recent changes in how upload enabled works, we need to register the custom
        // Sync pings before they can collect data in tests.
        // See https://bugzilla.mozilla.org/show_bug.cgi?id=1935001 for more info.
        Glean.shared.registerPings(GleanMetrics.Pings.shared.sync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.historySync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.bookmarksSync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.loginsSync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.creditcardsSync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.addressesSync)
        Glean.shared.registerPings(GleanMetrics.Pings.shared.tabsSync)

        Glean.shared.resetGlean(clearStores: true)

        now = Int64(Date().timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC
    }

    func testSendsLoginsHistoryAndGlobalPings() {
        var globalSyncUuid = UUID()
        let syncTelemetry = RustSyncTelemetryPing(version: 1,
                                                  uid: "abc123",
                                                  events: [],
                                                  syncs: [SyncInfo(at: now,
                                                                   took: 10000,
                                                                   engines: [EngineInfo(name: "passwords",
                                                                                        at: now,
                                                                                        took: 5000,
                                                                                        incoming: IncomingInfo(applied: 5,
                                                                                                               failed: 4,
                                                                                                               newFailed: 3,
                                                                                                               reconciled: 2),
                                                                                        outgoing: [OutgoingInfo(sent: 10,
                                                                                                                failed: 5),
                                                                                                   OutgoingInfo(sent: 4,
                                                                                                                failed: 2)],
                                                                                        failureReason: nil,
                                                                                        validation: nil),
                                                                             EngineInfo(name: "history",
                                                                                        at: now,
                                                                                        took: 5000,
                                                                                        incoming: IncomingInfo(applied: 5,
                                                                                                               failed: 4,
                                                                                                               newFailed: 3,
                                                                                                               reconciled: 2),
                                                                                        outgoing: [OutgoingInfo(sent: 10,
                                                                                                                failed: 5),
                                                                                                   OutgoingInfo(sent: 4,
                                                                                                                failed: 2)],
                                                                                        failureReason: nil,
                                                                                        validation: nil)],
                                                                   failureReason: FailureReason(name: FailureName.unknown,
                                                                                                message: "Synergies not aligned"))])

        func submitGlobalPing(_: NoReasonCodes?) {
            XCTAssertEqual("Synergies not aligned", SyncMetrics.failureReason["other"].testGetValue())
            XCTAssertNotNil(globalSyncUuid)
            XCTAssertEqual(globalSyncUuid, SyncMetrics.syncUuid.testGetValue("sync"))
        }

        func submitHistoryPing(_: NoReasonCodes?) {
            globalSyncUuid = SyncMetrics.syncUuid.testGetValue("history-sync")!
            XCTAssertEqual("abc123", HistoryMetrics.uid.testGetValue())

            XCTAssertNotNil(HistoryMetrics.startedAt.testGetValue())
            XCTAssertNotNil(HistoryMetrics.finishedAt.testGetValue())
            XCTAssertEqual(now, Int64(HistoryMetrics.startedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)
            XCTAssertEqual(now + 5, Int64(HistoryMetrics.finishedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)

            XCTAssertEqual(5, HistoryMetrics.incoming["applied"].testGetValue())
            XCTAssertEqual(7, HistoryMetrics.incoming["failed_to_apply"].testGetValue())
            XCTAssertEqual(2, HistoryMetrics.incoming["reconciled"].testGetValue())
            XCTAssertEqual(14, HistoryMetrics.outgoing["uploaded"].testGetValue())
            XCTAssertEqual(7, HistoryMetrics.outgoing["failed_to_upload"].testGetValue())
            XCTAssertEqual(2, HistoryMetrics.outgoingBatches.testGetValue())
        }

        func submitLoginsPing(_: NoReasonCodes?) {
            globalSyncUuid = SyncMetrics.syncUuid.testGetValue("logins-sync")!
            XCTAssertEqual("abc123", LoginsMetrics.uid.testGetValue())

            XCTAssertNotNil(LoginsMetrics.startedAt.testGetValue())
            XCTAssertNotNil(LoginsMetrics.finishedAt.testGetValue())
            XCTAssertEqual(now, Int64(LoginsMetrics.startedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)
            XCTAssertEqual(now + 5, Int64(LoginsMetrics.finishedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)

            XCTAssertEqual(5, LoginsMetrics.incoming["applied"].testGetValue())
            XCTAssertEqual(7, LoginsMetrics.incoming["failed_to_apply"].testGetValue())
            XCTAssertEqual(2, LoginsMetrics.incoming["reconciled"].testGetValue())
            XCTAssertEqual(14, LoginsMetrics.outgoing["uploaded"].testGetValue())
            XCTAssertEqual(7, LoginsMetrics.outgoing["failed_to_upload"].testGetValue())
            XCTAssertEqual(2, LoginsMetrics.outgoingBatches.testGetValue())
        }

        try! processSyncTelemetry(syncTelemetry: syncTelemetry,
                                  submitGlobalPing: submitGlobalPing,
                                  submitHistoryPing: submitHistoryPing,
                                  submitLoginsPing: submitLoginsPing)
    }

    func testSendsHistoryAndGlobalPings() {
        var globalSyncUuid = UUID()
        let syncTelemetry = RustSyncTelemetryPing(version: 1,
                                                  uid: "abc123",
                                                  events: [],
                                                  syncs: [SyncInfo(at: now + 10,
                                                                   took: 5000,
                                                                   engines: [EngineInfo(name: "history",
                                                                                        at: now + 10,
                                                                                        took: 5000,
                                                                                        incoming: nil,
                                                                                        outgoing: [],
                                                                                        failureReason: nil,
                                                                                        validation: nil)],
                                                                   failureReason: nil)])

        func submitGlobalPing(_: NoReasonCodes?) {
            XCTAssertNil(SyncMetrics.failureReason["other"].testGetValue())
            XCTAssertNotNil(globalSyncUuid)
            XCTAssertEqual(globalSyncUuid, SyncMetrics.syncUuid.testGetValue("sync"))
        }

        func submitHistoryPing(_: NoReasonCodes?) {
            globalSyncUuid = SyncMetrics.syncUuid.testGetValue("history-sync")!
            XCTAssertEqual("abc123", HistoryMetrics.uid.testGetValue())

            XCTAssertNotNil(HistoryMetrics.startedAt.testGetValue())
            XCTAssertNotNil(HistoryMetrics.finishedAt.testGetValue())
            XCTAssertEqual(now + 10, Int64(HistoryMetrics.startedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)
            XCTAssertEqual(now + 15, Int64(HistoryMetrics.finishedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)

            XCTAssertNil(HistoryMetrics.incoming["applied"].testGetValue())
            XCTAssertNil(HistoryMetrics.incoming["failed_to_apply"].testGetValue())
            XCTAssertNil(HistoryMetrics.incoming["reconciled"].testGetValue())
            XCTAssertNil(HistoryMetrics.outgoing["uploaded"].testGetValue())
            XCTAssertNil(HistoryMetrics.outgoing["failed_to_upload"].testGetValue())
            XCTAssertNil(HistoryMetrics.outgoingBatches.testGetValue())
        }

        try! processSyncTelemetry(syncTelemetry: syncTelemetry,
                                  submitGlobalPing: submitGlobalPing,
                                  submitHistoryPing: submitHistoryPing)
    }

    func testSendsBookmarksAndGlobalPings() {
        var globalSyncUuid = UUID()
        let syncTelemetry = RustSyncTelemetryPing(version: 1,
                                                  uid: "abc123",
                                                  events: [],
                                                  syncs: [SyncInfo(at: now + 20,
                                                                   took: 8000,
                                                                   engines: [EngineInfo(name: "bookmarks",
                                                                                        at: now + 25,
                                                                                        took: 6000,
                                                                                        incoming: nil,
                                                                                        outgoing: [OutgoingInfo(sent: 10, failed: 5)],
                                                                                        failureReason: nil,
                                                                                        validation: ValidationInfo(version: 2,
                                                                                                                   problems: [ProblemInfo(name: "missingParents",
                                                                                                                                          count: 5),
                                                                                                                              ProblemInfo(name: "missingChildren",
                                                                                                                                          count: 7)],
                                                                                                                   failureReason: nil))],
                                                                   failureReason: nil)])

        func submitGlobalPing(_: NoReasonCodes?) {
            XCTAssertNil(SyncMetrics.failureReason["other"].testGetValue())
            XCTAssertNotNil(globalSyncUuid)
            XCTAssertEqual(globalSyncUuid, SyncMetrics.syncUuid.testGetValue("sync"))
        }

        func submitBookmarksPing(_: NoReasonCodes?) {
            globalSyncUuid = SyncMetrics.syncUuid.testGetValue("bookmarks-sync")!
            XCTAssertEqual("abc123", BookmarksMetrics.uid.testGetValue())

            XCTAssertNotNil(BookmarksMetrics.startedAt.testGetValue())
            XCTAssertNotNil(BookmarksMetrics.finishedAt.testGetValue())
            XCTAssertEqual(now + 25, Int64(BookmarksMetrics.startedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)
            XCTAssertEqual(now + 31, Int64(BookmarksMetrics.finishedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)

            XCTAssertNil(BookmarksMetrics.incoming["applied"].testGetValue())
            XCTAssertNil(BookmarksMetrics.incoming["failed_to_apply"].testGetValue())
            XCTAssertNil(BookmarksMetrics.incoming["reconciled"].testGetValue())
            XCTAssertEqual(10, BookmarksMetrics.outgoing["uploaded"].testGetValue())
            XCTAssertEqual(5, BookmarksMetrics.outgoing["failed_to_upload"].testGetValue())
            XCTAssertEqual(1, BookmarksMetrics.outgoingBatches.testGetValue())
        }

        try! processSyncTelemetry(syncTelemetry: syncTelemetry,
                                  submitGlobalPing: submitGlobalPing,
                                  submitBookmarksPing: submitBookmarksPing)
    }

    func testSendsTabsCreditCardsAndGlobalPings() {
        var globalSyncUuid = UUID()
        let syncTelemetry = RustSyncTelemetryPing(version: 1,
                                                  uid: "abc123",
                                                  events: [],
                                                  syncs: [SyncInfo(at: now + 30,
                                                                   took: 10000,
                                                                   engines: [EngineInfo(name: "tabs",
                                                                                        at: now + 10,
                                                                                        took: 6000,
                                                                                        incoming: nil,
                                                                                        outgoing: [OutgoingInfo(sent: 8, failed: 2)],
                                                                                        failureReason: nil,
                                                                                        validation: nil),
                                                                             EngineInfo(name: "creditcards",
                                                                                        at: now + 15,
                                                                                        took: 4000,
                                                                                        incoming: IncomingInfo(applied: 3,
                                                                                                               failed: 1,
                                                                                                               newFailed: 1,
                                                                                                               reconciled: 0),
                                                                                        outgoing: [],
                                                                                        failureReason: nil,
                                                                                        validation: nil)],
                                                                   failureReason: nil)])

        func submitGlobalPing(_: NoReasonCodes?) {
            XCTAssertNil(SyncMetrics.failureReason["other"].testGetValue())
            XCTAssertNotNil(globalSyncUuid)
            XCTAssertEqual(globalSyncUuid, SyncMetrics.syncUuid.testGetValue("sync"))
        }

        func submitCreditCardsPing(_: NoReasonCodes?) {
            globalSyncUuid = SyncMetrics.syncUuid.testGetValue("creditcards-sync")!
            XCTAssertEqual("abc123", CreditcardsMetrics.uid.testGetValue())

            XCTAssertNotNil(CreditcardsMetrics.startedAt.testGetValue())
            XCTAssertNotNil(CreditcardsMetrics.finishedAt.testGetValue())
            XCTAssertEqual(now + 15, Int64(CreditcardsMetrics.startedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)
            XCTAssertEqual(now + 19, Int64(CreditcardsMetrics.finishedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)

            XCTAssertEqual(3, CreditcardsMetrics.incoming["applied"].testGetValue())
            XCTAssertEqual(2, CreditcardsMetrics.incoming["failed_to_apply"].testGetValue())
            XCTAssertNil(CreditcardsMetrics.incoming["reconciled"].testGetValue())
            XCTAssertNil(HistoryMetrics.outgoing["uploaded"].testGetValue())
            XCTAssertNil(HistoryMetrics.outgoing["failed_to_upload"].testGetValue())
            XCTAssertNil(CreditcardsMetrics.outgoingBatches.testGetValue())
        }

        func submitTabsPing(_: NoReasonCodes?) {
            globalSyncUuid = SyncMetrics.syncUuid.testGetValue("tabs-sync")!
            XCTAssertEqual("abc123", TabsMetrics.uid.testGetValue())

            XCTAssertNotNil(TabsMetrics.startedAt.testGetValue())
            XCTAssertNotNil(TabsMetrics.finishedAt.testGetValue())
            XCTAssertEqual(now + 10, Int64(TabsMetrics.startedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)
            XCTAssertEqual(now + 16, Int64(TabsMetrics.finishedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)

            XCTAssertNil(TabsMetrics.incoming["applied"].testGetValue())
            XCTAssertNil(TabsMetrics.incoming["failed_to_apply"].testGetValue())
            XCTAssertNil(TabsMetrics.incoming["reconciled"].testGetValue())
            XCTAssertEqual(8, TabsMetrics.outgoing["uploaded"].testGetValue())
            XCTAssertEqual(2, TabsMetrics.outgoing["failed_to_upload"].testGetValue())
        }

        try! processSyncTelemetry(syncTelemetry: syncTelemetry,
                                  submitGlobalPing: submitGlobalPing,
                                  submitCreditCardsPing: submitCreditCardsPing,
                                  submitTabsPing: submitTabsPing)
    }

    func testSendsAddressesAndGlobalPings() {
        var globalSyncUuid = UUID()
        let syncTelemetry = RustSyncTelemetryPing(version: 1,
                                                  uid: "abc123",
                                                  events: [],
                                                  syncs: [SyncInfo(at: now + 20,
                                                                   took: 8000,
                                                                   engines: [EngineInfo(name: "addresses",
                                                                                        at: now + 25,
                                                                                        took: 6000,
                                                                                        incoming: nil,
                                                                                        outgoing: [OutgoingInfo(sent: 10, failed: 5)],
                                                                                        failureReason: nil,
                                                                                        validation: nil)],
                                                                   failureReason: nil)])

        func submitGlobalPing(_: NoReasonCodes?) {
            XCTAssertNil(SyncMetrics.failureReason["other"].testGetValue())
            XCTAssertNotNil(globalSyncUuid)
            XCTAssertEqual(globalSyncUuid, SyncMetrics.syncUuid.testGetValue("sync"))
        }

        func submitAddressesPing(_: NoReasonCodes?) {
            globalSyncUuid = SyncMetrics.syncUuid.testGetValue("addresses-sync")!
            XCTAssertEqual("abc123", AddressesMetrics.uid.testGetValue())

            XCTAssertNotNil(AddressesMetrics.startedAt.testGetValue())
            XCTAssertNotNil(AddressesMetrics.finishedAt.testGetValue())
            XCTAssertEqual(now + 25, Int64(AddressesMetrics.startedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)
            XCTAssertEqual(now + 31, Int64(AddressesMetrics.finishedAt.testGetValue()!.timeIntervalSince1970) / BaseGleanSyncPing.MILLIS_PER_SEC)

            XCTAssertNil(AddressesMetrics.incoming["applied"].testGetValue())
            XCTAssertNil(AddressesMetrics.incoming["failed_to_apply"].testGetValue())
            XCTAssertNil(AddressesMetrics.incoming["reconciled"].testGetValue())
            XCTAssertEqual(10, AddressesMetrics.outgoing["uploaded"].testGetValue())
            XCTAssertEqual(5, AddressesMetrics.outgoing["failed_to_upload"].testGetValue())
            XCTAssertEqual(1, AddressesMetrics.outgoingBatches.testGetValue())
        }

        try! processSyncTelemetry(syncTelemetry: syncTelemetry,
                                  submitGlobalPing: submitGlobalPing,
                                  submitAddressesPing: submitAddressesPing)
    }

    func testReceivesOpenSyncSettingsMenuTelemetry() {
        SyncManagerComponent.reportOpenSyncSettingsMenuTelemetry()
        let events = GleanMetrics.SyncSettings.openMenu.testGetValue()!
        XCTAssertEqual(1, events.count)
        XCTAssertEqual("sync_settings", events[0].category)
        XCTAssertEqual("open_menu", events[0].name)
    }

    func testReceivesSaveSyncSettingsTelemetry() {
        let enabledEngines = ["bookmarks", "tabs"]
        let disabledEngines = ["logins"]
        SyncManagerComponent.reportSaveSyncSettingsTelemetry(enabledEngines: enabledEngines, disabledEngines: disabledEngines)
        let events = GleanMetrics.SyncSettings.save.testGetValue()!
        XCTAssertEqual(1, events.count)
        XCTAssertEqual("sync_settings", events[0].category)
        XCTAssertEqual("save", events[0].name)
        XCTAssertEqual("bookmarks,tabs", events[0].extra!["enabled_engines"])
        XCTAssertEqual("logins", events[0].extra!["disabled_engines"])
    }
}
