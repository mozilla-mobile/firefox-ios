/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import Deferred
import SwiftyJSON

private let log = Logger.syncLogger
let TabsStorageVersion = 1

open class TabsSynchronizer: TimestampedSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "tabs")
    }

    override var storageVersion: Int {
        return TabsStorageVersion
    }

    var tabsRecordLastUpload: Timestamp {
        set(value) {
            self.prefs.setLong(value, forKey: "lastTabsUpload")
        }

        get {
            return self.prefs.unsignedLongForKey("lastTabsUpload") ?? 0
        }
    }

    fileprivate func createOwnTabsRecord(_ tabs: [RemoteTab]) -> Record<TabsPayload> {
        let guid = self.scratchpad.clientGUID

        let tabsJSON = JSON([
            "id": guid,
            "clientName": self.scratchpad.clientName,
            "tabs": tabs.flatMap { $0.toDictionary() }
        ])
        if Logger.logPII {
            log.verbose("Sending tabs JSON \(tabsJSON.stringValue() ?? "nil")")
        }
        let payload = TabsPayload(tabsJSON)
        return Record(id: guid, payload: payload, ttl: ThreeWeeksInSeconds)
    }

    fileprivate func uploadOurTabs(_ localTabs: RemoteClientsAndTabs, toServer tabsClient: Sync15CollectionClient<TabsPayload>) -> Success {
        // check to see if our tabs have changed or we're in a fresh start
        let lastUploadTime: Timestamp? = (self.tabsRecordLastUpload == 0) ? nil : self.tabsRecordLastUpload
        if let lastUploadTime = lastUploadTime,
            lastUploadTime >= (Date.now() - (OneMinuteInMilliseconds)) {
            log.debug("Not uploading tabs: already did so at \(lastUploadTime).")
            return succeed()
        }

        return localTabs.getTabsForClientWithGUID(nil) >>== { tabs in
            if let lastUploadTime = lastUploadTime {
                // TODO: track this in memory so we don't have to hit the disk to figure out when our tabs have
                // changed and need to be uploaded.
                if tabs.every({ $0.lastUsed < lastUploadTime }) {
                    return succeed()
                }
            }

            let tabsRecord = self.createOwnTabsRecord(tabs)
            log.debug("Uploading our tabs: \(tabs.count).")

            var uploadStats = SyncUploadStats()
            uploadStats.sent += 1

            // We explicitly don't send If-Unmodified-Since, because we always
            // want our upload to succeed -- we own the record.
            return tabsClient.put(tabsRecord, ifUnmodifiedSince: nil) >>== { resp in
                if let ts = resp.metadata.lastModifiedMilliseconds {
                    // Protocol says this should always be present for success responses.
                    log.debug("Tabs record upload succeeded. New timestamp: \(ts).")
                    self.tabsRecordLastUpload = ts
                } else {
                    uploadStats.sentFailed += 1
                }
                return succeed()
            } >>== effect({ self.statsSession.recordUpload(stats: uploadStats) })
        }
    }

    open func synchronizeLocalTabs(_ localTabs: RemoteClientsAndTabs, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> SyncResult {
        func onResponseReceived(_ response: StorageResponse<[Record<TabsPayload>]>) -> Success {

            func afterWipe() -> Success {
                var downloadStats = SyncDownloadStats()

                let doInsert: (Record<TabsPayload>) -> Deferred<Maybe<(Int)>> = { record in
                    let remotes = record.payload.isValid() ? record.payload.remoteTabs : []
                    let ins = localTabs.insertOrUpdateTabsForClientGUID(record.id, tabs: remotes)

                    // Since tabs are all sent within a single record, we don't count number of tabs applied
                    // but number of records. In this case it's just one.
                    downloadStats.applied += 1
                    ins.upon() { res in
                        if let inserted = res.successValue {
                            if inserted != remotes.count {
                                log.warning("Only inserted \(inserted) tabs, not \(remotes.count). Malformed or missing client?")
                            }
                            downloadStats.applied += 1
                        } else {
                            downloadStats.failed += 1
                        }
                    }
                    return ins
                }

                let ourGUID = self.scratchpad.clientGUID

                let records = response.value
                let responseTimestamp = response.metadata.lastModifiedMilliseconds

                log.debug("Got \(records.count) tab records.")

                // We can only insert tabs for clients that we know locally, so
                // first we fetch the list of IDs and intersect the two.
                // TODO: there's a much more efficient way of doing this.
                return localTabs.getClientGUIDs()
                    >>== { clientGUIDs in
                        let filtered = records.filter({ $0.id != ourGUID && clientGUIDs.contains($0.id) })
                        if filtered.count != records.count {
                            log.debug("Filtered \(records.count) records down to \(filtered.count).")
                        }

                        let allDone = all(filtered.map(doInsert))
                        return allDone.bind { (results) -> Success in
                            if let failure = results.find({ $0.isFailure }) {
                                return deferMaybe(failure.failureValue!)
                            }

                            self.lastFetched = responseTimestamp!
                            return succeed()
                        }
                } >>== effect({ self.statsSession.downloadStats })
            }

            // If this is a fresh start, do a wipe.
            if self.lastFetched == 0 {
                log.info("Last fetch was 0. Wiping tabs.")
                return localTabs.wipeRemoteTabs()
                    >>== afterWipe
            }

            return afterWipe()
        }

        if let reason = self.reasonToNotSync(storageClient) {
            return deferMaybe(SyncStatus.notStarted(reason))
        }

        let keys = self.scratchpad.keys?.value
        let encoder = RecordEncoder<TabsPayload>(decode: { TabsPayload($0) }, encode: { $0.json })
        if let encrypter = keys?.encrypter(self.collection, encoder: encoder) {
            let tabsClient = storageClient.clientForCollection(self.collection, encrypter: encrypter)

            statsSession.start()

            if !self.remoteHasChanges(info) {
                // upload local tabs if they've changed or we're in a fresh start.
                let _ = uploadOurTabs(localTabs, toServer: tabsClient)
                return deferMaybe(completedWithStats)
            }

            return tabsClient.getSince(self.lastFetched)
                >>== onResponseReceived
                >>> { self.uploadOurTabs(localTabs, toServer: tabsClient) }
                >>> { deferMaybe(self.completedWithStats) }
        }

        log.error("Couldn't make tabs factory.")
        return deferMaybe(FatalError(message: "Couldn't make tabs factory."))
    }

    /**
     * This is a dedicated resetting interface that does both tabs and clients at the
     * same time.
     */
    open static func resetClientsAndTabsWithStorage(_ storage: ResettableSyncStorage, basePrefs: Prefs) -> Success {
        let clientPrefs = BaseCollectionSynchronizer.prefsForCollection("clients", withBasePrefs: basePrefs)
        let tabsPrefs = BaseCollectionSynchronizer.prefsForCollection("tabs", withBasePrefs: basePrefs)
        clientPrefs.removeObjectForKey("lastFetched")
        tabsPrefs.removeObjectForKey("lastFetched")
        return storage.resetClient()
    }
}

extension RemoteTab {
    public func toDictionary() -> Dictionary<String, Any>? {
        let tabHistory = history.flatMap { $0.absoluteString }
        if tabHistory.isEmpty {
            return nil
        }
        return [
            "title": title,
            "icon": icon?.absoluteString as Any? ?? NSNull(),
            "urlHistory": tabHistory,
            "lastUsed": millisecondsToDecimalSeconds(lastUsed)
        ]
    }
}
