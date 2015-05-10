/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared
import Storage
import XCTest

class MockSyncDelegate: SyncDelegate {
    func displaySentTabForURL(URL: NSURL, title: String) {
    }
}

class HistorySynchronizerTests: XCTestCase {
    private func applyRecords(records: [Record<HistoryPayload>], toStorage storage: SyncableHistory) -> HistorySynchronizer {
        let delegate = MockSyncDelegate()

        // We can use these useless values because we're directly injecting decrypted
        // payloads; no need for real keys etc.
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)

        let synchronizer = HistorySynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs)
        let ts = NSDate.now()

        let expectation = expectationWithDescription("Waiting for application.")
        var succeeded = false
        synchronizer.applyIncomingToStorage(storage, records: records, fetched: ts)
                    .upon({ result in
            succeeded = result.isSuccess
            expectation.fulfill()
        })

        waitForExpectationsWithTimeout(10, handler: nil)
        XCTAssertTrue(succeeded, "Application succeeded.")
        return synchronizer
    }

    func testApplyRecords() {
        let earliest = NSDate.now()

        func timestampIsSane(synchronizer: HistorySynchronizer) {
            XCTAssertTrue(earliest <= synchronizer.lastFetched, "Timestamp is sane (lower).")
            XCTAssertTrue(NSDate.now() >= synchronizer.lastFetched, "Timestamp is sane (upper).")
        }

        let empty = MockSyncableHistory()
        let noRecords = [Record<HistoryPayload>]()

        // Apply no records.
        timestampIsSane(self.applyRecords(noRecords, toStorage: empty))

        // Hey look! Nothing changed.
        XCTAssertTrue(empty.mirrorPlaces.isEmpty)
        XCTAssertTrue(empty.localPlaces.isEmpty)
        XCTAssertTrue(empty.remoteVisits.isEmpty)
        XCTAssertTrue(empty.localVisits.isEmpty)

        // Apply one remote record.
        let jA = "{\"id\":\"aaaaaa\",\"histUri\":\"http://foo.com/\",\"title\": \"ñ\",\"visits\":[{\"date\":1222222222222222,\"type\":1}]}"
        let pA = HistoryPayload.fromJSON(JSON.parse(jA))!
        let rA = Record<HistoryPayload>(id: "aaaaaa", payload: pA, modified: earliest + 10000, sortindex: 123, ttl: 1000000)

        timestampIsSane(self.applyRecords([rA], toStorage: empty))

        // The record was stored. This is checking our mock implementation, but real storage should work, too!

        XCTAssertEqual(1, empty.mirrorPlaces.count)
        XCTAssertTrue(empty.localPlaces.isEmpty)
        XCTAssertEqual(1, empty.remoteVisits.count)
        XCTAssertEqual(1, empty.remoteVisits["aaaaaa"]!.count)
        XCTAssertTrue(empty.localVisits.isEmpty)

    }
}