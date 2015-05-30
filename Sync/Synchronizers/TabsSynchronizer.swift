/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()
private let TabsStorageVersion = 1

public class TabsSynchronizer: BaseSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "tabs")
    }

    override var storageVersion: Int {
        return TabsStorageVersion
    }

    public func synchronizeLocalTabs(localTabs: RemoteClientsAndTabs, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> SyncResult {
        func onResponseReceived(response: StorageResponse<[Record<TabsPayload>]>) -> Success {

            func afterWipe() -> Success {
                log.info("Fetching tabs.")
                func doInsert(record: Record<TabsPayload>) -> Deferred<Result<(Int)>> {
                    let remotes = record.payload.remoteTabs
                    log.info("Inserting \(remotes.count) tabs for client \(record.id).")
                    return localTabs.insertOrUpdateTabsForClientGUID(record.id, tabs: remotes)
                }

                // TODO: decide whether to upload ours.
                let ourGUID = self.scratchpad.clientGUID
                let records = response.value
                let responseTimestamp = response.metadata.lastModifiedMilliseconds

                log.debug("Got \(records.count) tab records.")

                let allDone = all(records.filter({ $0.id != ourGUID }).map(doInsert))
                return allDone.bind { (results) -> Success in
                    if let failure = find(results, { $0.isFailure }) {
                        return deferResult(failure.failureValue!)
                    }

                    self.lastFetched = responseTimestamp!
                    return succeed()
                }
            }

            // If this is a fresh start, do a wipe.
            if self.lastFetched == 0 {
                log.info("Last fetch was 0. Wiping tabs.")
                return localTabs.wipeTabs()
                    >>== afterWipe
            }

            return afterWipe()
        }

        if let reason = self.reasonToNotSync() {
            return deferResult(SyncStatus.NotStarted(reason))
        }

        if !self.remoteHasChanges(info) {
            // Nothing to do.
            // TODO: upload local tabs if they've changed or we're in a fresh start.
            return deferResult(.Completed)
        }

        let keys = self.scratchpad.keys?.value
        let encoder = RecordEncoder<TabsPayload>(decode: { TabsPayload($0) }, encode: { $0 })
        if let encrypter = keys?.encrypter(self.collection, encoder: encoder) {
            let tabsClient = storageClient.clientForCollection(self.collection, encrypter: encrypter)

            return tabsClient.getSince(self.lastFetched)
                >>== onResponseReceived
                >>> { deferResult(.Completed) }
        }

        log.error("Couldn't make tabs factory.")
        return deferResult(FatalError(message: "Couldn't make tabs factory."))
    }
}
