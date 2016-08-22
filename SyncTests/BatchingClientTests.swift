/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred
@testable import Sync

import XCTest

// Always return a gigantic encoded payload.
private func massivify<T>(record: Record<T>) -> JSON? {
    return JSON([
        "id": record.id,
        "foo": String(count: Sync15StorageClient.maxRecordSizeBytes + 1, repeatedValue: "X" as Character)
    ])
}

private func basicSerializer<T>(record: Record<T>) -> String {
    return JSON([
        "id": record.id,
        "payload": record.payload
    ]).toString()
}

// Create a basic record with an ID and a title that is the `Site$ID`.
private func createRecordWithID(id: String) -> Record<CleartextPayloadJSON> {
    let jsonString = "{\"id\":\"\(id)\",\"title\": \"\(id)\"}"
    return Record<CleartextPayloadJSON>(id: id,
                                        payload: CleartextPayloadJSON(JSON.parse(jsonString)),
                                        modified: 10_000,
                                        sortindex: 123,
                                        ttl: 1_000_000)
}

private func assertLinesMatchRecords<T>(lines: [String], records: [Record<T>], serializer: (Record<T>) -> String) {
    guard lines.count == records.count else {
        XCTFail("Number of lines mismatch number of records")
        return
    }

    lines.enumerate().forEach { index, line in
        let record = records[index]
        XCTAssertEqual(line, serializer(record))
    }
}


private func deferEmptyResponse(batchToken batchToken: BatchToken? = nil, lastModified: Timestamp? = nil) -> Deferred<Maybe<StorageResponse<POSTResult>>> {
    var headers = [String: NSNumber]()
    if let lastModified = lastModified {
        headers["X-Last-Modified"] = NSNumber(unsignedLongLong: lastModified)
    }

    return deferMaybe(
        StorageResponse(value: POSTResult(success: [], failed: [:], batchToken: batchToken), metadata: ResponseMetadata(status: 200, headers: headers))
    )
}

// Small helper operator for comparing query parameters below
private func ==(param1: NSURLQueryItem, param2: NSURLQueryItem) -> Bool {
    return param1.name == param2.name && param1.value == param2.value
}

private let miniConfig = InfoConfiguration(maxRequestBytes: 1_048_576, maxPostRecords: 2, maxPostBytes: 1_048_576, maxTotalRecords: 10, maxTotalBytes: 104_857_600)

class Sync15BatchClientTests: XCTestCase {

    func testAddLargeRecordFails() {
        let uploader: BatchUploadFunction = { _ in deferEmptyResponse(lastModified: 10_000) }
        let serializeRecord = { massivify($0)?.toString() }

        let batch = Sync15BatchClient(config: miniConfig,
                                      ifUnmodifiedSince: nil,
                                      serializeRecord: serializeRecord,
                                      uploader: uploader,
                                      onCollectionUploaded: { _ in deferMaybe(NSDate.now())})

        let record = createRecordWithID("A")
        let result = batch.addRecords([record]).value
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(result.failureValue! is RecordTooLargeError)
    }

    func testFailToSerializeRecord() {
        let uploader: BatchUploadFunction = { _ in deferEmptyResponse(lastModified: 10_000) }
        let batch = Sync15BatchClient(config: miniConfig,
                                      ifUnmodifiedSince: nil,
                                      serializeRecord: { _ in nil },
                                      uploader: uploader,
                                      onCollectionUploaded: { _ in deferMaybe(NSDate.now())})

        let record = createRecordWithID("A")
        let result = batch.addRecords([record]).value
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(result.failureValue! is SerializeRecordFailure)
    }

    func testBackoffDuringBatchUploading() {
        let uploader: BatchUploadFunction = { lines, ius, queryParams in
            deferMaybe(ServerInBackoffError(until: 10_000))
        }

        // Setup a configuration so each batch supports two payloads of two records each
        let twoRecordBatchesConfig = InfoConfiguration(
            maxRequestBytes: 1_048_576,
            maxPostRecords: 1,
            maxPostBytes: 1_048_576,
            maxTotalRecords: 4,
            maxTotalBytes: 104_857_600
        )

        let batch = Sync15BatchClient(config: twoRecordBatchesConfig,
                                      ifUnmodifiedSince: 10_000,
                                      serializeRecord: basicSerializer,
                                      uploader: uploader,
                                      onCollectionUploaded: { _ in deferMaybe(NSDate.now())})

        let record = createRecordWithID("A")
        batch.addRecords([record]).succeeded()
        let result = batch.endBatch().value

        // Verify that when the server goes into backoff, we get those bubbled up through the batching client
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(result.failureValue! is ServerInBackoffError)
    }

