/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()
private let HistoryTTLInSeconds = 5184000                   // 60 days.
private let HistoryStorageVersion = 1

typealias DeferredTimestamp = Deferred<Result<Timestamp>>

public class HistorySynchronizer: BaseSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "history")
    }

    override var storageVersion: Int {
        return HistoryStorageVersion
    }

    private func applyIncomingToStorage(storage: SyncableHistory, response: StorageResponse<[Record<HistoryPayload>]>) -> Success {
        log.debug("Applying incoming history records from response timestamped \(response.metadata.timestampMilliseconds).")
        log.debug("Records header hint: \(response.metadata.records)")
        return self.applyIncomingToStorage(storage, records: response.value, fetched: response.metadata.lastModifiedMilliseconds!)
    }

    // TODO: this function should establish a transaction at suitable points.
    func applyIncomingToStorage(storage: SyncableHistory, records: [Record<HistoryPayload>], fetched: Timestamp) -> Success {
        func applyRecord(rec: Record<HistoryPayload>) -> Success {
            let guid = rec.id
            let payload = rec.payload
            let modified = rec.modified

            // We apply deletions immediately. Yes, this will throw away local visits
            // that haven't yet been synced. That's how Sync works, alas.
            if payload.deleted {
                return storage.deleteByGUID(guid, deletedAt: modified)
            }

            // It's safe to apply other remote records, too -- even if we re-download, we know
            // from our local cached server timestamp on each record that we've already seen it.
            // We have to reconcile on-the-fly: we're about to overwrite the server record, which
            // is our shared parent.
            let place = rec.payload.asPlace()
            let placeThenVisits = storage.insertOrUpdatePlace(place, modified: modified)
                              >>> { storage.storeRemoteVisits(payload.visits, forGUID: guid) }
            return placeThenVisits.map({ result in
                if result.isFailure {
                    log.error("Record application failed: \(result.failureValue)")
                }
                return result
            })
        }

        func done() -> Success {
            log.debug("Bumping fetch timestamp to \(fetched).")
            self.lastFetched = fetched
            return succeed()
        }

        if records.isEmpty {
            log.debug("No records; done applying.")
            return done()
        }

        // TODO: a much more efficient way to do this is to:
        // 1. Start a transaction.
        // 2. Try to update each place. Note failures.
        // 3. bulkInsert all failed updates in one go.
        // 4. Store all remote visits for all places in one go, constructing a single sequence of visits.
        return walk(records, applyRecord) >>> done
    }

    private class func makeDeletedHistoryRecord(guid: GUID) -> Record<HistoryPayload> {
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

    private class func makeHistoryRecord(place: Place, visits: [Visit]) -> Record<HistoryPayload> {
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

    private func setTimestamp(timestamp: Timestamp) {
        log.debug("Setting post-upload lastFetched to \(timestamp).")
        self.lastFetched = timestamp
    }

    /**
     * Upload just about anything that can be turned into something we can upload.
     */
    private func sequentialPosts<T>(items: [T], by: Int, lastTimestamp: Timestamp, storageOp: ([T], Timestamp) -> DeferredTimestamp) -> DeferredTimestamp {

        // This needs to be a real Array, not an ArraySlice,
        // for the types to line up.
        let chunks = chunk(items, by: by).map { Array($0) }

        let start = deferResult(lastTimestamp)

        let perChunk: ([T], Timestamp) -> DeferredTimestamp = { (records, timestamp) in
            // TODO: detect interruptions -- clients uploading records during our sync --
            // by using ifUnmodifiedSince. We can detect uploaded records since our download
            // (chain the download timestamp into this function), and we can detect uploads
            // that race with our own (chain download timestamps across 'walk' steps).
            // If we do that, we can also advance our last fetch timestamp after each chunk.
            log.debug("Uploading \(records.count) records.")
            return storageOp(records, timestamp)
        }

        return walk(chunks, start, perChunk)
    }

    private func uploadModifiedPlaces(places: [(Place, [Visit])], lastTimestamp: Timestamp, fromStorage storage: SyncableHistory, withServer storageClient: Sync15CollectionClient<HistoryPayload>) -> DeferredTimestamp {
        if places.isEmpty {
            log.debug("No modified places to upload.")
            return deferResult(lastTimestamp)
        }

        let storageOp: ([Record<HistoryPayload>], Timestamp) -> DeferredTimestamp = { records, timestamp in
            // TODO: use I-U-S.
            return storageClient.post(records, ifUnmodifiedSince: nil)
              >>== { storage.markAsSynchronized($0.value.success, modified: $0.value.modified) }
        }

        log.debug("Uploading \(places.count) modified places.")
        let records = places.map(HistorySynchronizer.makeHistoryRecord)

        // Chain the last upload timestamp right into our lastFetched timestamp.
        // This is what Sync clients tend to do, but we can probably do better.
        // Upload 50 records at a time.
        return self.sequentialPosts(records, by: 50, lastTimestamp: lastTimestamp, storageOp: storageOp)
          >>== effect(self.setTimestamp)
    }

    private func uploadDeletedPlaces(guids: [GUID], lastTimestamp: Timestamp, fromStorage storage: SyncableHistory, withServer storageClient: Sync15CollectionClient<HistoryPayload>) -> DeferredTimestamp {
        if guids.isEmpty {
            log.debug("No deleted records to upload.")
            return deferResult(lastTimestamp)
        }

        log.debug("Uploading \(guids.count) deletions.")
        let storageOp: ([Record<HistoryPayload>], Timestamp) -> DeferredTimestamp = { records, timestamp in
            return storageClient.post(records, ifUnmodifiedSince: nil)
              >>== { storage.markAsDeleted($0.value.success) >>> always($0.value.modified) }
        }

        let records = guids.map(HistorySynchronizer.makeDeletedHistoryRecord)

        // Deletions are smaller, so upload 100 at a time.
        return self.sequentialPosts(records, by: 100, lastTimestamp: lastTimestamp, storageOp: storageOp)
          >>== effect(self.setTimestamp)
    }

    private func uploadOutgoingFromStorage(storage: SyncableHistory, lastTimestamp: Timestamp, withServer storageClient: Sync15CollectionClient<HistoryPayload>) -> Success {

        let uploadDeleted: Timestamp -> DeferredTimestamp = { timestamp in
            storage.getDeletedHistoryToUpload()
            >>== { guids in
                return self.uploadDeletedPlaces(guids, lastTimestamp: timestamp, fromStorage: storage, withServer: storageClient)
            }
        }

        let uploadModified: Timestamp -> DeferredTimestamp = { timestamp in
            storage.getModifiedHistoryToUpload()
                >>== { places in
                    return self.uploadModifiedPlaces(places, lastTimestamp: timestamp, fromStorage: storage, withServer: storageClient)
            }
        }

        return deferResult(lastTimestamp)
          >>== uploadDeleted
          >>== uploadModified
           >>> effect({ log.debug("Done syncing.") })
           >>> succeed
    }

    public func synchronizeLocalHistory(history: SyncableHistory, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> Success {
        if !self.canSync() {
            return deferResult(EngineNotEnabledError(engine: self.collection))
        }

        let keys = self.scratchpad.keys?.value
        let encoder = RecordEncoder<HistoryPayload>(decode: { HistoryPayload($0) }, encode: { $0 })
        if let encrypter = keys?.encrypter(self.collection, encoder: encoder) {
            let historyClient = storageClient.clientForCollection(self.collection, encrypter: encrypter)

            let since: Timestamp = self.lastFetched
            log.debug("Synchronizing history. Last fetched: \(since).")

            // TODO: buffer downloaded records, fetching incrementally, so that we can separate
            // the network fetch from record application.

            /*
             * On each chunk that we upload, we pass along the server modified timestamp to the next.
             * The last chunk passes this modified timestamp out, and we assign it to lastFetched, above.
             *
             * The idea of this is twofold:
             *
             * 1. It does the fast-forwarding that every other Sync client does. The zero will never end
             *    up as lastFetched, but reduce requires a base.
             *
             * 2. It allows us to (eventually) pass the last collection modified time as If-Unmodified-Since
             *    on each upload batch, and between the download and the upload phase. This alone allows us
             *    to detect conflicts.
             *
             * In order to implement the latter, we'd need to chain the date from getSince in place of the
             * 0 in the call to uploadOutgoingFromStorage.
             */

            return historyClient.getSince(since)
              >>== { self.applyIncomingToStorage(history, response: $0) }
                // TODO: If we fetch sorted by date, we can bump the lastFetched timestamp
                // to the last successfully applied record timestamp, no matter where we fail.
                // There's no need to do the upload before bumping -- the storage of local changes is stable.
               >>> { self.uploadOutgoingFromStorage(history, lastTimestamp: 0, withServer: historyClient) }
        }

        log.error("Couldn't make history factory.")
        return deferResult(FatalError(message: "Couldn't make history factory."))
    }
}
