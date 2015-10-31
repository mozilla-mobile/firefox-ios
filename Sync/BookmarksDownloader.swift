/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger
let BookmarksStorageVersion = 2

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

private func itemFromRecord(record: Record<BookmarkBasePayload>) -> BookmarkMirrorItem? {
    guard let itemable = record as? MirrorItemable else {
        return nil
    }
    return itemable.toMirrorItem(record.modified)
}

public class MirroringBookmarksSynchronizer: TimestampedSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "bookmarks")
    }

    override var storageVersion: Int {
        return BookmarksStorageVersion
    }

    public func mirrorBookmarksToStorage(storage: BookmarkMirrorStorage, withServer storageClient: Sync15StorageClient, info: InfoCollections, greenLight: () -> Bool) -> SyncResult {
        if let reason = self.reasonToNotSync(storageClient) {
            return deferMaybe(.NotStarted(reason))
        }

        let encoder = RecordEncoder<BookmarkBasePayload>(decode: BookmarkType.somePayloadFromJSON, encode: { $0 })

        guard let bookmarksClient = self.collectionClient(encoder, storageClient: storageClient) else {
            log.error("Couldn't make bookmarks factory.")
            return deferMaybe(FatalError(message: "Couldn't make bookmarks factory."))
        }

        let mirrorer = BookmarksMirrorer(storage: storage, client: bookmarksClient, basePrefs: self.prefs, collection: "bookmarks")
        return mirrorer.go(info, greenLight: greenLight) >>> always(SyncStatus.Completed)
    }
}

public class BookmarksMirrorer {
    private let downloader: BatchingDownloader<BookmarkBasePayload>
    private let storage: BookmarkMirrorStorage
    private let batchSize: Int

    public init(storage: BookmarkMirrorStorage, client: Sync15CollectionClient<BookmarkBasePayload>, basePrefs: Prefs, collection: String, batchSize: Int=100) {
        self.storage = storage
        self.downloader = BatchingDownloader(collectionClient: client, basePrefs: basePrefs, collection: collection)
        self.batchSize = batchSize
    }

    // TODO
    public func storageFormatDidChange() {
    }

    // TODO
    public func onWipeWasAppliedToStorage() {
    }

    private func applyRecordsFromBatcher() -> Success {
        let retrieved = self.downloader.retrieve()
        let records = retrieved.flatMap { ($0.payload as? MirrorItemable)?.toMirrorItem($0.modified) }
        if records.isEmpty {
            log.debug("Got empty batch.")
            return succeed()
        }

        log.debug("Applying \(records.count) downloaded bookmarks.")
        return self.storage.applyRecords(records)
    }

