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

public class HistorySynchronizer: BaseSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "history")
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

            log.debug("Record: \(guid): \(payload.title)")

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
            return storage.insertOrUpdatePlace(place, modified: modified)
               >>> { storage.storeRemoteVisits(payload.visits, forGUID: guid) }
        }

        func allSucceed(arr: [Success]) -> Success {
            return all(arr).map {
                for x in $0 {
                    if x.isFailure {
                        log.error("Record application failed: \(x.failureValue)")
                        return x
                    }
                }
                log.debug("Record application succeeded.")
                return Result(success: ())
            }
        }

        // TODO: a much more efficient way to do this is to:
        // 1. Start a transaction.
        // 2. Try to update each place. Note failures.
        // 3. bulkInsert all failed updates in one go.
        // 4. Store all remote visits for all places in one go, constructing a single sequence of visits.
        return allSucceed(records.map(applyRecord))
           >>> {
            log.debug("Bumping fetch timestamp to \(fetched).")
            self.lastFetched = fetched
            return succeed()
        }
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

    private func uploadModifiedPlaces(places: [(Place, [Visit])], lastTimestamp: Timestamp, fromStorage storage: SyncableHistory, withServer storageClient: Sync15CollectionClient<HistoryPayload>) -> Success {

        // Upload 50 records at a time. This needs to be a real Array, not an ArraySlice,
        // for the types to line up.

        let chunks = chunk(places, by: 50).map { Array($0) }
        let start = deferResult(lastTimestamp)

        let perChunk: ([(Place, [Visit])], Timestamp) -> Deferred<Result<Timestamp>> = { (place, timestamp) in
            // TODO: detect interruptions -- clients uploading records during our sync --
            // by using ifUnmodifiedSince. We can detect uploaded records since our download
            // (chain the download timestamp into this function), and we can detect uploads
            // that race with our own (chain download timestamps across 'walk' steps).
            // If we do that, we can also advance our last fetch timestamp after each chunk.
            let records = places.map(HistorySynchronizer.makeHistoryRecord)

            log.debug("Uploading \(records.count) records.")
            // TODO: use I-U-S.
            return storageClient.post(records, ifUnmodifiedSince: nil)
                >>== { storage.markAsSynchronized($0.value.success, modified: $0.value.modified) }
        }

        // Chain the last upload timestamp right into our lastFetched timestamp.
        // This is what Sync clients tend to do, but we can probably do better.
        return walk(chunks, start, perChunk)
          >>== {
            log.debug("Setting post-upload lastFetched to \($0).")
            self.lastFetched = $0
            return succeed()
        }
    }

    private func uploadOutgoingFromStorage(storage: SyncableHistory, lastTimestamp: Timestamp, withServer storageClient: Sync15CollectionClient<HistoryPayload>) -> Success {

        return storage.getHistoryToUpload()
          >>== { places in
            log.debug("Uploading \(places.count) places.")
            if places.isEmpty {
                return succeed()
            }

            return self.uploadModifiedPlaces(places, lastTimestamp: lastTimestamp, fromStorage: storage, withServer: storageClient)
        }
    }


    public func synchronizeLocalHistory(history: SyncableHistory, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> Success {
        let keys = self.scratchpad.keys?.value
        let encoder = RecordEncoder<HistoryPayload>(decode: { HistoryPayload($0) }, encode: { $0 })
        if let encrypter = keys?.encrypter(self.collection, encoder: encoder) {
            let historyClient = storageClient.clientForCollection(self.collection, encrypter: encrypter)

            let since: Timestamp = self.lastFetched
            log.debug("Synchronizing history. Last fetched: \(since).")

            // TODO: buffer downloaded records. Do this by marking items as unprocessed?

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
