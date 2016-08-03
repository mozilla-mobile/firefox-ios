/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Alamofire
import Shared
import XCGLogger
import Deferred

public class BatchingNotSupported: MaybeErrorType {
    public let response: POSTResult

    public var description: String {
        return "Sync server does not support batching."
    }

    public init(response: POSTResult) {
        self.response = response
    }
}

private let log = Logger.syncLogger

typealias BatchUploadFunction = (lines: [String], ifUnmodifiedSince: Timestamp?, queryParams: [NSURLQueryItem]?) -> Deferred<Maybe<StorageResponse<POSTResult>>>

public class Sync15BatchClient<T: CleartextPayloadJSON> {
    private let config: InfoConfiguration

    private var records: [Record<T>] = []
    private let ifUnmodifiedSince: Timestamp?
    private let uploader: BatchUploadFunction
    private let serializeRecord: (Record<T>) -> String?

    // TODO: use I-U-S.
    // Each time we do the storage operation, we might receive a backoff notification.
    // For a success response, this will be on the subsequent request, which means we don't
    // have to worry about handling successes and failures mixed with backoffs here.

    init(config: InfoConfiguration, ifUnmodifiedSince: Timestamp? = nil, serializeRecord: (Record<T>) -> String?, uploader: BatchUploadFunction) {
        self.config = config
        self.ifUnmodifiedSince = ifUnmodifiedSince
        self.uploader = uploader
        self.serializeRecord = serializeRecord
    }

    public func addRecords(records: [Record<T>]) {
        log.debug("Adding \(records.count) records into batch")
        self.records += records
    }

