/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger
private let BookmarksStorageVersion = 2

/**
 * This is like a synchronizer, but it downloads records bit by bit, eventually
 * notifying that the local storage is up to date with the server contents.
 *
 * Because batches might be separated over time, it's possible for the server
 * state to change between calls. These state changes might include:
 *
 * 1. New changes arriving. This is fairly routine, but it's worth noting that
 *    changes might affect existing records that have been batched!
 * 2. Wipes. The collection (or the server as a whole) might be deleted. This
 *    should be accompanied by a change in syncID in meta/global; it's the caller's
 *    responsibility to detect this.
 * 3. A storage format change. This should be unfathomably rare, but if it happens
 *    we must also be prepared to discard our existing batched data.
 * 4. TTL expiry. We need to do better about TTL handling in general, but here
 *    we might find that a downloaded record is no longer live by the time we
 *    come to apply it! This doesn't apply to bookmark records, so we will ignore
 *    it for the moment.
 *
 * Batch downloading without continuation tokens is achieved as follows:
 *
 * * A minimum timestamp is established. This starts as zero.
 * * A fetch is issued against the server for records changed since that timestamp,
 *   ordered by modified time ascending, and limited to the batch size.
 * * If the batch is complete, we flush it to storage and advance the minimum
 *   timestamp to just before the newest record in the batch. This ensures that
 *   a divided set of records with the same modified times will be downloaded
 *   entirely so long as the set is never larger than the batch size.
 * * Iterate until we determine that there are no new records to fetch.
 *
 * Batch downloading with continuation tokens is much easier:
 *
 * * A minimum timestamp is established.
 * * Make a request with limit=N.
 * * Look for an X-Weave-Next-Offset header. Supply that in the next request.
 *   Also supply X-If-Unmodified-Since to avoid missed modifications.
 *
 * We do the latter, because we only support Sync 1.5. The use of the offset
 * allows us to efficiently process batches, particularly those that contain
 * large sets of records with the same timestamp. We still maintain the last
 * modified timestamp to allow for resuming a batch in the case of a conflicting
 * write, detected via X-I-U-S.
 */
class BatchingDownloader<T: CleartextPayloadJSON> {
    let client: Sync15CollectionClient<T>
    let collection: String
    let prefs: Prefs

    var batch: [Record<T>] = []

    func store(records: [Record<T>]) {
        self.batch += records
    }

    func retrieve() -> [Record<T>] {
        let ret = self.batch
        self.batch = []
        return ret
    }

    init(collectionClient: Sync15CollectionClient<T>, basePrefs: Prefs, collection: String) {
        self.client = collectionClient
        self.collection = collection
        let branchName = "downloader." + collection + "."
        self.prefs = basePrefs.branch(branchName)

        log.info("Downloader configured with prefs '\(branchName)'.")
    }

    var nextOffset: String? {
        get {
            return self.prefs.stringForKey("nextOffset")
        }
        set (value) {
            if let value = value {
                self.prefs.setString(value, forKey: "nextOffset")
            } else {
                self.prefs.removeObjectForKey("nextOffset")
            }
        }
    }

    var baseTimestamp: Timestamp {
        get {
            return self.prefs.timestampForKey("baseTimestamp") ?? 0
        }
        set (value) {
            self.prefs.setTimestamp(value ?? 0, forKey: "baseTimestamp")
        }
    }

    var lastModified: Timestamp {
        get {
            return self.prefs.timestampForKey("lastModified") ?? 0
        }
        set (value) {
            self.prefs.setTimestamp(value ?? 0, forKey: "lastModified")
        }
    }

    /**
     * Call this when a significant structural server change has been detected.
     */
    func reset() -> Success {
        self.baseTimestamp = 0
        self.lastModified = 0
        self.nextOffset = nil
        self.batch = []
        return succeed()
    }

    func go(info: InfoCollections, limit: Int) -> Deferred<Maybe<DownloadEndState>> {
        guard let modified = info.modified(self.collection) else {
            log.debug("No server modified time for collection \(self.collection).")
            return deferMaybe(.NoNewData)
        }

        log.debug("Modified: \(modified); last \(self.lastModified).")
        if modified == self.lastModified {
            log.debug("No more data to batch-download.")
            return deferMaybe(.NoNewData)
        }

        return self.downloadNextBatchWithLimit(limit, advancingOnCompletionTo: modified)
    }

    func downloadNextBatchWithLimit(limit: Int, advancingOnCompletionTo: Timestamp) -> Deferred<Maybe<DownloadEndState>> {
        func handleFailure(err: MaybeErrorType) -> Deferred<Maybe<DownloadEndState>> {
            guard let badRequest = err as? BadRequestError<[Record<T>]> where badRequest.response.metadata.status == 412 else {
                // Just pass through the failure.
                return deferMaybe(err)
            }

            // Conflict. Start again.
            log.warning("Server contents changed during offset-based batching. Stepping back.")
            self.nextOffset = nil
            return deferMaybe(.Interrupted)
        }

        func handleSuccess(response: StorageResponse<[Record<T>]>) -> Deferred<Maybe<DownloadEndState>> {
            // Shift to the next offset. This might be nil, in which case… fine!
            let offset = response.metadata.nextOffset
            self.nextOffset = offset

            // If there are records, advance to just before the timestamp of the last.
            // If our next fetch with X-Weave-Next-Offset fails, at least we'll start here.
            if let newBase = response.value.last?.modified {
                self.baseTimestamp = newBase - 1
            }

            log.debug("Got success response with \(response.metadata.records) records.")
            // Store the incoming records for collection.
            self.store(response.value)

            if offset == nil {
                self.lastModified = advancingOnCompletionTo
                return deferMaybe(.Complete)
            }

            return deferMaybe(.Incomplete)
        }

        let fetch = self.client.getSince(self.baseTimestamp, sort: SortOption.Newest, limit: limit, offset: self.nextOffset)
        return fetch.bind { result in
            guard let response = result.successValue else {
                return handleFailure(result.failureValue!)
            }
            return handleSuccess(response)
        }
    }
}

public enum DownloadEndState: String {
    case Complete                         // We're done. Records are waiting for you.
    case Incomplete                       // applyBatch was called, and we think there are more records.
    case NoNewData                        // There were no records.
    case Interrupted                      // We got a 412 conflict when fetching the next batch.
}