    func testIfUnmodifiedSinceUpdatesForSinglePOSTs() {
        var requestCount = 0
        var linesSent = [String]()
        var lastIUS: Timestamp? = 0

        // Since we never return a batch token, the batch client won't batch upload and default to single POSTs
        let uploader: BatchUploadFunction = { lines, ius, _ in
            linesSent += lines
            requestCount += 1
            switch requestCount {
            case 1:
                XCTAssertEqual(ius, 10_000_000)
                return deferEmptyResponse(lastModified: 20_000)
            case 2:
                XCTAssertEqual(ius, 20_000_000)
                return deferEmptyResponse(lastModified: 30_000)
            case 3:
                XCTAssertEqual(ius, 30_000_000)
                lastIUS = ius
                return deferEmptyResponse(lastModified: 30_000)
            default:
                XCTFail()
                return deferEmptyResponse(lastModified: 0)
            }
        }

        let singleRecordConfig = InfoConfiguration(
            maxRequestBytes: 1_048_576,
            maxPostRecords: 1,
            maxPostBytes: 1_048_576,
            maxTotalRecords: 10,
            maxTotalBytes: 104_857_600
        )

        let batch = Sync15BatchClient(config: singleRecordConfig,
                                      ifUnmodifiedSince: 10_000_000,
                                      serializeRecord: basicSerializer,
                                      uploader: uploader,
                                      onCollectionUploaded: { _ in deferMaybe(NSDate.now())})

        let recordA = createRecordWithID("A")
        let recordB = createRecordWithID("B")
        let recordC = createRecordWithID("C")
        let allRecords = [recordA, recordB, recordC]

        batch.addRecords([recordA, recordB, recordC]).succeeded()
        batch.endBatch().succeeded()

        // Validate number of requests sent
        XCTAssertEqual(requestCount, 3)

        // Validate contents sent to the server
        assertLinesMatchRecords(linesSent, records: allRecords, serializer: basicSerializer)

        // Validate the last IUS we got is the last request
        XCTAssertEqual(lastIUS, 30_000_000)
    }

    func testUploadBatchUnsupportedBatching() {
        var requestCount = 0
        var uploadedCollectionCount = 0
        var linesSent = [String]()

        // Since we never return a batch token, the batch client won't batch upload and default to single POSTs
        let uploader: BatchUploadFunction = { lines, ius, _ in
            linesSent += lines
            requestCount += 1
            return deferEmptyResponse(lastModified: 10_000)
        }

        let collectionUploaded: (POSTResult, Timestamp?) -> DeferredTimestamp = { _ in
            uploadedCollectionCount += 1
            return deferMaybe(NSDate.now())
        }

        // Setup a configuration so we each payload would be one record
        let twoRecordBatchesConfig = InfoConfiguration(
            maxRequestBytes: 1_048_576,
            maxPostRecords: 1,
            maxPostBytes: 1_048_576,
            maxTotalRecords: 10,
            maxTotalBytes: 104_857_600
        )

        let batch = Sync15BatchClient(config: twoRecordBatchesConfig,
                                      ifUnmodifiedSince: 10_000,
                                      serializeRecord: basicSerializer,
                                      uploader: uploader,
                                      onCollectionUploaded: collectionUploaded)

        let recordA = createRecordWithID("A")
        let recordB = createRecordWithID("B")
        let allRecords = [recordA, recordB]

        batch.addRecords([recordA, recordB]).succeeded()
        batch.endBatch().succeeded()

        // Validate number of requests sent. One for the start post, and one for the committing
        XCTAssertEqual(requestCount, 2)

        // Validate contents sent to the server
        assertLinesMatchRecords(linesSent, records: allRecords, serializer: basicSerializer)

        // Validate we only made 2 calls to collection uploaded since we're doing single POSTs
        XCTAssertEqual(uploadedCollectionCount, 2)
    }

