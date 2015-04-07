/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage

// TODO: return values?
/**
 * A Synchronizer is (unavoidably) entirely in charge of what it does within a sync.
 * For example, it might make incremental progress in building a local cache of remote records, never actually performing an upload or modifying local storage.
 * It might only upload data. Etc.
 *
 * Eventually I envision an intent-like approach, or additional methods, to specify preferences and constraints
 * (e.g., "do what you can in a few seconds", or "do a full sync, no matter how long it takes"), but that'll come in time.
 *
 * A Synchronizer is a two-stage beast. It needs to support synchronization, of course; that
 * needs a completely configured client, which can only be obtained from Ready. But it also
 * needs to be able to do certain things beforehand:
 *
 * * Wipe its collections from the server (presumably via a delegate from the state machine).
 * * Prepare to sync from scratch ("reset") in response to a changed set of keys, syncID, or node assignment.
 * * Wipe local storage ("wipeClient").
 *
 * Those imply that some kind of 'Synchronizer' exists throughout the state machine. We *could*
 * pickle instructions for eventual delivery next time one is made and synchronized…
 */
public protocol Synchronizer {
    init(scratchpad: Scratchpad)
    //func synchronize(client: Sync15StorageClient, info: InfoCollections) -> Deferred<Result<Scratchpad>>
}

public class FatalError: SyncError {
    let message: String
    init(message: String) {
        self.message = message
    }

    public var description: String {
        return self.message
    }
}

public class ClientsSynchronizer: Synchronizer {
    private let scratchpad: Scratchpad

    private let prefix = "clients"
    private let collection = "clients"

    required public init(scratchpad: Scratchpad) {
        self.scratchpad = scratchpad
    }

    private func clientRecordToLocalClientEntry(record: Record<ClientPayload>) -> RemoteClient {
        let modified = record.modified
        let payload = record.payload
        return RemoteClient(json: payload, modified: modified)
    }

    public func synchronizeLocalClients(localClients: Clients, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> Deferred<Result<Scratchpad>> {
        let lastFetched = self.scratchpad.collectionLastFetched[self.collection] ?? 0
        if lastFetched >= info.modified(self.collection) {
            // Nothing to do.
            return Deferred(value: Result(success: self.scratchpad))
        }

        if let factory: (String) -> ClientPayload? = self.scratchpad.keys?.value.factory(self.collection, f: { ClientPayload($0) }) {
            let clientsClient = storageClient.clientForCollection(self.collection, factory: factory)
            return chainDeferred(clientsClient.getSince(lastFetched), {
                // TODO: process incoming records: both others and our own.
                // TODO: decide whether to upload ours.
                let ourGUID = "ABC"      // TODO
                let records = $0.value
                let responseTimestamp = $0.metadata.lastModifiedMilliseconds

                // If this is a fresh start, do a wipe.
                // N.B., we don't wipe outgoing commands! (TODO: check this when we implement commands!)
                if (lastFetched == 0) {
                    localClients.wipe()
                }

                // TODO: batching.
                for (record) in records {
                    if record.id == ourGUID {
                        // Skip. TODO: process commands.
                        continue
                    }

                    localClients.storeClient(self.clientRecordToLocalClientEntry(record))
                }

                self.scratchpad.collectionLastFetched["clients"] = responseTimestamp
                return Deferred(value: Result(success: self.scratchpad.checkpoint()))
            })
        } else {
            return Deferred(value: Result(failure: FatalError(message: "Couldn't make clients factory.")))
        }
    }
}