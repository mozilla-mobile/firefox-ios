/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

// TODO: same comment as for SyncAuthState.swift!
private let log = XCGLogger.defaultInstance()

public typealias Success = Deferred<Result<()>>

private func succeed() -> Success {
    return deferResult(())
}

/**
 * This exists to pass in external context: e.g., the UIApplication can
 * expose notification functionality in this way.
 */
public protocol SyncDelegate {
    func displaySentTabForURL(URL: NSURL, title: String)
    // TODO: storage.
}

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
    init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs)
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

// TODO
public protocol Command {
    static func fromName(command: String, args: [JSON]) -> Command?
    func run(synchronizer: ClientsSynchronizer) -> Success
}

// Shit.
// We need a way to wipe or reset engines.
// We need a way to log out the account.
// So when we sync commands, we're gonna need a delegate of some kind.
public class WipeCommand: Command {
    public init?(command: String, args: [JSON]) {
        return nil
    }

    public class func fromName(command: String, args: [JSON]) -> Command? {
        return WipeCommand(command: command, args: args)
    }

    public func run(synchronizer: ClientsSynchronizer) -> Success {
        return succeed()
    }
}

public class DisplayURICommand: Command {
    let uri: NSURL
    // clientID: we don't care.
    let title: String

    public init?(command: String, args: [JSON]) {
        if let uri = args[0].asString?.asURL,
               title = args[2].asString {
            self.uri = uri
            self.title = title
        } else {
            // Oh, Swift.
            self.uri = "http://localhost/".asURL!
            self.title = ""
            return nil
        }
    }

    public class func fromName(command: String, args: [JSON]) -> Command? {
        return DisplayURICommand(command: command, args: args)
    }

    public func run(synchronizer: ClientsSynchronizer) -> Success {
        synchronizer.delegate.displaySentTabForURL(uri, title: title)
        return succeed()
    }
}

let Commands: [String: (String, [JSON]) -> Command?] = [
    "wipeAll": WipeCommand.fromName,
    "wipeEngine": WipeCommand.fromName,
    // resetEngine
    // resetAll
    // logout
    "displayURI": DisplayURICommand.fromName,
]

public protocol SingleCollectionSynchronizer {
    func remoteHasChanges(info: InfoCollections) -> Bool
}

public class BaseSingleCollectionSynchronizer: SingleCollectionSynchronizer {
    let collection: String

    private let scratchpad: Scratchpad
    private let delegate: SyncDelegate
    private let prefs: Prefs

