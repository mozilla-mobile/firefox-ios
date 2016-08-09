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

private let deferEmptyResponse: () -> Deferred<Maybe<StorageResponse<POSTResult>>> = {
    return deferMaybe(
        StorageResponse(value: POSTResult(modified: NSDate.now(), success: [], failed: [:]), metadata: ResponseMetadata(status: 200, headers: [:]))
    )
}

private let miniConfig = InfoConfiguration(maxRequestBytes: 1048576, maxPostRecords: 2, maxPostBytes: 1048576, maxTotalRecords: 10, maxTotalBytes: 104857600)

class Sync15BatchClientTests: XCTestCase {

    func testAddLargeRecordFails() {
        let uploader: BatchUploadFunction = { _ in deferEmptyResponse() }
        let serializeRecord = { massivify($0)?.toString() }

        let batch = Sync15BatchClient(config: miniConfig,
                                      ifUnmodifiedSince: nil,
                                      serializeRecord: serializeRecord,
                                      uploader: uploader,
                                      onCollectionUploaded: nil)

        let jA = "{\"id\":\"mock\",\"histUri\":\"http://foo.com/\",\"title\": \"ñ\",\"visits\":[{\"date\":1222222222222222,\"type\":1}]}"
        let record = Record<CleartextPayloadJSON>(id: "mock",payload: CleartextPayloadJSON(JSON.parse(jA)), modified: 10000, sortindex: 123, ttl: 1000000)

        let result = batch.addRecord(record).value
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(result.failureValue! is RecordTooLargeError)
    }

    func testFailToSerializeRecord() {
        let uploader: BatchUploadFunction = { _ in deferEmptyResponse() }
        let batch = Sync15BatchClient(config: miniConfig,
                                      ifUnmodifiedSince: nil,
                                      serializeRecord: { _ in nil },
                                      uploader: uploader,
                                      onCollectionUploaded: nil)

        let jA = "{\"id\":\"mock\",\"histUri\":\"http://foo.com/\",\"title\": \"ñ\",\"visits\":[{\"date\":1222222222222222,\"type\":1}]}"
        let record = Record<CleartextPayloadJSON>(id: "mock",payload: CleartextPayloadJSON(JSON.parse(jA)), modified: 10000, sortindex: 123, ttl: 1000000)

        let result = batch.addRecord(record).value
        XCTAssertTrue(result.isFailure)
        XCTAssertTrue(result.failureValue! is SerializeRecordFailure)
    }

    func testIfUnmodifiedSinceUpdates() {
        let firstResponse  =
            StorageResponse(value: POSTResult(modified: 20000, success: [], failed: [:]), metadata: ResponseMetadata(status: 200, headers: [:]))
        let secondResponse =
            StorageResponse(value: POSTResult(modified: 30000, success: [], failed: [:]), metadata: ResponseMetadata(status: 200, headers: [:]))
        var requestCount = 0

        // Since we never return a batch token, the batch client won't batch upload and default to single POSTs
        let uploader: BatchUploadFunction = { _, ius, _ in
            requestCount += 1
            switch requestCount {
            case 1:
                XCTAssertEqual(ius, 10000)
                return deferMaybe(firstResponse)
            case 2:
                XCTAssertEqual(ius, 20000)
                return deferMaybe(secondResponse)
            case 3:
                XCTAssertEqual(ius, 30000)
                return deferEmptyResponse()
            default:
                XCTFail()
                return deferEmptyResponse()
            }
        }

        let serializeRecord: (Record<CleartextPayloadJSON>) -> String = { record in
            return JSON(["id": record.id, "foo": "foo"]).toString()
        }

        let singleRecordConfig = InfoConfiguration(
            maxRequestBytes: 1048576,
            maxPostRecords: 1,
            maxPostBytes: 1048576,
            maxTotalRecords: 10,
            maxTotalBytes: 104857600
        )

        let batch = Sync15BatchClient(config: singleRecordConfig,
                                      ifUnmodifiedSince: 10000,
                                      serializeRecord: serializeRecord,
                                      uploader: uploader,
                                      onCollectionUploaded: nil)

        let recordA = Record<CleartextPayloadJSON>(id: "A", payload: CleartextPayloadJSON(JSON.parse("{}")), modified: 10000, sortindex: 123, ttl: 1000000)
        let recordB = Record<CleartextPayloadJSON>(id: "B", payload: CleartextPayloadJSON(JSON.parse("{}")), modified: 10000, sortindex: 123, ttl: 1000000)
        let recordC = Record<CleartextPayloadJSON>(id: "C", payload: CleartextPayloadJSON(JSON.parse("{}")), modified: 10000, sortindex: 123, ttl: 1000000)

        batch.addRecord(recordA).succeeded()
        batch.addRecord(recordB).succeeded()
        batch.addRecord(recordC).succeeded()
        XCTAssertEqual(requestCount, 3)
    }
}