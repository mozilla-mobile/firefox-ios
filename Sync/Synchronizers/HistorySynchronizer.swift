/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger
private let HistoryTTLInSeconds = 5184000                   // 60 days.
let HistoryStorageVersion = 1

func makeDeletedHistoryRecord(guid: GUID) -> Record<HistoryPayload> {
    // Local modified time is ignored in upload serialization.
    let modified: Timestamp = 0

    // Sortindex for history is frecency. Make deleted items more frecent than almost
    // anything.
    let sortindex = 5_000_000

    let ttl = HistoryTTLInSeconds

    let json: JSON = JSON([
        "id": guid,
        "deleted": true,
        ])
    let payload = HistoryPayload(json)
    return Record<HistoryPayload>(id: guid, payload: payload, modified: modified, sortindex: sortindex, ttl: ttl)
}

func makeHistoryRecord(place: Place, visits: [Visit]) -> Record<HistoryPayload> {
    let id = place.guid
    let modified: Timestamp = 0    // Ignored in upload serialization.
    let sortindex = 1              // TODO: frecency!
    let ttl = HistoryTTLInSeconds
    let json: JSON = JSON([
        "id": id,
        "visits": visits.map { $0.toJSON() },
        "histUri": place.url,
        "title": place.title,
        ])
    let payload = HistoryPayload(json)
    return Record<HistoryPayload>(id: id, payload: payload, modified: modified, sortindex: sortindex, ttl: ttl)
}

