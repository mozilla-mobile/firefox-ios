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

/**
 *  A payload represents a block of records sent in a single POST to the server within a batch.
 *  The payload tries to contains as many records it can fit while respecting the limits imposed
 *  by the info/configuration endpoint.
 */
private struct Payload {
    let config: InfoConfiguration
    private(set) var records: [UploadRecord] = []
    private var bytes: ByteCount = 0
    private var count: Int = 0

    init(config: InfoConfiguration) {
        self.config = config
    }

    /** Returns true if the record was added to this payload; false otherwise. */
    mutating func add(record: UploadRecord) -> Bool {
        if (record.size + bytes + 1) > config.maxPostBytes {
            return false
        }

        if count >= config.maxPostRecords {
            return false
        }

        records.append(record)
        count += 1
        bytes += record.size + 1     // For newline.
        return true
    }
}

/**
 * Used to keep track of number of bytes and records sent as part of a batch
 */
private struct BatchMeta {
    let config: InfoConfiguration
    private var bytes: ByteCount = 0
    private var count: Int = 0

    init(config: InfoConfiguration) {
        self.config = config
    }

    mutating func add(payload: Payload) -> Bool {
        guard payloadFitsInBatch(payload) else {
            return false
        }

        count += payload.count
        bytes += payload.bytes
        return true
    }

    private func payloadFitsInBatch(payload: Payload) -> Bool {
        return (bytes + payload.bytes <= config.maxTotalBytes) && (count + payload.count < config.maxTotalRecords)
    }
}

typealias BatchUploadFunction = (lines: [String], ifUnmodifiedSince: Timestamp?, queryParams: [NSURLQueryItem]?) -> Deferred<Maybe<StorageResponse<POSTResult>>>

public class Sync15BatchClient<T: CleartextPayloadJSON> {
    private let config: InfoConfiguration
    private let uploader: BatchUploadFunction
    private let serializeRecord: (Record<T>) -> String?
    private var ifUnmodifiedSince: Timestamp?

    private var batchMeta: BatchMeta
    private var batchToken: BatchToken?
    private var currentPayload: Payload
    private var onCollectionUploaded: (POSTResult -> Void)?

    // TODO: use I-U-S.
    // Each time we do the storage operation, we might receive a backoff notification.
    // For a success response, this will be on the subsequent request, which means we don't
    // have to worry about handling successes and failures mixed with backoffs here.

    init(config: InfoConfiguration, ifUnmodifiedSince: Timestamp? = nil, serializeRecord: (Record<T>) -> String?, uploader: BatchUploadFunction, onCollectionUploaded: (POSTResult -> Void)?) {
        self.config = config
        self.ifUnmodifiedSince = ifUnmodifiedSince
        self.uploader = uploader
        self.serializeRecord = serializeRecord

        self.batchMeta = BatchMeta(config: config)
        self.currentPayload = Payload(config: config)
        self.onCollectionUploaded = onCollectionUploaded
    }

    public func addRecord(record: Record<T>) -> Success {
        // Sanity checks and assumptions
        precondition(config.maxPostBytes <= config.maxTotalBytes)
        precondition(config.maxPostRecords <= config.maxTotalRecords)

        guard let line = self.serializeRecord(record) else {
            return deferMaybe(SerializeRecordFailure(record: record))
        }

        let lineSize = line.utf8.count
        guard lineSize < Sync15StorageClient.maxRecordSizeBytes else {
            return deferMaybe(RecordTooLargeError(size: lineSize, guid: record.id))
        }

        let uploadRecord: UploadRecord = (record.id, line, lineSize)

        // If we can add a record to the payload, all is good - we don't need to push to the server yet.
        // Otherwise, try to push the payload (since it's full) to the server in a batch
        if self.currentPayload.add(uploadRecord) {
            return succeed()
        }

        // If we have a batch token, go ahead and push up the payload using the token.
        // Otherwise, attempt to start a new batch. If we fail starting - no problem! The records would
        // have already been sent in a single POST call.
        guard let token = batchToken else {
            return self.start(self.currentPayload)
                >>== effect({ self.batchToken = $0 })

                // Based on the precondition, we must be able to add at least one payload into the batch 
                // without it failing
                >>> effect({ self.batchMeta.add(self.currentPayload) })
                >>> effect({ self.currentPayload = Payload(config: self.config) })
                >>> succeed
        }

        // If we can fit in another payload, push it up using our batch token
        if batchMeta.add(self.currentPayload) {
            return self.uploadPayload(self.currentPayload, queryParams: [NSURLQueryItem(name: "batch", value: token)])
                >>> effect({ self.currentPayload = Payload(config: self.config) })
                >>> succeed
        }

        // Otherwise, 
        // 1. Commit the batch
        // 2. Start up a new batch
        // 3. Place the payload into the new batch
        return self.commit(token) >>> {
            return self.start(self.currentPayload)
                >>== effect({ self.batchToken = $0 })
                >>> effect({ self.batchMeta = BatchMeta(config: self.config) })
                >>> effect({ self.batchMeta.add(self.currentPayload) })
                >>> succeed
        }
    }

    public func endBatch() -> Success {
        // When not batching, just upload whatever is left over
        guard let token = batchToken else {
            return uploadPayload(self.currentPayload)
                >>== effect({ self.ifUnmodifiedSince = $0.value.modified })
                >>== effect({ self.onCollectionUploaded?($0.value) })
                >>> succeed
        }

        return self.commit(token)
    }

    private func start(payload: Payload) -> Deferred<Maybe<BatchToken?>> {
        let batchStartParam = NSURLQueryItem(name: "batch", value: "true")
        let lines = payload.records.map { $0.payload }
        return self.uploadPayload(payload, queryParams: [batchStartParam]) >>== { storageResponse in
            self.ifUnmodifiedSince = storageResponse.value.modified

            if let batchToken = storageResponse.value.batchToken {
                log.debug("Uploaded \(lines.count) records and received batch token \(batchToken)")
                return deferMaybe(batchToken)
            }

            // Since we were unable to start a batch, the records that were sent will be committed directly to
            // the collection so we should update our timestamp and invoke our upload callback.
            log.debug("Uploaded \(lines.count) records but received no batch token - records will be committed to collection right away")
            self.ifUnmodifiedSince = storageResponse.value.modified
            self.onCollectionUploaded?(storageResponse.value)
            return deferMaybe(nil)
        }
    }

    private func commit(token: BatchToken) -> Success {
        let batchParam = NSURLQueryItem(name: "batch", value: token)
        let commitParam = NSURLQueryItem(name: "commit", value: "true")

        // We could send a payload when committing the batch but that would involve us slicing up the in-progress 
        // payload to make it fit just right. Easier to just push it up in a new batch.
        return self.uploadPayload(Payload(config: self.config), queryParams: [batchParam, commitParam])
            >>== effect({ self.ifUnmodifiedSince = $0.value.modified })
            >>== effect({ self.onCollectionUploaded?($0.value) })
            >>> succeed
    }

    private func uploadPayload(payload: Payload, queryParams: [NSURLQueryItem]? = nil) -> Deferred<Maybe<StorageResponse<POSTResult>>> {
        let lines = payload.records.map { $0.payload }
        return self.uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: nil)
    }
}