    /**
     Tests sending a batch consisting of 3 full payloads. This batch is regular in the sense that it should
     contain a batch=true call, an upload within the batch, and finish with a commit=true upload.
     */
    func testUploadRegularSingleBatch() {
        var requestCount = 0
        var uploadedCollectionCount = 0
        var linesSent = [String]()

        let allRecords: [Record<CleartextPayloadJSON>] = "ABCDEF".characters.reduce([]) { list, char in
            return list + [createRecordWithID(String(char))]
        }

        // Since we never return a batch token, the batch client won't batch upload and default to single POSTs
        let uploader: BatchUploadFunction = { lines, ius, queryParams in
            linesSent += lines
            requestCount += 1
            switch requestCount {
            case 1:
                let expected = NSURLQueryItem(name: "batch", value: "true")
                XCTAssertEqual(expected, queryParams![0])
                XCTAssertEqual(ius, 10_000)
                assertLinesMatchRecords(lines, records: Array(allRecords[0..<2]), serializer: basicSerializer)
                return deferEmptyResponse(batchToken: "1", lastModified: 10_000)
            case 2:
                let expected = NSURLQueryItem(name: "batch", value: "1")
                XCTAssertEqual(expected, queryParams![0])
                XCTAssertEqual(ius, 10_000_000)
                assertLinesMatchRecords(lines, records: Array(allRecords[2..<4]), serializer: basicSerializer)
                return deferEmptyResponse(batchToken: "1", lastModified: 10_000)
            case 3:
                let expectedBatch = NSURLQueryItem(name: "batch", value: "1")
                let expectedCommit = NSURLQueryItem(name: "commit", value: "true")
                XCTAssertEqual(expectedBatch, queryParams![0])
                XCTAssertEqual(expectedCommit, queryParams![1])
                XCTAssertEqual(ius, 10_000_000)
                assertLinesMatchRecords(lines, records: Array(allRecords[4..<6]), serializer: basicSerializer)
                return deferEmptyResponse(lastModified: 20_000)
            default:
                XCTFail()
                return deferEmptyResponse(lastModified: 0)
            }
        }

        let collectionUploaded: (POSTResult, Timestamp?) -> DeferredTimestamp = { _ in
            uploadedCollectionCount += 1
            return deferMaybe(NSDate.now())
        }

        // Setup a configuration so we send 2 records per each payload
        let twoRecordBatchesConfig = InfoConfiguration(
            maxRequestBytes: 1_048_576,
            maxPostRecords: 2,
            maxPostBytes: 1_048_576,
            maxTotalRecords: 10,
            maxTotalBytes: 104_857_600
        )

        let batch = Sync15BatchClient(config: twoRecordBatchesConfig,
                                      ifUnmodifiedSince: 10_000,
                                      serializeRecord: basicSerializer,
                                      uploader: uploader,
                                      onCollectionUploaded: collectionUploaded)

        batch.addRecords(allRecords).succeeded()
        batch.endBatch().succeeded()

        // Validate number of requests sent. One for the start post, and one for the committing
        XCTAssertEqual(requestCount, 3)

        // Validate contents sent to the server
        assertLinesMatchRecords(linesSent, records: allRecords, serializer: basicSerializer)

        // Validate we only made one call to the collection upload callback
        XCTAssertEqual(uploadedCollectionCount, 2)
        XCTAssertEqual(batch.ifUnmodifiedSince!, 20_000_000)
    }

