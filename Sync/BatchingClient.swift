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

private typealias UploadRecord = (guid: GUID, payload: String, size: Int)
private typealias DeferredResponse = Deferred<Maybe<StorageResponse<POSTResult>>>

typealias BatchUploadFunction = (lines: [String], ifUnmodifiedSince: Timestamp?, queryParams: [NSURLQueryItem]?) -> Deferred<Maybe<StorageResponse<POSTResult>>>

public class Sync15BatchClient<T: CleartextPayloadJSON> {
    private(set) var ifUnmodifiedSince: Timestamp?

    private let config: InfoConfiguration
    private let uploader: BatchUploadFunction
    private let serializeRecord: (Record<T>) -> String?

    private let commitParam = NSURLQueryItem(name: "commit", value: "true")

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
        } else {
            let lines = self.freezePost()
            let queryParams = [
                batchQueryParamWithValue("true"),
                NSURLQueryItem(name: "commit", value: "true")
            ]
            return self.uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: queryParams)
                >>== effect(moveForward)
                >>> succeed
        }
    }

    public func addRecords(records: [Record<T>]) -> Success {
        guard !records.isEmpty else {
            return succeed()
        }

        do {
            let serialized = try records.map { try serialize($0) }
            return addRecords(serialized.generate())
        } catch let e {
            return deferMaybe(e as! MaybeErrorType)
        }
    }

    private func addRecords(generator: IndexingGenerator<[UploadRecord]>) -> Success {
        var mutGenerator = generator
        while let record = mutGenerator.next() {
            if let uploadOp = accumulateRecord(record) {
                return uploadOp >>> {
                    if let deferred = self.accumulateRecord(record) {
                        return deferred >>> { self.addRecords(mutGenerator) }
                    }
                    return self.addRecords(mutGenerator)
                }
            }
        }
        return succeed()
    }

    private func accumulateRecord(record: UploadRecord) -> DeferredResponse? {
        if let token = self.batchToken {
            if fitsInBatch(record) {
                if addToPost(record) {
                    // Only count the record towards the batch if we could add it to a payload...
                    addToBatch(record)
                    return nil
                } else {
                    // Otherwise, we don't added the record and just POST away.
                    return postInBatch(token)
                }
            } else {
                return commitBatch(token)
            }
        } else {
            return addToPost(record) ? nil : start()
        }
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
        guard postRecords + 1 <= config.maxPostRecords && postBytes + record.size <= config.maxPostBytes else {
            return false
        }
        postRecords += 1
        postBytes += record.size
        records.append(record)
        return true
    }

    private func fitsInBatch(record: UploadRecord) -> Bool {
        return totalRecords + 1 <= config.maxTotalRecords && totalBytes + record.size <= config.maxTotalBytes
    }

    private func addToBatch(record: UploadRecord) {
        totalRecords += 1
        totalBytes += record.size
    }

    private func postInBatch(token: BatchToken) -> DeferredResponse {
        // Push up the current payload to the server and reset
        let lines = self.freezePost()
        return uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: [batchQueryParamWithValue(token)])
    }

    private func commitBatch(token: BatchToken) -> DeferredResponse {
        resetBatch()
        let lines = self.freezePost()
        let queryParams = [
            batchQueryParamWithValue(token),
            NSURLQueryItem(name: "commit", value: "true")
        ]
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
