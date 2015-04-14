/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()

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
    init(scratchpad: Scratchpad, basePrefs: Prefs)
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

public protocol SingleCollectionSynchronizer {
    func remoteHasChanges(info: InfoCollections) -> Bool
}

public class BaseSingleCollectionSynchronizer: SingleCollectionSynchronizer {
    let collection: String
    private let scratchpad: Scratchpad
    private let prefs: Prefs

    init(scratchpad: Scratchpad, basePrefs: Prefs, collection: String) {
        self.collection = collection
        self.scratchpad = scratchpad
        let branchName = "synchronizer." + collection + "."
        self.prefs = basePrefs.branch(branchName)

        log.info("Synchronizer configured with prefs \(branchName).")
    }

    var lastFetched: Timestamp {
        set(value) {
            self.prefs.setLong(value, forKey: "lastFetched")
        }

        get {
            return self.prefs.unsignedLongForKey("lastFetched") ?? 0
        }
    }

    public func remoteHasChanges(info: InfoCollections) -> Bool {
        return info.modified(self.collection) > self.lastFetched
    }
}

public class ClientsSynchronizer: BaseSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, basePrefs: basePrefs, collection: "clients")
    }

    private func clientRecordToLocalClientEntry(record: Record<ClientPayload>) -> RemoteClient {
        let modified = record.modified
        let payload = record.payload
        return RemoteClient(json: payload, modified: modified)
    }

    public func synchronizeLocalClients(localClients: RemoteClientsAndTabs, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> Deferred<Result<()>> {
        func onResponseReceived(response: StorageResponse<[Record<ClientPayload>]>) -> Deferred<Result<()>> {
            func afterWipe() -> Deferred<Result<()>> {
                // TODO: process incoming records: both others and our own.
                // TODO: decide whether to upload ours.
                let ourGUID = self.scratchpad.clientGUID

                let records = response.value
                let responseTimestamp = response.metadata.lastModifiedMilliseconds

                log.debug("Got \(records.count) client records.")

                // TODO: batching.
                for (record) in records {
                    if record.id == ourGUID {
                        // Skip. TODO: process commands.
                        continue
                    }

                    let rec = self.clientRecordToLocalClientEntry(record)
                    log.info("Storing client \(rec).")
                    localClients.insertOrUpdateClient(rec)
                }

                // TODO: don't force-unwrap?
                self.lastFetched = responseTimestamp!
                return Deferred(value: Result(success: ()))

            }

            // If this is a fresh start, do a wipe.
            // N.B., we don't wipe outgoing commands! (TODO: check this when we implement commands!)
            // N.B., but perhaps we should discard outgoing wipe/reset commands!
            if self.lastFetched == 0 {
                return chainDeferred(localClients.wipeClients(), afterWipe)
            }
            return afterWipe()
        }

        if !self.remoteHasChanges(info) {
            // Nothing to do.
            // TODO: upload local client if necessary.
            // TODO: move client upload timestamp out of Scratchpad.
            log.debug("No remote changes for clients. (Last fetched \(self.lastFetched).)")
            return Deferred(value: Result(success: ()))
        }

        if let factory: (String) -> ClientPayload? = self.scratchpad.keys?.value.factory(self.collection, f: { ClientPayload($0) }) {
            let clientsClient = storageClient.clientForCollection(self.collection, factory: factory)
            return chainDeferred(clientsClient.getSince(self.lastFetched), onResponseReceived)
        } else {
            log.error("Couldn't make clients factory.")
            return Deferred(value: Result(failure: FatalError(message: "Couldn't make clients factory.")))
        }
    }
}

public class TabsSynchronizer: BaseSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, basePrefs: basePrefs, collection: "tabs")
    }

    public func synchronizeLocalTabs(localTabs: RemoteClientsAndTabs, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> Deferred<Result<()>> {
        if !self.remoteHasChanges(info) {
            // Nothing to do.
            // TODO: upload local tabs if they've changed or we're in a fresh start.
            return Deferred(value: Result(success: ()))
        }

        if let factory: (String) -> TabsPayload? = self.scratchpad.keys?.value.factory(self.collection, f: { TabsPayload($0) }) {
            let tabsClient = storageClient.clientForCollection(self.collection, factory: factory)

            return chainDeferred(tabsClient.getSince(self.lastFetched), {
                // TODO: decide whether to upload ours.
                let ourGUID = self.scratchpad.clientGUID
                let records = $0.value
                let responseTimestamp = $0.metadata.lastModifiedMilliseconds

                // If this is a fresh start, do a wipe.
                let onward: Deferred<Result<()>> = (self.lastFetched == 0) ? localTabs.wipeTabs() : Deferred(value: Result(success: ()))

                return chainDeferred(onward, {
                    log.debug("Got \(records.count) tab records.")

                    // TODO: batching.
                    for (record) in records {
                        if record.id == ourGUID {
                            // Skip. TODO: process commands.
                            continue
                        }

                        let remotes = record.payload.remoteTabs
                        log.info("Inserting \(remotes.count) tabs for client \(record.id).")
                        localTabs.insertOrUpdateTabsForClient(record.id, tabs: remotes)
                    }

                    self.lastFetched = responseTimestamp!
                    return Deferred(value: Result(success: ()))
                })
            })
        } else {
            log.error("Couldn't make tabs factory.")
            return Deferred(value: Result(failure: FatalError(message: "Couldn't make tabs factory.")))
        }
    }
}