    /**
     Tests pushing a batch where one of the payloads is not at limit.
     */
    func testBatchUploadWithPartialPayload() {
        var requestCount = 0
        var uploadedCollectionCount = 0
        var linesSent = [String]()

        let allRecords: [Record<CleartextPayloadJSON>] = "ABC".characters.reduce([]) { list, char in
            return list + [createRecordWithID(String(char))]
        }

        // Since we never return a batch token, the batch client won't batch upload and default to single POSTs
        let uploader: BatchUploadFunction = { lines, ius, queryParams in
            linesSent += lines
            requestCount += 1
            switch requestCount {
            case 1:
                let expected = NSURLQueryItem(name: "batch", value: "true")
                XCTAssertEqual(expected, queryParams![0])
                XCTAssertEqual(ius, 10_000)
                assertLinesMatchRecords(lines, records: Array(allRecords[0..<2]), serializer: basicSerializer)
                return deferEmptyResponse(batchToken: "1", lastModified: 10_000)
            case 2:
                let expectedBatch = NSURLQueryItem(name: "batch", value: "1")
                let expectedCommit = NSURLQueryItem(name: "commit", value: "true")
                XCTAssertEqual(expectedBatch, queryParams![0])
                XCTAssertEqual(expectedCommit, queryParams![1])
                XCTAssertEqual(ius, 10_000_000)
                assertLinesMatchRecords(lines, records: Array(allRecords[2..<3]), serializer: basicSerializer)
                return deferEmptyResponse(lastModified: 20_000)
            default:
                XCTFail()
                return deferEmptyResponse(lastModified: 0)
            }
        }

        let collectionUploaded: (POSTResult, Timestamp?) -> DeferredTimestamp = { _ in
            uploadedCollectionCount += 1
            return deferMaybe(NSDate.now())
        }

        // Setup a configuration so we send 2 records per each payload
        let twoRecordBatchesConfig = InfoConfiguration(
            maxRequestBytes: 1_048_576,
            maxPostRecords: 2,
            maxPostBytes: 1_048_576,
            maxTotalRecords: 10,
            maxTotalBytes: 104_857_600
        )

        let batch = Sync15BatchClient(config: twoRecordBatchesConfig,
                                      ifUnmodifiedSince: 10_000,
                                      serializeRecord: basicSerializer,
                                      uploader: uploader,
                                      onCollectionUploaded: collectionUploaded)

        batch.addRecords(allRecords).succeeded()
        batch.endBatch().succeeded()

        // Validate number of requests sent. One for the start post, and one for the committing
        XCTAssertEqual(requestCount, 2)

        // Validate contents sent to the server
        assertLinesMatchRecords(linesSent, records: allRecords, serializer: basicSerializer)

        // Validate we only made one call to the collection upload callback
        XCTAssertEqual(uploadedCollectionCount, 2)
        XCTAssertEqual(batch.ifUnmodifiedSince!, 20_000_000)
    }

