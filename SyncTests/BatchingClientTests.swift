/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred
@testable import Sync

import XCTest

class Sync15BatchClientTests: XCTestCase {

    // Setup a configuration thats pretty small record-wise for testing
    private let miniConfig = InfoConfiguration(maxRequestBytes: 1048576, maxPostRecords: 2, maxPostBytes: 1048576, maxTotalRecords: 10, maxTotalBytes: 104857600)
    private let emptyResponse = StorageResponse(value: POSTResult(modified: NSDate.now(), success: [], failed: [:]), metadata: ResponseMetadata(status: 200, headers: [:]))

    private func serializeRecord(record: Record<CleartextPayloadJSON>) -> String? {
        return jsonFromRecord(record)?.toString()
    }

    private func mockRecord() -> Record<CleartextPayloadJSON> {
        let jA = "{\"id\":\"mock\",\"histUri\":\"http://foo.com/\",\"title\": \"ñ\",\"visits\":[{\"date\":1222222222222222,\"type\":1}]}"
        return Record<CleartextPayloadJSON>(id: "mock",payload: CleartextPayloadJSON(JSON.parse(jA)), modified: 10000, sortindex: 123, ttl: 1000000)
    }

    private func sizeOfMockRecord() -> ByteCount {
        return serializeRecord(mockRecord())!.utf8.count
    }

    private func generateMockRecords(count: Int) -> [Record<CleartextPayloadJSON>] {
        return (0..<count).reduce([]) { previous, _ in
            return previous + [mockRecord()]
        }
    }

    private func jsonFromRecord<T>(record: Record<T>) -> JSON? {
        return JSON([
            "id": record.id,
            "foo": "bar"
        ])
    }

    private func sizeReducer(total: ByteCount, record: Record<CleartextPayloadJSON>) -> ByteCount {
        return total + (self.serializeRecord(record) ?? "").utf8.count
    }

    // Always return a gigantic encoded payload.
    func massivify(record: Record<CleartextPayloadJSON>) -> JSON? {
        return JSON([
            "id": record.id,
            "foo": String(count: Sync15StorageClient.maxRecordSizeBytes + 1, repeatedValue: "X" as Character)
        ])
    }
}

// MARK: Mock uploading tests
extension Sync15BatchClientTests {

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
            uploadOpCount += 1

            if let params = queryParams where params.contains({ $0.name == "batch" && $0.value == "true" }) {
                startedBatch = true
                let batchStart = POSTResult(modified: 100000, success: [], failed: [:], batchToken: "token")
                return deferMaybe(StorageResponse(value: batchStart, metadata: ResponseMetadata(status: 200, headers: [:])))
            }

            if let params = queryParams where params.contains({ $0.name == "commit" && $0.value == "true" }) {
                committedBatch = true
            }

            return deferMaybe(self.emptyResponse)
        }

        let onCollectionUpload: (POSTResult -> Void) = { _ in collectionUploadCount += 1 }

        let batch = Sync15BatchClient(config: miniConfig, ifUnmodifiedSince: nil, serializeRecord: serializeRecord, uploader: uploader)
        let records = generateMockRecords(miniConfig.maxTotalRecords)
        batch.addRecords(records)
        batch.commit(onCollectionUpload).succeeded()

        // Should only have called the upload/collection callbacks once
        XCTAssertEqual(collectionUploadCount, 1)
        XCTAssertEqual(uploadOpCount, 5)
        XCTAssertTrue(startedBatch)
        XCTAssertTrue(committedBatch)
    }

    func testBatchNotSupportedUpload() {
        var collectionUploadCount = 0
        var uploadOpCount = 0

        let uploader: BatchUploadFunction = { lines, timestamp, queryParams in
            uploadOpCount += 1

            if let params = queryParams where params.contains({ $0.name == "batch" && $0.value == "true" }) {
                let batchStart = POSTResult(modified: 100000, success: [], failed: [:])
                return deferMaybe(StorageResponse(value: batchStart, metadata: ResponseMetadata(status: 200, headers: [:])))
            }

            return deferMaybe(self.emptyResponse)
        }

        let onCollectionUpload: (POSTResult -> Void) = { _ in collectionUploadCount += 1 }

        let batch = Sync15BatchClient(config: miniConfig, ifUnmodifiedSince: nil, serializeRecord: serializeRecord, uploader: uploader)
        let records = generateMockRecords(miniConfig.maxTotalRecords)
        batch.addRecords(records)
        batch.commit(onCollectionUpload).succeeded()

        // Should only have called the upload/collection callbacks for each upload we made
        XCTAssertEqual(collectionUploadCount, 5)
        XCTAssertEqual(uploadOpCount, 5)
    }

    func testMultipleBatchUpload() {

    }
}

