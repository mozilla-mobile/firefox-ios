/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import Deferred

private let log = Logger.syncLogger

typealias ByteCount = Int

class Uploader {
    /**
     * Upload just about anything that can be turned into something we can upload.
     */
    func sequentialPosts<T>(items: [T], by: Int, lastTimestamp: Timestamp, storageOp: ([T], Timestamp) -> DeferredTimestamp) -> DeferredTimestamp {

        // This needs to be a real Array, not an ArraySlice,
        // for the types to line up.
        let chunks = chunk(items, by: by).map { Array($0) }

        let start = deferMaybe(lastTimestamp)

        let perChunk: ([T], Timestamp) -> DeferredTimestamp = { (records, timestamp) in
            // TODO: detect interruptions -- clients uploading records during our sync --
            // by using ifUnmodifiedSince. We can detect uploaded records since our download
            // (chain the download timestamp into this function), and we can detect uploads
            // that race with our own (chain download timestamps across 'walk' steps).
            // If we do that, we can also advance our last fetch timestamp after each chunk.
            log.debug("Uploading \(records.count) records.")
            return storageOp(records, timestamp)
        }

        return walk(chunks, start: start, f: perChunk)
    }
}

public class IndependentRecordSynchronizer: TimestampedSingleCollectionSynchronizer {
    /**
     * Just like the usual applyIncomingToStorage, but doesn't fast-forward the timestamp.
     */
    func applyIncomingRecords<T>(records: [T], apply: T -> Success) -> Success {
        if records.isEmpty {
            log.debug("No records; done applying.")
            return succeed()
        }

        return walk(records, f: apply)
    }

    func applyIncomingToStorage<T>(records: [T], fetched: Timestamp, apply: T -> Success) -> Success {
        func done() -> Success {
            log.debug("Bumping fetch timestamp to \(fetched).")
            self.lastFetched = fetched
            return succeed()
        }

        if records.isEmpty {
            log.debug("No records; done applying.")
            return done()
        }

        return walk(records, f: apply) >>> done
    }
}

extension TimestampedSingleCollectionSynchronizer {
    /**
     * On each chunk that we upload, we pass along the server modified timestamp to the next,
     * chained through the provided `onUpload` function.
     *
     * The last chunk passes this modified timestamp out, and we assign it to lastFetched.
     *
     * The idea of this is twofold:
     *
     * 1. It does the fast-forwarding that every other Sync client does.
     *
     * 2. It allows us to (eventually) pass the last collection modified time as If-Unmodified-Since
     *    on each upload batch, as we do between the download and the upload phase.
     *    This alone allows us to detect conflicts from racing clients.
     *
     * In order to implement the latter, we'd need to chain the date from getSince in place of the
     * 0 in the call to uploadOutgoingFromStorage in each synchronizer.
     */
    func uploadRecords<T>(records: [Record<T>], by: Int, lastTimestamp: Timestamp, storageClient: Sync15CollectionClient<T>, onUpload: POSTResult -> DeferredTimestamp) -> DeferredTimestamp {
        if records.isEmpty {
            log.debug("No modified records to upload.")
            return deferMaybe(lastTimestamp)
        }

        let storageOp: ([Record<T>], Timestamp) -> DeferredTimestamp = { records, timestamp in
            // TODO: use I-U-S.

            // Each time we do the storage operation, we might receive a backoff notification.
            // For a success response, this will be on the subsequent request, which means we don't
            // have to worry about handling successes and failures mixed with backoffs here.
            return storageClient.post(records, ifUnmodifiedSince: nil)
                >>== { onUpload($0.value) }
        }

        log.debug("Uploading \(records.count) modified records.")

        // Chain the last upload timestamp right into our lastFetched timestamp.
        // This is what Sync clients tend to do, but we can probably do better.
        // Upload 50 records at a time.
        return Uploader().sequentialPosts(records, by: by, lastTimestamp: lastTimestamp, storageOp: storageOp)
            >>== effect(self.setTimestamp)
    }

    func uploadRecordsInChunks<T>(records: [Record<T>], lastTimestamp: Timestamp, storageClient: Sync15CollectionClient<T>, onUpload: POSTResult -> DeferredTimestamp) -> DeferredTimestamp {
        if records.isEmpty {
            log.debug("No modified records to upload.")
            return deferMaybe(lastTimestamp)
        }

        // Schwartzian transform.
        func decorate(record: Record<T>) -> (String, ByteCount)? {
            guard let s = storageClient.serializeRecord(record) else {
                // TODO: fail.
                return nil
            }

            return (s, s.utf8.count)
        }

        // Put small records first.
        let sorted = records.flatMap(decorate).sort { $0.1 < $1.1 }

        // Cut this up into chunks of a maximum size.
        var batches: [[String]] = []
        var batch: [String] = []
        var bytes = 0
        sorted.forEach { line in
            let expectedBytes = bytes + line.1 + 1   // Include newlines.
            if expectedBytes > Sync15StorageClient.maxPayloadSizeBytes {
                if batch.isEmpty {
                    // Uh oh. We're screwed.
                    assertionFailure("Max record size hit before accruing any items.")
                } else {
                    batches.append(batch)
                    batch = []
                    bytes = 0
                }
            }
            batch.append(line.0)
            bytes += line.1 + 1
        }

        // Catch the last one.
        if !batch.isEmpty {
            batches.append(batch)
        }

        log.debug("Uploading \(records.count) modified records in \(batches.count) batches.")

        let perChunk: ([String], Timestamp) -> DeferredTimestamp = { (lines, timestamp) in
            log.debug("Uploading \(lines.count) records.")
            // TODO: use I-U-S.

            // Each time we do the storage operation, we might receive a backoff notification.
            // For a success response, this will be on the subsequent request, which means we don't
            // have to worry about handling successes and failures mixed with backoffs here.
            return storageClient.post(lines, ifUnmodifiedSince: nil)
                >>== { onUpload($0.value) }
        }

        let start = deferMaybe(lastTimestamp)
        return walk(batches, start: start, f: perChunk)
            // Chain the last upload timestamp right into our lastFetched timestamp.
            // This is what Sync clients tend to do, but we can probably do better.
            >>== effect(self.setTimestamp)
    }
}