    /**
     Attempt to send 3 payloads: 2 which are full, 1 that is partial, within a batch that only supports 5 records.
     */
    func testBatchUploadWithUnevenPayloadsInBatch() {
        var requestCount = 0
        var uploadedCollectionCount = 0
        var linesSent = [String]()

        let allRecords: [Record<CleartextPayloadJSON>] = "ABCDE".characters.reduce([]) { list, char in
            return list + [createRecordWithID(String(char))]
        }

        // Since we never return a batch token, the batch client won't batch upload and default to single POSTs
        let uploader: BatchUploadFunction = { lines, ius, queryParams in
            linesSent += lines
            requestCount += 1
            switch requestCount {
            case 1:
                let expected = NSURLQueryItem(name: "batch", value: "true")
                XCTAssertEqual(expected, queryParams![0])
                XCTAssertEqual(ius, 10_000)
                assertLinesMatchRecords(lines, records: Array(allRecords[0..<2]), serializer: basicSerializer)
                return deferEmptyResponse(batchToken: "1", lastModified: 10_000)
            case 2:
                let expectedBatch = NSURLQueryItem(name: "batch", value: "1")
                XCTAssertEqual(expectedBatch, queryParams![0])
                XCTAssertEqual(ius, 10_000_000)
                assertLinesMatchRecords(lines, records: Array(allRecords[2..<4]), serializer: basicSerializer)
                return deferEmptyResponse(lastModified: 10_000)
            case 3:
                let expectedBatch = NSURLQueryItem(name: "batch", value: "1")
                let expectedCommit = NSURLQueryItem(name: "commit", value: "true")
                XCTAssertEqual(expectedBatch, queryParams![0])
                XCTAssertEqual(expectedCommit, queryParams![1])
                XCTAssertEqual(ius, 10_000_000)
                assertLinesMatchRecords(lines, records: [allRecords[4]], serializer: basicSerializer)
                return deferEmptyResponse(lastModified: 20_000)
            default:
                XCTFail()
                return deferEmptyResponse(lastModified: 0)
            }
        }

        let collectionUploaded: (POSTResult, Timestamp?) -> DeferredTimestamp = { _ in
            uploadedCollectionCount += 1
            return deferMaybe(NSDate.now())
        }

        // Setup a configuration so we send 2 records per each payload
        let twoRecordBatchesConfig = InfoConfiguration(
            maxRequestBytes: 1_048_576,
            maxPostRecords: 2,
            maxPostBytes: 1_048_576,
            maxTotalRecords: 5,
            maxTotalBytes: 104_857_600
        )

        let batch = Sync15BatchClient(config: twoRecordBatchesConfig,
                                      ifUnmodifiedSince: 10_000,
                                      serializeRecord: basicSerializer,
                                      uploader: uploader,
                                      onCollectionUploaded: collectionUploaded)

        batch.addRecords(allRecords).succeeded()
        batch.endBatch().succeeded()

        // Validate number of requests sent. One for the start post, and one for the committing
        XCTAssertEqual(requestCount, 3)

        // Validate contents sent to the server
        assertLinesMatchRecords(linesSent, records: allRecords, serializer: basicSerializer)

        // Validate we only made one call to the collection upload callback
        XCTAssertEqual(uploadedCollectionCount, 2)
        XCTAssertEqual(batch.ifUnmodifiedSince!, 20_000_000)
    }

    /**
     Tests pushing up a single payload as part of a batch.
     */
    func testBatchUploadWithSinglePayload() {
        var requestCount = 0
        var uploadedCollectionCount = 0
        var linesSent = [String]()

        let recordA = createRecordWithID("A")

        // Since we never return a batch token, the batch client won't batch upload and default to single POSTs
        let uploader: BatchUploadFunction = { lines, ius, queryParams in
            linesSent += lines
            requestCount += 1
            switch requestCount {
            case 1:
                let expectedBatch = NSURLQueryItem(name: "batch", value: "true")
                let expectedCommit = NSURLQueryItem(name: "commit", value: "true")
                XCTAssertEqual(expectedBatch, queryParams![0])
                XCTAssertEqual(expectedCommit, queryParams![1])
                XCTAssertEqual(ius, 10_000)
                assertLinesMatchRecords(lines, records: [recordA], serializer: basicSerializer)
                return deferEmptyResponse(lastModified: 20_000)
            default:
                XCTFail()
                return deferEmptyResponse(lastModified: 0)
            }
        }

        let collectionUploaded: (POSTResult, Timestamp?) -> DeferredTimestamp = { _ in
            uploadedCollectionCount += 1
            return deferMaybe(NSDate.now())
        }

        // Setup a configuration so we send 2 records per each payload
        let twoRecordBatchesConfig = InfoConfiguration(
            maxRequestBytes: 1_048_576,
            maxPostRecords: 2,
            maxPostBytes: 1_048_576,
            maxTotalRecords: 10,
            maxTotalBytes: 104_857_600
        )

        let batch = Sync15BatchClient(config: twoRecordBatchesConfig,
                                      ifUnmodifiedSince: 10_000,
                                      serializeRecord: basicSerializer,
                                      uploader: uploader,
                                      onCollectionUploaded: collectionUploaded)

        batch.addRecords([recordA]).succeeded()
        batch.endBatch().succeeded()

        // Validate number of requests sent. One for the start post, and one for the committing
        XCTAssertEqual(requestCount, 1)

        // Validate contents sent to the server
        assertLinesMatchRecords(linesSent, records: [recordA], serializer: basicSerializer)

        // Validate we only made one call to the collection upload callback
        XCTAssertEqual(uploadedCollectionCount, 1)
        XCTAssertEqual(batch.ifUnmodifiedSince!, 20_000_000)
    }

