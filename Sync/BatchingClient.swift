/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared
import XCGLogger
import Deferred

// MARK: Batch Client Errors
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

// MARK: Internal Types
private typealias UploadRecord = (guid: GUID, payload: String, size: Int)
private typealias DeferredResponse = Deferred<Maybe<StorageResponse<POSTResult>>>

/**
 *  A payload represents a block of records sent in a single POST to the server within a batch.
 *  The payload tries to contain as many records it can fit while respecting the limits imposed
 *  by the info/configuration endpoint.
 */
private struct Payload {
    let config: InfoConfiguration

    var isEmpty: Bool {
        return records.isEmpty
    }

    private(set) var records: [UploadRecord] = []
    private var bytes: ByteCount = 0
    private var count: Int = 0

    init(config: InfoConfiguration) {
        self.config = config
    }

    mutating func add(record: UploadRecord) -> Bool {
        guard (record.size + bytes + 1 <= config.maxPostBytes) && (count < config.maxPostRecords) else {
            return false
        }

        records.append(record)
        count += 1
        bytes += record.size + 1     // For newline.
        return true
    }
}

private struct Batch {
    let config: InfoConfiguration

    private let token: BatchToken
    private var bytes: ByteCount = 0
    private var count: Int = 0

    // Batch is full if we can't add another payload to it
    var isFull: Bool {
        return (config.maxPostRecords + count > config.maxTotalRecords) ||
               (config.maxPostBytes + bytes > config.maxTotalBytes)
    }

    var isEmpty: Bool {
        return count == 0
    }

    var commitParams: [NSURLQueryItem] {
        return [NSURLQueryItem(name: "batch", value: String(token)), NSURLQueryItem(name: "commit", value: "true")]
    }

    var batchParams: [NSURLQueryItem] {
        return [NSURLQueryItem(name: "batch", value: String(token))]
    }

    init(config: InfoConfiguration, token: BatchToken) {
        self.config = config
        self.token = token
    }

    mutating func add(payload: Payload) {
        count += payload.count
        bytes += payload.bytes
    }
}


// MARK: Batching Client

typealias BatchUploadFunction = (lines: [String], ifUnmodifiedSince: Timestamp?, queryParams: [NSURLQueryItem]?) -> Deferred<Maybe<StorageResponse<POSTResult>>>

public class Sync15BatchClient<T: CleartextPayloadJSON> {
    private(set) var ifUnmodifiedSince: Timestamp?

    private let config: InfoConfiguration
    private let uploader: BatchUploadFunction
    private let serializeRecord: (Record<T>) -> String?

    private let batchStartParam = NSURLQueryItem(name: "batch", value: "true")
    private let commitParam = NSURLQueryItem(name: "commit", value: "true")

    private var currentBatch: Batch?
    private var currentPayload: Payload

    private var onCollectionUploaded: (POSTResult, Timestamp?) -> DeferredTimestamp

    init(config: InfoConfiguration, ifUnmodifiedSince: Timestamp? = nil, serializeRecord: (Record<T>) -> String?,
         uploader: BatchUploadFunction, onCollectionUploaded: (POSTResult, Timestamp?) -> DeferredTimestamp) {
        self.config = config
        self.ifUnmodifiedSince = ifUnmodifiedSince
        self.uploader = uploader
        self.serializeRecord = serializeRecord

        self.currentPayload = Payload(config: config)
        self.onCollectionUploaded = onCollectionUploaded
    }

    public func endBatch() -> Success {
        func uploadPayload() -> Success {
            let lines = self.currentPayload.records.map { $0.payload }
            return self.uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: [batchStartParam, commitParam])
                >>== effect(moveForward) >>> succeed
        }

        // Send up as a single upload if we're not batching.
        guard let batch = self.currentBatch else {
            return self.currentPayload.isEmpty ? succeed() : uploadPayload()
        }

        // If we have a batch and both it and the payload are empty, don't need to do anything
        if batch.isEmpty && self.currentPayload.isEmpty {
            return succeed()
        }

        if batch.isFull {
            return commit(batch) >>> uploadPayload
        } else {
            return commit(batch) >>> succeed
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
        // No upload operation happens while queuing records in a payload.
        if self.currentPayload.add(record) {
            return nil
        }

        // Once the payload is full, see if we have a batch we can upload it in. If not, start one.
        guard var batch = self.currentBatch else {
            return start()
        }

        batch.add(self.currentPayload)
        if batch.isFull {
            return commit(batch)
        } else {
            self.currentBatch = batch
            return push(batch)
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

    private func push(batch: Batch) -> DeferredResponse {
        // Push up the current payload to the server and reset
        let lines = self.freezePayload()
        return uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: batch.batchParams)
    }

    private func commit(batch: Batch) -> DeferredResponse {
        let lines = self.freezePayload()
        self.currentBatch = nil
        return uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: batch.commitParams)
            >>== effect(moveForward)
    }

    private func start() -> DeferredResponse {
        let payloadCopy = self.currentPayload
        let lines = self.freezePayload()
        return self.uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: [batchStartParam])
             >>== effect(moveForward)
             >>== { response in
                if let token = response.value.batchToken {
                    var startedBatch = Batch(config: self.config, token: token)
                    startedBatch.add(payloadCopy)
                    self.currentBatch = startedBatch
                }

                return deferMaybe(response)
            }
    }

    private func moveForward(response: StorageResponse<POSTResult>) {
        let lastModified = response.metadata.lastModifiedMilliseconds
        self.ifUnmodifiedSince = lastModified
        self.onCollectionUploaded(response.value, lastModified)
    }

    private func freezePayload() -> [String] {
        let lines = self.currentPayload.records.map { $0.payload }
        self.currentPayload = Payload(config: self.config)
        return lines
    }
}
