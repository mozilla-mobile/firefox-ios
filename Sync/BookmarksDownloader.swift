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
                   >>> effect(self.downloader.advance)
                   >>> self.storage.doneApplyingRecordsAfterDownload
            case .Incomplete:
                log.debug("Running another batch.")
                // This recursion is fine because Deferred always pushes callbacks onto a queue.
                return self.applyRecordsFromBatcher()
                   >>> effect(self.downloader.advance)
                   >>> { self.go(info, greenLight: greenLight) }
            case .Interrupted:
                log.info("Interrupted. Aborting batching this time.")
                return succeed()
            case .NoNewData:
                log.info("No new data. No need to continue batching.")
                self.downloader.advance()
                return succeed()
            }
        }
    }
}
