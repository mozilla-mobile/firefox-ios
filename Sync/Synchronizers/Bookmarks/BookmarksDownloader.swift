/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

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

public class BookmarksMirrorer {
    private let downloader: BatchingDownloader<BookmarkBasePayload>
    private let storage: BookmarkBufferStorage
    private let batchSize: Int
    private let statsSession: SyncEngineStatsSession

    public init(storage: BookmarkBufferStorage, client: Sync15CollectionClient<BookmarkBasePayload>, basePrefs: Prefs, collection: String, statsSession: SyncEngineStatsSession, batchSize: Int=100) {
        self.storage = storage
        self.downloader = BatchingDownloader(collectionClient: client, basePrefs: basePrefs, collection: collection)
        self.batchSize = batchSize
        self.statsSession = statsSession
    }

    // TODO
    public func storageFormatDidChange() {
    }

    // TODO
    public func onWipeWasAppliedToStorage() {
    }

    private func applyRecordsFromBatcher() -> Success {
        let retrieved = self.downloader.retrieve()
        let invalid = retrieved.filter { !$0.payload.isValid() }

        if !invalid.isEmpty {
            // There's nothing we can do with invalid input. There's also no point in
            // tracking failing GUIDs here yet: if another client reuploads those records
            // correctly, we'll encounter them routinely due to a newer timestamp.
            // The only improvement we could make is to drop records from the buffer if we
            // happen to see a new, invalid one before somehow syncing again, but that's
            // unlikely enough that it's not worth doing.
            //
            // Bug 1258801 tracks recording telemetry for these invalid items, which is
            // why we don't simply drop them on the ground at the download stage.
            //
            // We might also choose to perform certain simple recovery actions here: for example,
            // bookmarks with null URIs are clearly invalid, and could be treated as if they
            // weren't present on the server, or transparently deleted.
            log.warning("Invalid records: \(invalid.map { $0.id }.joined(separator: ", ")).")
        }

        let mirrorItems = retrieved.flatMap { record -> BookmarkMirrorItem? in
            guard record.payload.isValid() else {
                return nil
            }

            return (record.payload as MirrorItemable).toMirrorItem(record.modified)
        }

        if mirrorItems.isEmpty {
            log.debug("Got empty batch.")
            return succeed()
        }

        log.debug("Applying \(mirrorItems.count) downloaded bookmarks.")
        return self.storage.applyRecords(mirrorItems)
    }

    public func go(info: InfoCollections, greenLight: @escaping () -> Bool) -> SyncResult {
        if !greenLight() {
            log.info("Green light turned red. Stopping mirror operation.")
            return deferMaybe(SyncStatus.notStarted(.redLight))
        }

        log.debug("Downloading up to \(self.batchSize) records.")
        return self.downloader.go(info, limit: self.batchSize)
                              .bind { result in
            guard let end = result.successValue else {
                log.warning("Got failure: \(result.failureValue!)")
                return deferMaybe(result.failureValue!)
            }
            switch end {
            case .complete:
                log.info("Done with batched mirroring.")
                return self.applyRecordsFromBatcher()
                   >>> effect(self.downloader.advance)
                   >>> self.storage.doneApplyingRecordsAfterDownload
                   >>> always(SyncStatus.completed(self.statsSession.end()))
            case .incomplete:
                log.debug("Running another batch.")
                // This recursion is fine because Deferred always pushes callbacks onto a queue.
                return self.applyRecordsFromBatcher()
                   >>> effect(self.downloader.advance)
                   >>> { self.go(info: info, greenLight: greenLight) }
            case .interrupted:
                log.info("Interrupted. Aborting batching this time.")
                return deferMaybe(SyncStatus.partial(self.statsSession))
            case .noNewData:
                log.info("No new data. No need to continue batching.")
                self.downloader.advance()
                return deferMaybe(SyncStatus.completed(self.statsSession.end()))
            }
        }
    }

    func advanceNextDownloadTimestampTo(timestamp: Timestamp) {
        self.downloader.advanceTimestampTo(timestamp)
    }
}
