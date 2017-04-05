/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared
import XCGLogger
import Deferred

open class SerializeRecordFailure<T: CleartextPayloadJSON>: MaybeErrorType {
    open let record: Record<T>

    open var description: String {
        return "Failed to serialize record: \(record)"
    }

    public init(record: Record<T>) {
        self.record = record
    }
}

private let log = Logger.syncLogger

private typealias UploadRecord = (guid: GUID, payload: String, sizeBytes: Int)
private typealias DeferredResponse = Deferred<Maybe<StorageResponse<POSTResult>>>

typealias BatchUploadFunction = (_ lines: [String], _ ifUnmodifiedSince: Timestamp?, _ queryParams: [URLQueryItem]?) -> Deferred<Maybe<StorageResponse<POSTResult>>>

private let commitParam = URLQueryItem(name: "commit", value: "true")

private enum AccumulateRecordError: MaybeErrorType {
    var description: String {
        switch self {
        case .full:
            return "Batch or payload is full."
        case .unknown:
            return "Unknown errored while trying to accumulate records in batch"
        }
    }

    case full(uploadOp: DeferredResponse)
    case unknown
}

open class Sync15BatchClient<T: CleartextPayloadJSON> {
    fileprivate(set) var ifUnmodifiedSince: Timestamp?

    fileprivate let config: InfoConfiguration
    fileprivate let uploader: BatchUploadFunction
    fileprivate let serializeRecord: (Record<T>) -> String?

    fileprivate var batchToken: BatchToken?

    // Keep track of the limits of a single batch
    fileprivate var totalBytes: ByteCount = 0
    fileprivate var totalRecords: Int = 0

    // Keep track of the limits of a single POST
    fileprivate var postBytes: ByteCount = 0
    fileprivate var postRecords: Int = 0

    fileprivate var records = [UploadRecord]()

    fileprivate var onCollectionUploaded: (POSTResult, Timestamp?) -> DeferredTimestamp

    fileprivate func batchQueryParamWithValue(_ value: String) -> URLQueryItem {
        return URLQueryItem(name: "batch", value: value)
    }

    init(config: InfoConfiguration, ifUnmodifiedSince: Timestamp? = nil, serializeRecord: @escaping (Record<T>) -> String?,
         uploader: @escaping BatchUploadFunction, onCollectionUploaded: @escaping (POSTResult, Timestamp?) -> DeferredTimestamp) {
        self.config = config
        self.ifUnmodifiedSince = ifUnmodifiedSince
        self.uploader = uploader
        self.serializeRecord = serializeRecord

        self.onCollectionUploaded = onCollectionUploaded
    }

    open func endBatch() -> Success {
        guard !records.isEmpty else {
            return succeed()
        }

        if let token = self.batchToken {
            return commitBatch(token) >>> succeed
        }

        let lines = self.freezePost()
        return self.uploader(lines, self.ifUnmodifiedSince, nil)
            >>== effect(moveForward)
            >>> succeed
    }

    open func addRecords(_ records: [Record<T>]) -> Success {
        guard !records.isEmpty else {
            return succeed()
        }

        // Eagerly serializer the record prior to processing them so we can catch any issues
        // with record sizes before we start uploading to the server.
        let serializeThunks = records.map { record in
            return { self.serialize(record) }
        }

        return accumulate(serializeThunks) >>== { self.addRecords($0.makeIterator()) }
    }

    fileprivate func addRecords(_ generator: IndexingIterator<[UploadRecord]>) -> Success {
        var mutGenerator = generator
        while let record = mutGenerator.next() {
            return accumulateOrUpload(record) >>> { self.addRecords(mutGenerator) }
        }
        return succeed()
    }

    fileprivate func accumulateOrUpload(_ record: UploadRecord) -> Success {
        return accumulateRecord(record).bind { result in
            // Try to add the record to our buffer
            guard let e = result.failureValue as? AccumulateRecordError else {
                return succeed()
            }

            switch e {
            case .full(let uploadOp):
                return uploadOp >>> { self.accumulateOrUpload(record) }
            default:
                return deferMaybe(e)
            }
        }
    }

    fileprivate func accumulateRecord(_ record: UploadRecord) -> Success {
        guard let token = self.batchToken else {
            guard addToPost(record) else {
                return deferMaybe(AccumulateRecordError.full(uploadOp: self.start()))
            }
            return succeed()
        }

        guard fitsInBatch(record) else {
            return deferMaybe(AccumulateRecordError.full(uploadOp: self.commitBatch(token)))
        }

        guard addToPost(record) else {
            return deferMaybe(AccumulateRecordError.full(uploadOp: self.postInBatch(token)))
        }

        addToBatch(record)
        return succeed()
    }

    fileprivate func serialize(_ record: Record<T>) -> Deferred<Maybe<UploadRecord>> {
        guard let line = self.serializeRecord(record) else {
            return deferMaybe(SerializeRecordFailure(record: record))
        }

        let lineSize = line.utf8.count
        guard lineSize < Sync15StorageClient.maxRecordSizeBytes else {
            return deferMaybe(RecordTooLargeError(size: lineSize, guid: record.id))
        }

        return deferMaybe((record.id, line, lineSize))
    }

    fileprivate func addToPost(_ record: UploadRecord) -> Bool {
        guard postRecords + 1 <= config.maxPostRecords && postBytes + record.sizeBytes <= config.maxPostBytes else {
            return false
        }
        postRecords += 1
        postBytes += record.sizeBytes
        records.append(record)
        return true
    }

    fileprivate func fitsInBatch(_ record: UploadRecord) -> Bool {
        return totalRecords + 1 <= config.maxTotalRecords && totalBytes + record.sizeBytes <= config.maxTotalBytes
    }

    fileprivate func addToBatch(_ record: UploadRecord) {
        totalRecords += 1
        totalBytes += record.sizeBytes
    }

    fileprivate func postInBatch(_ token: BatchToken) -> DeferredResponse {
        // Push up the current payload to the server and reset
        let lines = self.freezePost()
        return uploader(lines, self.ifUnmodifiedSince, [batchQueryParamWithValue(token)])
    }

    fileprivate func commitBatch(_ token: BatchToken) -> DeferredResponse {
        resetBatch()
        let lines = self.freezePost()
        let queryParams = [batchQueryParamWithValue(token), commitParam]
        return uploader(lines, self.ifUnmodifiedSince, queryParams)
            >>== effect(moveForward)
    }

    fileprivate func start() -> DeferredResponse {
        let postRecordCount = self.postRecords
        let postBytesCount = self.postBytes
        let lines = freezePost()
        return self.uploader(lines, self.ifUnmodifiedSince, [batchQueryParamWithValue("true")])
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

    fileprivate func moveForward(_ response: StorageResponse<POSTResult>) {
        let lastModified = response.metadata.lastModifiedMilliseconds
        self.ifUnmodifiedSince = lastModified
        let _ = self.onCollectionUploaded(response.value, lastModified)
    }

    fileprivate func resetBatch() {
        totalBytes = 0
        totalRecords = 0
        self.batchToken = nil
    }

    fileprivate func freezePost() -> [String] {
        let lines = records.map { $0.payload }
        self.records = []
        self.postBytes = 0
        self.postRecords = 0
        return lines
    }
}
