/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred
@testable import Sync

import XCTest

// Always return a gigantic encoded payload.
func massivify(record: Record<CleartextPayloadJSON>) -> JSON? {
    return JSON([
        "id": record.id,
        "foo": String(count: Sync15StorageClient.maxRecordSizeBytes + 1, repeatedValue: "X" as Character)
    ])
}

private class MockBackoffStorage: BackoffStorage {
    var serverBackoffUntilLocalTimestamp: Timestamp? { get { return 0 } set(value) {} }

    func clearServerBackoff() {
    }

    func isInBackoff(now: Timestamp) -> Timestamp? {
        return nil
    }

    init() {
    }
}

class StorageClientTests: XCTestCase {
    func testPartialJSON() {
        let body = "0"
        let o: AnyObject? = try! NSJSONSerialization.JSONObjectWithData(body.dataUsingEncoding(NSUTF8StringEncoding)!, options: NSJSONReadingOptions.AllowFragments)
        XCTAssertTrue(JSON(o!).isInt)
    }

    func testPOSTResult() {
        // Pulled straight from <http://docs.services.mozilla.com/storage/apis-1.5.html>.
        let r = "{" +
            "\"modified\": 1233702554.25," +
            "\"success\": [\"GXS58IDC_12\", \"GXS58IDC_13\", \"GXS58IDC_15\"," +
            "\"GXS58IDC_16\", \"GXS58IDC_18\", \"GXS58IDC_19\"]," +
            "\"failed\": {\"GXS58IDC_11\": \"invalid ttl\"," +
            "\"GXS58IDC_14\": \"invalid sortindex\"}" +
        "}"

        let p = POSTResult.fromJSON(JSON.parse(r))
        XCTAssertTrue(p != nil)
        XCTAssertEqual(p!.modified, 1233702554250)
        XCTAssertEqual(p!.success[0], "GXS58IDC_12")
        XCTAssertEqual(p!.failed["GXS58IDC_14"]!, "invalid sortindex")

        XCTAssertTrue(nil == POSTResult.fromJSON(JSON.parse("{\"foo\": 5}")))
    }

    func testNumeric() {
        let m = ResponseMetadata(status: 200, headers: [
            "X-Last-Modified": "2174380461.12",
        ])
        XCTAssertTrue(m.lastModifiedMilliseconds == 2174380461120)

        XCTAssertEqual("2174380461.12", millisecondsToDecimalSeconds(2174380461120))
    }

    // Trivial test for struct semantics that we might want to pay attention to if they change,
    // and for response header parsing.
    func testResponseHeaders() {
        let v: JSON = JSON.parse("{\"a:\": 2}")
        let m = ResponseMetadata(status: 200, headers: [
            "X-Weave-Timestamp": "1274380461.12",
            "X-Last-Modified":   "2174380461.12",
            "X-Weave-Next-Offset": "abdef",
            ])

        XCTAssertTrue(m.lastModifiedMilliseconds == 2174380461120)
        XCTAssertTrue(m.timestampMilliseconds    == 1274380461120)
        XCTAssertTrue(m.nextOffset == "abdef")

        // Just to avoid consistent overflow allowing ==.
        XCTAssertTrue(m.lastModifiedMilliseconds?.description == "2174380461120")
        XCTAssertTrue(m.timestampMilliseconds.description == "1274380461120")

        let x: StorageResponse<JSON> = StorageResponse<JSON>(value: v, metadata: m)

        func doTesting(y: StorageResponse<JSON>) {
            // Make sure that reference fields in a struct are copies of the same reference,
            // not references to a copy.
            XCTAssertTrue(x.value === y.value)

            XCTAssertTrue(y.metadata.lastModifiedMilliseconds == x.metadata.lastModifiedMilliseconds, "lastModified is the same.")

            XCTAssertTrue(x.metadata.quotaRemaining == nil, "No quota.")
            XCTAssertTrue(y.metadata.lastModifiedMilliseconds == 2174380461120, "lastModified is correct.")
            XCTAssertTrue(x.metadata.timestampMilliseconds == 1274380461120, "timestamp is correct.")
            XCTAssertTrue(x.metadata.nextOffset == "abdef", "nextOffset is correct.")
            XCTAssertTrue(x.metadata.records == nil, "No X-Weave-Records.")
        }

        doTesting(x)
    }

    func testOverSizeRecords() {
        let delegate = MockSyncDelegate()

        // We can use these useless values because we're directly injecting decrypted
        // payloads; no need for real keys etc.
        let prefs = MockProfilePrefs()
        let scratchpad = Scratchpad(b: KeyBundle.random(), persistingTo: prefs)

        let synchronizer = IndependentRecordSynchronizer(scratchpad: scratchpad, delegate: delegate, basePrefs: prefs, collection: "foo")
        let jA = "{\"id\":\"aaaaaa\",\"histUri\":\"http://foo.com/\",\"title\": \"ñ\",\"visits\":[{\"date\":1222222222222222,\"type\":1}]}"
        let rA = Record<CleartextPayloadJSON>(id: "aaaaaa", payload: CleartextPayloadJSON(JSON.parse(jA)), modified: 10000, sortindex: 123, ttl: 1000000)

        let storageClient = Sync15StorageClient(serverURI: "http://example.com/".asURL!, authorizer: identity, workQueue: dispatch_get_main_queue(), resultQueue: dispatch_get_main_queue(), backoff: MockBackoffStorage())
        let collectionClient = storageClient.clientForCollection("foo", encrypter: RecordEncrypter<CleartextPayloadJSON>(serializer: massivify, factory: { CleartextPayloadJSON($0) }))
        let result = synchronizer.uploadRecordsInChunks([rA], lastTimestamp: NSDate.now(), storageClient: collectionClient, onUpload: { _ in deferMaybe(NSDate.now()) })

        XCTAssertTrue(result.value.failureValue is RecordTooLargeError)
    }
}