    public func commit(onCollectionUploaded: (POSTResult -> Void)) -> Success {

        if records.isEmpty {
            return succeed()
        }

        // Need to deduce how big the data is we're sending across using this reducer
        let sizeReducer: (total: ByteCount, record: Record<T>) -> ByteCount = { total, record in
            return total + (self.serializeRecord(record) ?? "").utf8.count
        }

        let sizeOfRecords = records.reduce(0, combine: sizeReducer)

        // Batch up all of the records and fail early if there is an issue
        let batchingResult = batchesFromRecords(records)
        guard let batches = batchingResult.successValue else {
            let failure = batchingResult.failureValue!
            log.debug("Unable to generate batches from records submitted to batch client: \(failure)")
            return deferMaybe(failure)
        }

        // We have too many records for a single post so we'll either need to upload in a single batch or
        // multiple batches
        if records.count > config.maxTotalRecords || sizeOfRecords > config.maxTotalBytes {
            return self.bunchUpload(batches, ifUnmodifiedSince: self.ifUnmodifiedSince, onCollectionUploaded: onCollectionUploaded)
        }

        if records.count > config.maxPostRecords || sizeOfRecords > config.maxPostBytes {
            return self.batchUpload(batches, ifUnmodifiedSince: self.ifUnmodifiedSince, onCollectionUploaded: onCollectionUploaded)
        }

        // We can just do a single post instead of batching
        log.debug("Batch fits within a single request. Submitting records in a single post.")
        let lines = optFilter(records.map(self.serializeRecord))
        return self.uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: nil)
            >>== effect({ onCollectionUploaded($0.value) })
            >>> succeed
    }

    public func bunchUpload(batch: [[String]], ifUnmodifiedSince: Timestamp?, onCollectionUploaded: (POSTResult -> Void)) -> Success {

        // Need to break apart the provided batch into multiple batches (AKA a bunch) so we can fit them in batch calls
        var mutBatch = batch

        /* 
         * When talking about a 'batch' and multiple 'batches' the word becomes very confusing. In this context,
         *
         * A 'batch' consists of N requests to the server beginning with a batch=true call and ends with a commit=true call.
         * A 'bunch' is many of these calls.
         * A partialBatch is one of the N requests made within a 'batch'.
         *
         * Here are some typealiases to make your life easier.
         */

        typealias Batch = [[String]]
        typealias Bunch = [Batch]

        var bunch = Bunch()

        while !mutBatch.isEmpty {
            var recordCount = 0
            var size = 0
            var smallerBatch = Batch()

            while size <= config.maxTotalBytes && recordCount <= config.maxTotalRecords && !mutBatch.isEmpty {
                let partialBatch = mutBatch.removeFirst()
                recordCount += partialBatch.count
                size += partialBatch.reduce(0) { $0 + ($1.utf8.count + 1) }
                smallerBatch.append(partialBatch)
            }

            bunch.append(smallerBatch)
        }

        let perBatch: (batch: [[String]]) -> Success = { batch in
            return self.batchUpload(batch, ifUnmodifiedSince: ifUnmodifiedSince, onCollectionUploaded: onCollectionUploaded)
        }

        return walk(bunch, f: perBatch)
    }

    public func batchUpload(batch: [[String]], ifUnmodifiedSince: Timestamp?, onCollectionUploaded: (POSTResult -> Void)) -> Success {

        let batchSize: ByteCount = batch.reduce(0) { sum, batch in
            return sum + batch.reduce(0) { $0 + $1.utf8.count }
        }

        let recordCount: Int = batch.reduce(0) { $0 + $1.count }

        // Same checks made in commit call but included here for strength
        precondition(recordCount < config.maxTotalRecords)
        precondition(batchSize < config.maxTotalBytes)

        var batch = batch
        let firstBatch = batch.removeFirst()
        let lastBatch = batch.last ?? []

        return startBatch(firstBatch).bind { result in
            guard let token = result.successValue else {
                // Check if we didn't get a token back/batching isn't supported and push up records using regular single posts
                if let error = result.failureValue as? BatchingNotSupported {

                    // Since we uploaded the first set already as part of the start call and we don't support
                    // batching, make sure to invoke the upload callback to let the others know we committed
                    // new records to the collection server-side
                    onCollectionUploaded(error.response)

                    // Walk through the batches, posting along the way and invoking onUpload
                    let perChunk: (lines: [String]) -> Success = { lines in
                        return self.uploader(lines: lines, ifUnmodifiedSince: ifUnmodifiedSince, queryParams: nil)
                            >>== effect({ onCollectionUploaded($0.value) })
                            >>> succeed
                    }
                    return walk(batch, f: perChunk)
                } else {
                    // Bubble up other errors
                    return deferMaybe(result.failureValue!)
                }
            }

            // Remove the last batch - we handle the last call in a special case.
            batch.removeLast()

            // When batching, each upload in the batch is uploaded to a temporary collection until we specif
            // commit=true. At this point, the temporary collection is pushed to the real collection on the server.
            // It is at this point we want to say the collection has been uploaded.
            return self.uploadBatches(token, batches: batch) >>> {
                return self.finishBatch(token, lines: lastBatch)
                    >>== effect({ onCollectionUploaded($0.value) })
                    >>> succeed
            }
        }
    }

    private func startBatch(lines: [String]) -> Deferred<Maybe<BatchToken>> {
        let batchStartParam = NSURLQueryItem(name: "batch", value: "true")

        // Attempt to upload some records and see if we get back a token we can use for batches.
        return self.uploader(lines: lines, ifUnmodifiedSince: ifUnmodifiedSince, queryParams: [batchStartParam]) >>== { storageResponse in
            if let batchToken = storageResponse.value.batchToken {
                log.debug("Uploaded \(lines.count) records and received batch token \(batchToken)")
                return deferMaybe(batchToken)
            } else {
                log.debug("Uploaded \(lines.count) records but received no batch token")
                return deferMaybe(BatchingNotSupported(response: storageResponse.value))
            }
        }
    }

    private func uploadBatches(token: BatchToken, batches: [[String]]) -> Success {
        let batchParam = NSURLQueryItem(name: "batch", value: token)
        let uploadBatch: (lines: [String]) -> Success = { lines in
            return self.uploader(lines: lines, ifUnmodifiedSince: self.ifUnmodifiedSince, queryParams: [batchParam])
                >>> effect({ log.debug(("Uploaded \(lines.count) records for batch \(token)")) })
        }

        return walk(batches, f: uploadBatch)
    }

    private func finishBatch(token: BatchToken, lines: [String]) -> Deferred<Maybe<StorageResponse<POSTResult>>> {
        let batchParam = NSURLQueryItem(name: "batch", value: token)
        let commitParam = NSURLQueryItem(name: "commit", value: "true")
        return self.uploader(lines: lines, ifUnmodifiedSince: ifUnmodifiedSince, queryParams: [batchParam, commitParam])
    }

    func batchesFromRecords(records: [Record<T>]) -> Maybe<[[String]]> {

        // Place the record ID alongside the line text for error reporting later on
        let idWithLine: (record: Record<T>) -> (GUID, String)? = { record in
            guard let line = self.serializeRecord(record) else {
                return nil
            }
            return (record.id, line)
        }

        let pairs : [(GUID, String)] = records.flatMap(idWithLine)

        var batches = [[String]]()
        var batch = [String]()
        var size = 0

        for (id, line) in pairs {
            let lineSize = line.utf8.count

            if lineSize > Sync15StorageClient.maxRecordSizeBytes {
                return Maybe(failure: RecordTooLargeError(size: lineSize, guid: id))
            }

            // If adding the line keeps the batch size and number of records below the limits, proceed.
            // Otherwise, add the filled batch to our batches and start a new one.

            // Add 1 to account for the newline
            guard (size + lineSize + 1) <= config.maxPostBytes && (batch.count + 1) <= config.maxPostRecords else {
                // Start the next batch
                batches.append(batch)
                size = lineSize
                batch = [line]
                continue
            }

            size += (lineSize + 1)
            batch.append(line)
        }

        // Don't forget to add the last batch!
        if !batch.isEmpty {
            batches.append(batch)
        }

        return Maybe(success: batches)
    }
}