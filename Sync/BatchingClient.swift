/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared
import XCGLogger
import Deferred

public class SerializeRecordFailure<T: CleartextPayloadJSON>: MaybeErrorType {
    public let record: Record<T>

    public var description: String {
        return "Failed to serialize record: \(record)"
    }

    public init(record: Record<T>) {
        self.record = record
    }
}

private let log = Logger.syncLogger

private typealias UploadRecord = (guid: GUID, payload: String, sizeBytes: Int)
private typealias DeferredResponse = Deferred<Maybe<StorageResponse<POSTResult>>>

typealias BatchUploadFunction = (lines: [String], ifUnmodifiedSince: Timestamp?, queryParams: [NSURLQueryItem]?) -> Deferred<Maybe<StorageResponse<POSTResult>>>

private let commitParam = NSURLQueryItem(name: "commit", value: "true")

private enum AccumulateRecordError: MaybeErrorType {
    var description: String {
        switch self {
        case .Full:
            return "Batch or payload is full."
        case .Unknown:
            return "Unknown errored while trying to accumulate records in batch"
        }
    }

    case Full(uploadOp: DeferredResponse)
    case Unknown
}

public class Sync15BatchClient<T: CleartextPayloadJSON> {
    private(set) var ifUnmodifiedSince: Timestamp?

    private let config: InfoConfiguration
    private let uploader: BatchUploadFunction
    private let serializeRecord: (Record<T>) -> String?

    private var batchToken: BatchToken?

    // Keep track of the limits of a single batch
    private var totalBytes: ByteCount = 0
    private var totalRecords: Int = 0

    // Keep track of the limits of a single POST
    private var postBytes: ByteCount = 0
    private var postRecords: Int = 0

    private var records = [UploadRecord]()

    private var onCollectionUploaded: (POSTResult, Timestamp?) -> DeferredTimestamp

    private func batchQueryParamWithValue(value: String) -> NSURLQueryItem {
        return NSURLQueryItem(name: "batch", value: value)
    }

    init(config: InfoConfiguration, ifUnmodifiedSince: Timestamp? = nil, serializeRecord: (Record<T>) -> String?,
         uploader: BatchUploadFunction, onCollectionUploaded: (POSTResult, Timestamp?) -> DeferredTimestamp) {
        self.config = config
        self.ifUnmodifiedSince = ifUnmodifiedSince
        self.uploader = uploader
        self.serializeRecord = serializeRecord

        self.onCollectionUploaded = onCollectionUploaded
    }

    public func endBatch() -> Success {
        guard !records.isEmpty else {
            return succeed()
        }

        if let token = self.batchToken {
            return commitBatch(token) >>> succeed
        }

        let lines = self.freezePost()
        return self.uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: nil)
            >>== effect(moveForward)
            >>> succeed
    }

    public func addRecords(records: [Record<T>]) -> Success {
        guard !records.isEmpty else {
            return succeed()
        }

        do {
            // Eagerly serializer the record prior to processing them so we can catch any issues
            // with record sizes before we start uploading to the server.
            let serialized = try records.map { try serialize($0) }
            return addRecords(serialized.generate())
        } catch let e {
            return deferMaybe(e as! MaybeErrorType)
        }
    }

    private func addRecords(generator: IndexingGenerator<[UploadRecord]>) -> Success {
        var mutGenerator = generator
        while let record = mutGenerator.next() {
            return accumulateOrUpload(record) >>> { self.addRecords(mutGenerator) }
        }
        return succeed()
    }

    private func accumulateOrUpload(record: UploadRecord) -> Success {
        do {
            // Try to add the record to our buffer
            try accumulateRecord(record)
        } catch AccumulateRecordError.Full(let uploadOp) {
            // When we're full, run the upload and try to add the record
            // after uploading since we've made room for it.
            return uploadOp >>> { self.accumulateOrUpload(record) }
        } catch let e {
            // Should never happen.
            return deferMaybe(e as! MaybeErrorType)
        }
        return succeed()
    }

    private func accumulateRecord(record: UploadRecord) throws {
        guard let token = self.batchToken else {
            guard addToPost(record) else {
                throw AccumulateRecordError.Full(uploadOp: self.start())
            }
            return
        }

        guard fitsInBatch(record) else {
            throw AccumulateRecordError.Full(uploadOp: self.commitBatch(token))
        }

        guard addToPost(record) else {
            throw AccumulateRecordError.Full(uploadOp: self.postInBatch(token))
        }

        addToBatch(record)
    }

    private func serialize(record: Record<T>) throws -> UploadRecord {
        guard let line = self.serializeRecord(record) else {
            throw SerializeRecordFailure(record: record)
        }

        let lineSize = line.utf8.count
        guard lineSize < Sync15StorageClient.maxRecordSizeBytes else {
            throw RecordTooLargeError(size: lineSize, guid: record.id)
        }

        return (record.id, line, lineSize)
    }

    private func addToPost(record: UploadRecord) -> Bool {
        guard postRecords + 1 <= config.maxPostRecords && postBytes + record.sizeBytes <= config.maxPostBytes else {
            return false
        }
        postRecords += 1
        postBytes += record.sizeBytes
        records.append(record)
        return true
    }

    private func fitsInBatch(record: UploadRecord) -> Bool {
        return totalRecords + 1 <= config.maxTotalRecords && totalBytes + record.sizeBytes <= config.maxTotalBytes
    }

    private func addToBatch(record: UploadRecord) {
        totalRecords += 1
        totalBytes += record.sizeBytes
    }

    private func postInBatch(token: BatchToken) -> DeferredResponse {
        // Push up the current payload to the server and reset
        let lines = self.freezePost()
        return uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: [batchQueryParamWithValue(token)])
    }

    private func commitBatch(token: BatchToken) -> DeferredResponse {
        resetBatch()
        let lines = self.freezePost()
        let queryParams = [batchQueryParamWithValue(token), commitParam]
        return uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: queryParams)
            >>== effect(moveForward)
    }

    private func start() -> DeferredResponse {
        let postRecordCount = self.postRecords
        let postBytesCount = self.postBytes
        let lines = freezePost()
        return self.uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: [batchQueryParamWithValue("true")])
             >>== effect(moveForward)
             >>== { response in
                if let token = response.value.batchToken {
                    self.batchToken = token

                    // Now that we've started a batch, make sure to set the counters for the batch to include
                    // the records we just sent as part of the start call.
                    self.totalRecords = postRecordCount
                    self.totalBytes = postBytesCount
                }

                return deferMaybe(response)
            }
    }

    private func moveForward(response: StorageResponse<POSTResult>) {
        let lastModified = response.metadata.lastModifiedMilliseconds
        self.ifUnmodifiedSince = lastModified
        self.onCollectionUploaded(response.value, lastModified)
    }

    private func resetBatch() {
        totalBytes = 0
        totalRecords = 0
        self.batchToken = nil
    }

    private func freezePost() -> [String] {
        let lines = records.map { $0.payload }
        self.records = []
        self.postBytes = 0
        self.postRecords = 0
        return lines
    }
}