    func testMultipleBatchUpload() {
        var requestCount = 0
        var uploadedCollectionCount = 0
        var linesSent = [String]()

        let allRecords: [Record<CleartextPayloadJSON>] = "ABCDEFGHIJKL".characters.reduce([]) { list, char in
            return list + [createRecordWithID(String(char))]
        }

        // For each upload, verify that we are getting the correct queryParams and records to be sent.
        let uploader: BatchUploadFunction = { lines, ius, queryParams in
            linesSent += lines
            requestCount += 1
            switch requestCount {
            case 1:
                let expected = NSURLQueryItem(name: "batch", value: "true")
                XCTAssertEqual(expected, queryParams![0])
                assertLinesMatchRecords(lines, records: Array(allRecords[0..<2]), serializer: basicSerializer)
                return deferEmptyResponse(batchToken: "1", lastModified: 20_000)
            case 2:
                let expectedBatch = NSURLQueryItem(name: "batch", value: "1")
                XCTAssertEqual(expectedBatch, queryParams![0])
                assertLinesMatchRecords(lines, records: Array(allRecords[2..<4]), serializer: basicSerializer)
                return deferEmptyResponse(lastModified: 20_000)
            case 3:
                let expectedBatch = NSURLQueryItem(name: "batch", value: "1")
                let expectedCommit = NSURLQueryItem(name: "commit", value: "true")
                XCTAssertEqual(expectedBatch, queryParams![0])
                XCTAssertEqual(expectedCommit, queryParams![1])
                assertLinesMatchRecords(lines, records: Array(allRecords[4..<6]), serializer: basicSerializer)
                return deferEmptyResponse(lastModified: 20_000)
            case 4:
                let expected = NSURLQueryItem(name: "batch", value: "true")
                XCTAssertEqual(expected, queryParams![0])
                assertLinesMatchRecords(lines, records: Array(allRecords[6..<8]), serializer: basicSerializer)
                return deferEmptyResponse(batchToken: "2", lastModified: 30_000)
            case 5:
                let expectedBatch = NSURLQueryItem(name: "batch", value: "2")
                XCTAssertEqual(expectedBatch, queryParams![0])
                assertLinesMatchRecords(lines, records: Array(allRecords[8..<10]), serializer: basicSerializer)
                return deferEmptyResponse(lastModified: 30_000)
            case 6:
                let expectedBatch = NSURLQueryItem(name: "batch", value: "2")
                let expectedCommit = NSURLQueryItem(name: "commit", value: "true")
                XCTAssertEqual(expectedBatch, queryParams![0])
                XCTAssertEqual(expectedCommit, queryParams![1])
                assertLinesMatchRecords(lines, records: Array(allRecords[10..<12]), serializer: basicSerializer)
                return deferEmptyResponse(lastModified: 30_000)
            default:
                XCTFail()
                return deferEmptyResponse(lastModified: 0)
            }
        }

        let collectionUploaded: (POSTResult, Timestamp?) -> DeferredTimestamp = { _ in
            uploadedCollectionCount += 1
            return deferMaybe(NSDate.now())
        }

        // Setup a configuration so each batch supports two payloads of two records each
        let twoRecordBatchesConfig = InfoConfiguration(
            maxRequestBytes: 1_048_576,
            maxPostRecords: 2,
            maxPostBytes: 1_048_576,
            maxTotalRecords: 6,
            maxTotalBytes: 104_857_600
        )

        let batch = Sync15BatchClient(config: twoRecordBatchesConfig,
                                      ifUnmodifiedSince: 10_000_000,
                                      serializeRecord: basicSerializer,
                                      uploader: uploader,
                                      onCollectionUploaded: collectionUploaded)

        batch.addRecords(allRecords).succeeded()
        batch.endBatch().succeeded()

        // Validate number of requests sent. One for the start post, and one for the committing
        XCTAssertEqual(requestCount, 6)

        // Validate contents sent to the server
        assertLinesMatchRecords(linesSent, records: allRecords, serializer: basicSerializer)

        // Validate we only called collection uploaded when we start and finish a batch. The uploads inside
        // a batch should not trigger the callback.
        XCTAssertEqual(uploadedCollectionCount, 4)
    }
}