private func jsonFromRecord<T>(record: Record<T>) -> JSON? {
    return JSON([
        "id": record.id,
        "foo": "bar"
    ])
}

class Sync15BatchClientTests: XCTestCase {
    // Setup a configuration thats pretty small record-wise for testing
    private let miniConfig = InfoConfiguration(maxRequestBytes: 1048576, maxPostRecords: 2, maxPostBytes: 1048576, maxBatchRecord: 10, maxBatchBytes: 104857600)
    private let emptyResponse = StorageResponse(value: POSTResult(modified: NSDate.now(), success: [], failed: [:]), metadata: ResponseMetadata(status: 200, headers: [:]))

    private func serializeRecord(record: Record<CleartextPayloadJSON>) -> String? {
        return jsonFromRecord(record)?.asString
    }

    private func generateMockRecords(count: Int) -> [Record<CleartextPayloadJSON>] {
        return (0..<count).reduce([]) { previous, id in
            let jA = "{\"id\":\"record\(id)\",\"histUri\":\"http://foo.com/\",\"title\": \"ñ\",\"visits\":[{\"date\":1222222222222222,\"type\":1}]}"
            return previous + [Record<CleartextPayloadJSON>(id: "record\(id)", payload: CleartextPayloadJSON(JSON.parse(jA)), modified: 10000, sortindex: 123, ttl: 1000000)]
        }
    }

    func testNoUploadWhenEmpty() {
        var onCollectionUploadCalled = false
        var onUploadCalled = false

        let uploader: BatchUploadFunction = { _ in
            onUploadCalled = true
            return deferMaybe(self.emptyResponse)
        }

        let onCollectionUpload: (POSTResult -> Void) = { _ in onCollectionUploadCalled = true }

        let batch = Sync15BatchClient(config: miniConfig, ifUnmodifiedSince: nil, serializeRecord: serializeRecord, uploader: uploader)
        batch.addRecords([])
        batch.commit(onCollectionUpload).succeeded()

        // Shouldn't invoke the callback if we didn't actually upload anything
        XCTAssertFalse(onCollectionUploadCalled)
        XCTAssertFalse(onUploadCalled)
    }

    func testSinglePOSTUpload() {
        var collectionUploadCount = 0
        var uploadOpCount = 0

        let uploader: BatchUploadFunction = { lines, timestamp, queryParams in
            // Single POST should not have query parameters attached
            XCTAssertNil(queryParams)
            uploadOpCount += 1
            return deferMaybe(self.emptyResponse)
        }

        let onCollectionUpload: (POSTResult -> Void) = { _ in collectionUploadCount += 1 }

        let batch = Sync15BatchClient(config: miniConfig, ifUnmodifiedSince: nil, serializeRecord: serializeRecord, uploader: uploader)
        let records = generateMockRecords(miniConfig.maxPostRecords)
        batch.addRecords(records)
        batch.commit(onCollectionUpload).succeeded()

        // Should only have called the upload/collection callbacks once
        XCTAssertEqual(collectionUploadCount, 1)
        XCTAssertEqual(uploadOpCount, 1)
    }

    func testBatchUpload() {
        var collectionUploadCount = 0
        var uploadOpCount = 0

        var startedBatch: Bool = false
        var committedBatch: Bool = false

        let uploader: BatchUploadFunction = { lines, timestamp, queryParams in
            if let params = queryParams where params.contains({ $0.name == "batch" && $0.value == "batch" }) {
                startedBatch = true
                let batchStart = POSTResult(modified: 100000, success: [], failed: [:], batchToken: "token")
                return deferMaybe(StorageResponse(value: batchStart, metadata: ResponseMetadata(status: 200, headers: [:])))
            }

            if let params = queryParams where params.contains({ $0.name == "commit" && $0.value == "true" }) {
                committedBatch = true
            }

            uploadOpCount += 1
            return deferMaybe(self.emptyResponse)
        }

        let onCollectionUpload: (POSTResult -> Void) = { _ in collectionUploadCount += 1 }

        let batch = Sync15BatchClient(config: miniConfig, ifUnmodifiedSince: nil, serializeRecord: serializeRecord, uploader: uploader)
        let records = generateMockRecords(miniConfig.maxBatchRecord)
        batch.addRecords(records)
        batch.commit(onCollectionUpload).succeeded()

        // Should only have called the upload/collection callbacks once
        XCTAssertEqual(collectionUploadCount, 1)
        XCTAssertEqual(uploadOpCount, 2)
        XCTAssertTrue(startedBatch)
        XCTAssertTrue(committedBatch)
    }

    func testBatchNotSupportedUpload() {

    }

    func testMultipleBatchUpload() {

    }
}