    init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs, collection: String) {
        self.scratchpad = scratchpad
        self.delegate = delegate
        self.collection = collection
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
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "clients")
    }

    var clientRecordLastUpload: Timestamp {
        set(value) {
            self.prefs.setLong(value, forKey: "lastClientUpload")
        }

        get {
            return self.prefs.unsignedLongForKey("lastClientUpload") ?? 0
        }
    }

    public func getOurClientRecord() -> Record<ClientPayload> {
        let guid = self.scratchpad.clientGUID
        let json = JSON([
            "id": guid,
            "version": "0.1",    // TODO
            "protocols": ["1.5"],
            "name": self.scratchpad.clientName,
            "os": "iOS",
            "commands": [JSON](),
            "type": "mobile",
            "appPackage": NSBundle.mainBundle().bundleIdentifier ?? "org.mozilla.ios.FennecUnknown",
            "application": DeviceInfo.appName(),
            "device": DeviceInfo.deviceModel(),
            "formfactor": DeviceInfo.isSimulator() ? "simulator" : "phone",
        ])

        let payload = ClientPayload(json)
        return Record(id: guid, payload: payload, ttl: ThreeWeeksInSeconds)
    }

    private func clientRecordToLocalClientEntry(record: Record<ClientPayload>) -> RemoteClient {
        let modified = record.modified
        let payload = record.payload
        return RemoteClient(json: payload, modified: modified)
    }

    // If this is a fresh start, do a wipe.
    // N.B., we don't wipe outgoing commands! (TODO: check this when we implement commands!)
    // N.B., but perhaps we should discard outgoing wipe/reset commands!
    private func wipeIfNecessary(localClients: RemoteClientsAndTabs) -> Success {
        if self.lastFetched == 0 {
            return localClients.wipeClients()
        }
        return succeed()
    }

    /**
     * Returns whether any commands were found (and thus a replacement record
     * needs to be uploaded). Also returns the commands: we run them after we
     * upload a replacement record.
     */
    private func processCommandsFromRecord(record: Record<ClientPayload>?, withServer storageClient: Sync15CollectionClient<ClientPayload>) -> Deferred<Result<(Bool, [Command])>> {
        log.debug("Processing commands from downloaded record.")

        // TODO: short-circuit based on the modified time of the record we uploaded, so we don't need to skip ahead.
        if let record = record {
            let commands = record.payload.commands
            if !commands.isEmpty {
                func parse(json: JSON) -> Command? {
                    if let name = json["command"].asString,
                        args = json["args"].asArray,
                        constructor = Commands[name] {
                            return constructor(name, args)
                    }
                    return nil
                }

                // TODO: can we do anything better if a command fails?
                return deferResult((true, optFilter(commands.map(parse))))
            }
        }

        return deferResult((false, []))
    }

    /**
     * Upload our record if either (a) we know we should upload, or (b)
     * our own notes tell us we're due to reupload.
     */
    private func maybeUploadOurRecord(should: Bool, ifUnmodifiedSince: Timestamp?, toServer storageClient: Sync15CollectionClient<ClientPayload>) -> Success {

        let lastUpload = self.clientRecordLastUpload
        let expired = lastUpload < (NSDate.now() - OneWeekInMilliseconds)
        log.debug("Should we upload our client record? Caller = \(should), expired = \(expired).")
        if !should && !expired {
            return succeed()
        }

        let iUS: Timestamp? = ifUnmodifiedSince ?? ((lastUpload == 0) ? nil : lastUpload)

        return storageClient.put(getOurClientRecord(), ifUnmodifiedSince: iUS)
           >>== { resp in
            if let ts = resp.metadata.lastModifiedMilliseconds {
                // Protocol says this should always be present for success responses.
                log.debug("Client record upload succeeded. New timestamp: \(ts).")
                self.clientRecordLastUpload = ts
            }
            return succeed()
        }
    }

    private func applyStorageResponse(response: StorageResponse<[Record<ClientPayload>]>, toLocalClients localClients: RemoteClientsAndTabs, withServer storageClient: Sync15CollectionClient<ClientPayload>) -> Success {
        log.debug("Applying clients response.")

        let records = response.value
        let responseTimestamp = response.metadata.lastModifiedMilliseconds

        func updateMetadata() -> Success {
            self.lastFetched = responseTimestamp!
            return succeed()
        }

        log.debug("Got \(records.count) client records.")

        let ourGUID = self.scratchpad.clientGUID
        var toInsert = [RemoteClient]()
        var ours: Record<ClientPayload>? = nil

        for (rec) in records {
            if rec.id == ourGUID {
                if rec.modified == self.clientRecordLastUpload {
                    log.debug("Skipping our own unmodified record.")
                } else {
                    log.debug("Saw our own record in response.")
                    ours = rec
                }
            } else {
                toInsert.append(self.clientRecordToLocalClientEntry(rec))
            }
        }

        // Apply remote changes.
        // Collect commands from our own record and reupload if necessary.
        // Then run the commands and return.
        return localClients.insertOrUpdateClients(toInsert)
          >>== { self.processCommandsFromRecord(ours, withServer: storageClient) }
          >>== { (shouldUpload, commands) in
            return self.maybeUploadOurRecord(shouldUpload, ifUnmodifiedSince: ours?.modified, toServer: storageClient)
               >>> {
                log.debug("Running \(commands.count) commands.")
                for (command) in commands {
                    command.run(self)
                }
                return succeed()
            }
        }
    }

    // TODO: return whether or not the sync should continue.
    public func synchronizeLocalClients(localClients: RemoteClientsAndTabs, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> Success {
        log.debug("Synchronizing clients.")

        let keys = self.scratchpad.keys?.value
        let encoder = RecordEncoder<ClientPayload>(decode: { ClientPayload($0) }, encode: { $0 })
        let encrypter = keys?.encrypter(self.collection, encoder: encoder)
        if encrypter == nil {
            log.error("Couldn't make clients encrypter.")
            return deferResult(FatalError(message: "Couldn't make clients encrypter."))
        }

        let clientsClient = storageClient.clientForCollection(self.collection, encrypter: encrypter!)

        if !self.remoteHasChanges(info) {
            log.debug("No remote changes for clients. (Last fetched \(self.lastFetched).)")
            return maybeUploadOurRecord(false, ifUnmodifiedSince: nil, toServer: clientsClient)
        }

        return clientsClient.getSince(self.lastFetched)
          >>== { response in
            return self.wipeIfNecessary(localClients)
               >>> { self.applyStorageResponse(response, toLocalClients: localClients, withServer: clientsClient) }
        }
    }
}

public class TabsSynchronizer: BaseSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "tabs")
    }

    public func synchronizeLocalTabs(localTabs: RemoteClientsAndTabs, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> Success {
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

        if !self.remoteHasChanges(info) {
            // Nothing to do.
            // TODO: upload local tabs if they've changed or we're in a fresh start.
            return succeed()
        }

        let keys = self.scratchpad.keys?.value
        let encoder = RecordEncoder<TabsPayload>(decode: { TabsPayload($0) }, encode: { $0 })
        if let encrypter = keys?.encrypter(self.collection, encoder: encoder) {
            let tabsClient = storageClient.clientForCollection(self.collection, encrypter: encrypter)

            return tabsClient.getSince(self.lastFetched)
              >>== onResponseReceived
        }

        log.error("Couldn't make tabs factory.")
        return deferResult(FatalError(message: "Couldn't make tabs factory."))
    }
}