// MARK: Batching logic tests
extension Sync15BatchClientTests {

    func testBatchesFromRecordsUsingRecordLimits() {
        let smallRecordLimitConfig =
            InfoConfiguration(maxRequestBytes: 1048576, maxPostRecords: 2, maxPostBytes: 1048576, maxTotalRecords: 10, maxTotalBytes: 104857600)

        let uploader: BatchUploadFunction = { _ in return deferMaybe(self.emptyResponse) }
        let batch = Sync15BatchClient(config: smallRecordLimitConfig, ifUnmodifiedSince: nil, serializeRecord: serializeRecord, uploader: uploader)

        var batches = batch.batchesFromRecords([]).successValue!
        XCTAssertEqual(batches.count, 0)

        var records = generateMockRecords(1)
        batches = batch.batchesFromRecords(records).successValue!
        XCTAssertEqual(batches.count, 1)

        records = generateMockRecords(2)
        batches = batch.batchesFromRecords(records).successValue!
        XCTAssertEqual(batches.count, 1)

        records = generateMockRecords(3)
        batches = batch.batchesFromRecords(records).successValue!
        XCTAssertEqual(batches.count, 2)

        records = generateMockRecords(20)
        batches = batch.batchesFromRecords(records).successValue!
        XCTAssertEqual(batches.count, 10)
    }

    func testBatchesFromRecordsUsingByteLimits() {
        // Limit the size of a batch to two records + 2 newlines
        let smallByteLimitConfig =
            InfoConfiguration(maxRequestBytes: 1048576, maxPostRecords: 100, maxPostBytes: (sizeOfMockRecord() * 2 + 2), maxTotalRecords: 100, maxTotalBytes: 104857600)

        let uploader: BatchUploadFunction = { _ in return deferMaybe(self.emptyResponse) }
        let batch = Sync15BatchClient(config: smallByteLimitConfig, ifUnmodifiedSince: nil, serializeRecord: serializeRecord, uploader: uploader)

        var batches = batch.batchesFromRecords([]).successValue!
        XCTAssertEqual(batches.count, 0)

        var records = generateMockRecords(1)
        batches = batch.batchesFromRecords(records).successValue!
        XCTAssertEqual(batches.count, 1)

        records = generateMockRecords(2)
        batches = batch.batchesFromRecords(records).successValue!
        XCTAssertEqual(batches.count, 1)

        records = generateMockRecords(3)
        batches = batch.batchesFromRecords(records).successValue!
        XCTAssertEqual(batches.count, 2)

        records = generateMockRecords(20)
        batches = batch.batchesFromRecords(records).successValue!
        XCTAssertEqual(batches.count, 10)
    }

    func testBatchesAccountsForNewlines() {
        let postBytesLimit = sizeOfMockRecord() * 2
        let smallByteLimitConfig =
            InfoConfiguration(maxRequestBytes: 1048576, maxPostRecords: 100, maxPostBytes: postBytesLimit, maxTotalRecords: 100, maxTotalBytes: 104857600)

        let uploader: BatchUploadFunction = { _ in return deferMaybe(self.emptyResponse) }
        let batch = Sync15BatchClient(config: smallByteLimitConfig, ifUnmodifiedSince: nil, serializeRecord: serializeRecord, uploader: uploader)

        let records = generateMockRecords(2)
        let sizeOfRecords: ByteCount = records.reduce(0, combine: self.sizeReducer)

        XCTAssertEqual(sizeOfRecords, postBytesLimit)

        // Even though the records should fit, by adding the byte for the newline we should move to the next batch
        let batches = batch.batchesFromRecords(records).successValue!
        XCTAssertEqual(batches.count, 2)
    }

    func testBatchingReturnsRecordTooLargeFailure() {
        let uploader: BatchUploadFunction = { _ in return deferMaybe(self.emptyResponse) }
        let batch = Sync15BatchClient(config: miniConfig, ifUnmodifiedSince: nil, serializeRecord: { self.massivify($0)?.toString() }, uploader: uploader)

        let record = generateMockRecords(1).first!
        let failure = batch.batchesFromRecords([record]).failureValue as! RecordTooLargeError
        XCTAssertEqual(failure.guid, record.id)
    }
}