public class HistorySynchronizer: IndependentRecordSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "history")
    }

    override var storageVersion: Int {
        return HistoryStorageVersion
    }

    private let batchSize: Int = 500  // A balance between number of requests and per-request size.

    private func mask(maxFailures: Int) -> Maybe<()> -> Success {
        var failures = 0
        return { result in
            if result.isSuccess {
                return Deferred(value: result)
            }

            if ++failures > maxFailures {
                return Deferred(value: result)
            }

            log.debug("Masking failure \(failures).")
            return succeed()
        }
    }

    // TODO: this function should establish a transaction at suitable points.
    // TODO: a much more efficient way to do this is to:
    // 1. Start a transaction.
    // 2. Try to update each place. Note failures.
    // 3. bulkInsert all failed updates in one go.
    // 4. Store all remote visits for all places in one go, constructing a single sequence of visits.
    func applyIncomingToStorage(storage: SyncableHistory, records: [Record<HistoryPayload>]) -> Success {

        // Skip over at most this many failing records before aborting the sync.
        let maskSomeFailures = self.mask(3)

        // TODO: it'd be nice to put this in an extension on SyncableHistory. Waiting for Swift 2.0...
        func applyRecord(rec: Record<HistoryPayload>) -> Success {
            let guid = rec.id
            let payload = rec.payload
            let modified = rec.modified

            // We apply deletions immediately. Yes, this will throw away local visits
            // that haven't yet been synced. That's how Sync works, alas.
            if payload.deleted {
                return storage.deleteByGUID(guid, deletedAt: modified).bind(maskSomeFailures)
            }

            // It's safe to apply other remote records, too -- even if we re-download, we know
            // from our local cached server timestamp on each record that we've already seen it.
            // We have to reconcile on-the-fly: we're about to overwrite the server record, which
            // is our shared parent.
            let place = rec.payload.asPlace()

            if isIgnoredURL(place.url) {
                log.debug("Ignoring incoming record \(guid) because its URL is one we wish to ignore.")
                return succeed()
            }

            let placeThenVisits = storage.insertOrUpdatePlace(place, modified: modified)
                              >>> { storage.storeRemoteVisits(payload.visits, forGUID: guid) }
            return placeThenVisits.map({ result in
                if result.isFailure {
                    let reason = result.failureValue?.description ?? "unknown reason"
                    log.error("Record application failed: \(reason)")
                }
                return result
            }).bind(maskSomeFailures)
        }

        return self.applyIncomingRecords(records, apply: applyRecord)
    }

    private func uploadModifiedPlaces(places: [(Place, [Visit])], lastTimestamp: Timestamp, fromStorage storage: SyncableHistory, withServer storageClient: Sync15CollectionClient<HistoryPayload>) -> DeferredTimestamp {
        return self.uploadRecords(places.map(makeHistoryRecord), by: 50, lastTimestamp: lastTimestamp, storageClient: storageClient) {
            // We don't do anything with failed.
            storage.markAsSynchronized($0.success, modified: $0.modified)
        }
    }

    private func uploadDeletedPlaces(guids: [GUID], lastTimestamp: Timestamp, fromStorage storage: SyncableHistory, withServer storageClient: Sync15CollectionClient<HistoryPayload>) -> DeferredTimestamp {

        let records = guids.map(makeDeletedHistoryRecord)

        // Deletions are smaller, so upload 100 at a time.
        return self.uploadRecords(records, by: 100, lastTimestamp: lastTimestamp, storageClient: storageClient) {
            storage.markAsDeleted($0.success) >>> always($0.modified)
        }
    }

    private func uploadOutgoingFromStorage(storage: SyncableHistory, lastTimestamp: Timestamp, withServer storageClient: Sync15CollectionClient<HistoryPayload>) -> Success {

        var workWasDone = false
        let uploadDeleted: Timestamp -> DeferredTimestamp = { timestamp in
            storage.getDeletedHistoryToUpload()
            >>== { guids in
                if !guids.isEmpty {
                    workWasDone = true
                }
                return self.uploadDeletedPlaces(guids, lastTimestamp: timestamp, fromStorage: storage, withServer: storageClient)
            }
        }

        let uploadModified: Timestamp -> DeferredTimestamp = { timestamp in
            storage.getModifiedHistoryToUpload()
                >>== { places in
                    if !places.isEmpty {
                        workWasDone = true
                    }
                    return self.uploadModifiedPlaces(places, lastTimestamp: timestamp, fromStorage: storage, withServer: storageClient)
            }
        }

        // The last clause will checkpoint the DB. But we just checkpointed the DB after downloading records!
        // Yes, that's true. Either there will be lots of work to do (e.g., having just marked
        // thousands of records as uploaded, or dropping lots of deleted rows), and so it's
        // worthwhile… or there won't be much work to do, and the checkpoint will be cheap.
        // If we did nothing -- uploaded no deletions, uploaded no modified records -- then we
        // don't checkpoint at all.
        return deferMaybe(lastTimestamp)
          >>== uploadDeleted
          >>== uploadModified
           >>> effect({ log.debug("Done syncing. Work was done? \(workWasDone)") })
           >>> { workWasDone ? storage.doneUpdatingMetadataAfterUpload() : succeed() }    // A closure so we eval workWasDone after it's set!
           >>> effect({ log.debug("Done.") })
    }

    private func go(info: InfoCollections, greenLight: () -> Bool, downloader: BatchingDownloader<HistoryPayload>, history: SyncableHistory) -> Success {

        if !greenLight() {
            log.info("Green light turned red. Stopping history download.")
            return succeed()
        }

        func applyBatched() -> Success {
            return self.applyIncomingToStorage(history, records: downloader.retrieve())
               >>> effect(downloader.advance)
        }

        func onBatchResult(result: Maybe<DownloadEndState>) -> Success {
            guard let end = result.successValue else {
                log.warning("Got failure: \(result.failureValue!)")
                return succeed()
            }

            switch end {
            case .Complete:
                log.info("Done with batched mirroring.")
                return applyBatched()
                   >>> history.doneApplyingRecordsAfterDownload
            case .Incomplete:
                log.debug("Running another batch.")
                // This recursion is fine because Deferred always pushes callbacks onto a queue.
                return applyBatched()
                   >>> { self.go(info, greenLight: greenLight, downloader: downloader, history: history) }
            case .Interrupted:
                log.info("Interrupted. Aborting batching this time.")
                return succeed()
            case .NoNewData:
                log.info("No new data. No need to continue batching.")
                downloader.advance()
                return succeed()
            }
        }

        return downloader.go(info, limit: self.batchSize)
                         .bind(onBatchResult)
    }

    public func synchronizeLocalHistory(history: SyncableHistory, withServer storageClient: Sync15StorageClient, info: InfoCollections, greenLight: () -> Bool) -> SyncResult {
        if let reason = self.reasonToNotSync(storageClient) {
            return deferMaybe(.NotStarted(reason))
        }

        let encoder = RecordEncoder<HistoryPayload>(decode: { HistoryPayload($0) }, encode: { $0 })

        guard let historyClient = self.collectionClient(encoder, storageClient: storageClient) else {
            log.error("Couldn't make history factory.")
            return deferMaybe(FatalError(message: "Couldn't make history factory."))
        }

        let downloader = BatchingDownloader(collectionClient: historyClient, basePrefs: self.prefs, collection: "history")

        // The original version of the history synchronizer tracked its
        // own last fetched time. We need to migrate this into the
        // batching downloader.
        let since: Timestamp = self.lastFetched
        if since > downloader.lastModified {
            log.debug("Advancing downloader lastModified to synchronizer lastFetched \(since).")
            downloader.lastModified = since
            self.lastFetched = 0
        }

        return self.go(info, greenLight: greenLight, downloader: downloader, history: history)
           >>> { self.uploadOutgoingFromStorage(history, lastTimestamp: 0, withServer: historyClient) }
           >>> { return deferMaybe(.Completed) }
    }
}
