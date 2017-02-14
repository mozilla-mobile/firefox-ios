/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON
@testable import Sync

import XCTest

fileprivate class MockFailure<T: CleartextPayloadJSON>: MaybeErrorType {
    let record: Record<T>

    var description: String {
        return "Failed to store or upload record: \(record)"
    }

    init(record: Record<T>) {
        self.record = record
    }
}

class SyncTelemetryTests: XCTestCase {
}

// MARK: IndependentRecordSynchronizer
extension SyncTelemetryTests {
    private func getMockedIndependentRecordSynchronizer() -> IndependentRecordSynchronizer {
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)
        let delegate = MockSyncDelegate()

        return IndependentRecordSynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs, collection: "mockHistory")
    }

    func testApplyIncomingRecordsReportsDownloadStats() {
        let synchronizer = getMockedIndependentRecordSynchronizer()
        synchronizer.statsSession.start()

        // Fake remote records for incoming changes
        let payloadA = CleartextPayloadJSON("{\"id\":\"A\",\"title\": \"A\"}")
        let A = Record<CleartextPayloadJSON>(id: "A", payload: payloadA)

        let payloadB = CleartextPayloadJSON("{\"id\":\"B\",\"title\": \"B\"}")
        let B = Record<CleartextPayloadJSON>(id: "B", payload: payloadB)

        let remoteRecords = [A, B]

        let _ = synchronizer.applyIncomingRecords(remoteRecords) { record in
            return record.id == "B" ? deferMaybe(MockFailure(record: record)) : succeed()
        }.value

        let session = synchronizer.statsSession.end()

        let downloadStats = session.downloadStats
        XCTAssertEqual(downloadStats.applied, 2)
        XCTAssertEqual(downloadStats.succeeded, 1)
        XCTAssertEqual(downloadStats.failed, 1)
    }

    func testApplyIncomingRecordsToStorageReportsDownloadStats() {
        let synchronizer = getMockedIndependentRecordSynchronizer()
        synchronizer.statsSession.start()

        // Fake remote records for incoming changes
        let payloadA = CleartextPayloadJSON("{\"id\":\"A\",\"title\": \"A\"}")
        let A = Record<CleartextPayloadJSON>(id: "A", payload: payloadA)

        let payloadB = CleartextPayloadJSON("{\"id\":\"B\",\"title\": \"B\"}")
        let B = Record<CleartextPayloadJSON>(id: "B", payload: payloadB)

        let records = [A, B]

        let _ = synchronizer.applyIncomingToStorage(records, fetched: Date.now()) { record in
            return record.id == "B" ? deferMaybe(MockFailure(record: record)) : succeed()
        }.value

        let session = synchronizer.statsSession.end()

        let downloadStats = session.downloadStats
        XCTAssertEqual(downloadStats.applied, 2)
        XCTAssertEqual(downloadStats.succeeded, 1)
        XCTAssertEqual(downloadStats.failed, 1)
    }

    func testUploadRecordsReportsUploadStats() {
        let synchronizer = getMockedIndependentRecordSynchronizer()
        synchronizer.statsSession.start()

        let now = Date.now()

        // Fake local records for outgoing changes
        let payloadC = CleartextPayloadJSON("{\"id\":\"C\",\"title\": \"C\"}")
        let C = Record<CleartextPayloadJSON>(id: "C", payload: payloadC)

        let payloadD = CleartextPayloadJSON("{\"id\":\"D\", \"title\": \"D\"}")
        let D = Record<CleartextPayloadJSON>(id: "D", payload: payloadD)
        let records = [C, D]

        // Mock out a response for the uploader
        let uploader: BatchUploadFunction = { _, _, _ in
            let result = POSTResult(success: [C.id], failed: [D.id: "Invalid GUID"])
            let response = StorageResponse<POSTResult>(value: result, metadata: ResponseMetadata(status: 200, headers: [:]))
            return deferMaybe(response)
        }

        let miniConfig = InfoConfiguration(maxRequestBytes: 1_048_576, maxPostRecords: 2, maxPostBytes: 1_048_576, maxTotalRecords: 10, maxTotalBytes: 104_857_600)
        let collectionClient = MockSyncCollectionClient(uploader: uploader, infoConfig: miniConfig, collection: "mockdata", encrypter: getEncrypter())
        let _ = synchronizer.uploadRecords(records, lastTimestamp: now, storageClient: collectionClient) { _, _ in
            return deferMaybe(now)
        }.value

        let uploadStats = synchronizer.statsSession.uploadStats
        XCTAssertEqual(uploadStats.sent, 1)
        XCTAssertEqual(uploadStats.sentFailed, 1)
    }
}