    public func go(info: InfoCollections, greenLight: () -> Bool) -> Success {
        if !greenLight() {
            log.info("Green light turned red. Stopping mirror operation.")
            return succeed()
        }

        log.debug("Downloading up to \(self.batchSize) records.")
        return self.downloader.go(info, limit: self.batchSize)
                              .bind { result in
            guard let end = result.successValue else {
                log.warning("Got failure: \(result.failureValue!)")
                return succeed()
            }
            switch end {
            case .Complete:
                log.info("Done with batched mirroring.")
                return self.applyRecordsFromBatcher()
                   >>> self.storage.doneApplyingRecordsAfterDownload
            case .Incomplete:
                log.debug("Running another batch.")
                // This recursion is fine because Deferred always pushes callbacks onto a queue.
                return self.applyRecordsFromBatcher() >>> { self.go(info, greenLight: greenLight) }
            case .Interrupted:
                log.info("Interrupted. Aborting batching this time.")
                return succeed()
            case .NoNewData:
                log.info("No new data. No need to continue batching.")
                return succeed()
            }
        }
    }
}

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

    /**
     * Clients should provide the same set of parameters alongside an `offset` as was
     * provided with the initial request. The only thing that varies in our batch fetches
     * is `newer`, so we track the original value alongside.
     */
    var nextFetchParameters: (String, Timestamp)? {
        get {
            let o = self.prefs.stringForKey("nextOffset")
            let n = self.prefs.timestampForKey("offsetNewer")
            guard let offset = o, let newer = n else {
                return nil
            }
            return (offset, newer)
        }
        set (value) {
            if let (offset, newer) = value {
                self.prefs.setString(offset, forKey: "nextOffset")
                self.prefs.setTimestamp(newer, forKey: "offsetNewer")
            } else {
                self.prefs.removeObjectForKey("nextOffset")
                self.prefs.removeObjectForKey("offsetNewer")
            }
        }
    }

    // Set after each batch, from record timestamps.
    var baseTimestamp: Timestamp {
        get {
            return self.prefs.timestampForKey("baseTimestamp") ?? 0
        }
        set (value) {
            self.prefs.setTimestamp(value ?? 0, forKey: "baseTimestamp")
        }
    }

    // Only set at the end of a batch, from headers.
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
        self.nextFetchParameters = nil
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

        return self.downloadNextBatchWithLimit(limit, infoModified: modified)
    }

    // We're either fetching from our current base timestamp with no offset,
    // or the timestamp we were using when we last saved an offset.
    func fetchParameters() -> (String?, Timestamp) {
        if let (offset, since) = self.nextFetchParameters {
            return (offset, since)
        }
        return (nil, max(self.lastModified, self.baseTimestamp))
    }

    func downloadNextBatchWithLimit(limit: Int, infoModified: Timestamp) -> Deferred<Maybe<DownloadEndState>> {
        let (offset, since) = self.fetchParameters()
        log.debug("Fetching newer=\(since), offset=\(offset).")

        let fetch = self.client.getSince(since, sort: SortOption.OldestFirst, limit: limit, offset: offset)

        func handleFailure(err: MaybeErrorType) -> Deferred<Maybe<DownloadEndState>> {
            log.debug("Handling failure.")
            guard let badRequest = err as? BadRequestError<[Record<T>]> where badRequest.response.metadata.status == 412 else {
                // Just pass through the failure.
                return deferMaybe(err)
            }

            // Conflict. Start again.
            log.warning("Server contents changed during offset-based batching. Stepping back.")
            self.nextFetchParameters = nil
            return deferMaybe(.Interrupted)
        }

        func handleSuccess(response: StorageResponse<[Record<T>]>) -> Deferred<Maybe<DownloadEndState>> {
            log.debug("Handling success.")
            // Shift to the next offset. This might be nil, in which case… fine!
            // Note that we preserve the previous 'newer' value from the offset or the original fetch,
            // even as we update baseTimestamp.
            let nextOffset = response.metadata.nextOffset
            self.nextFetchParameters = nextOffset == nil ? nil : (nextOffset!, since)

            // If there are records, advance to just before the timestamp of the last.
            // If our next fetch with X-Weave-Next-Offset fails, at least we'll start here.
            //
            // This approach is only valid if we're fetching oldest-first.
            if let newBase = response.value.last?.modified {
                log.debug("Advancing baseTimestamp to \(newBase) - 1")
                self.baseTimestamp = newBase - 1
            }

            log.debug("Got success response with \(response.metadata.records) records.")
            // Store the incoming records for collection.
            self.store(response.value)

            if nextOffset == nil {
                // If we can't get a timestamp from the header -- and we should always be able to --
                // we fall back on the collection modified time in i/c, as supplied by the caller.
                // In any case where there is no racing writer these two values should be the same.
                // If they differ, the header should be later. If it's missing, and we use the i/c
                // value, we'll simply redownload some records.
                // All bets are off if we hit this case and are filtering somehow… don't do that.
                let lm = response.metadata.lastModifiedMilliseconds
                log.debug("Advancing lastModified to \(lm) ?? \(infoModified).")
                self.lastModified = lm ?? infoModified
                return deferMaybe(.Complete)
            }

            return deferMaybe(.Incomplete)
        }

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
