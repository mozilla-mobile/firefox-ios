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
let ClientsStorageVersion = 1

// TODO
public protocol Command {
    static func fromName(_ command: String, args: [JSON]) -> Command?
    func run(_ synchronizer: ClientsSynchronizer) -> Success
    static func commandFromSyncCommand(_ syncCommand: SyncCommand) -> Command?
}

// Shit.
// We need a way to wipe or reset engines.
// We need a way to log out the account.
// So when we sync commands, we're gonna need a delegate of some kind.
open class WipeCommand: Command {

    public init?(command: String, args: [JSON]) {
        return nil
    }

    open class func fromName(_ command: String, args: [JSON]) -> Command? {
        return WipeCommand(command: command, args: args)
    }

    open func run(_ synchronizer: ClientsSynchronizer) -> Success {
        return succeed()
    }

    open static func commandFromSyncCommand(_ syncCommand: SyncCommand) -> Command? {
        let json = JSON(parseJSON: syncCommand.value)
        if let name = json["command"].string,
            let args = json["args"].array {
                return WipeCommand.fromName(name, args: args)
        }
        return nil
    }
}

open class DisplayURICommand: Command {
    let uri: URL
    let title: String

    public init?(command: String, args: [JSON]) {
        if let uri = args[0].string?.asURL,
            let title = args[2].string {
                self.uri = uri
                self.title = title
        } else {
            // Oh, Swift.
            self.uri = "http://localhost/".asURL!
            self.title = ""
            return nil
        }
    }

    open class func fromName(_ command: String, args: [JSON]) -> Command? {
        return DisplayURICommand(command: command, args: args)
    }

    open func run(_ synchronizer: ClientsSynchronizer) -> Success {
        synchronizer.delegate.displaySentTabForURL(uri, title: title)
        return succeed()
    }

    open static func commandFromSyncCommand(_ syncCommand: SyncCommand) -> Command? {
        let json = JSON(parseJSON: syncCommand.value)
        if let name = json["command"].string,
            let args = json["args"].array {
                return DisplayURICommand.fromName(name, args: args)
        }
        return nil
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

open class ClientsSynchronizer: TimestampedSingleCollectionSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "clients")
    }

    override var storageVersion: Int {
        return ClientsStorageVersion
    }

    var clientRecordLastUpload: Timestamp {
        set(value) {
            self.prefs.setLong(value, forKey: "lastClientUpload")
        }

        get {
            return self.prefs.unsignedLongForKey("lastClientUpload") ?? 0
        }
    }

    // Sync Object Format (Version 1) for Form Factors: http://docs.services.mozilla.com/sync/objectformats.html#id2
    fileprivate enum SyncFormFactorFormat: String {
        case phone = "phone"
        case tablet = "tablet"
    }

    open func getOurClientRecord() -> Record<ClientPayload> {
        let guid = self.scratchpad.clientGUID
        let formfactor = formFactorString()
        
        let json = JSON(object: [
            "id": guid,
            "version": AppInfo.appVersion,
            "protocols": ["1.5"],
            "name": self.scratchpad.clientName,
            "os": "iOS",
            "commands": [JSON](),
            "type": "mobile",
            "appPackage": Bundle.main.bundleIdentifier ?? "org.mozilla.ios.FennecUnknown",
            "application": DeviceInfo.appName(),
            "device": DeviceInfo.deviceModel(),
            "formfactor": formfactor])

        let payload = ClientPayload(json)
        return Record(id: guid, payload: payload, ttl: ThreeWeeksInSeconds)
    }

    fileprivate func formFactorString() -> String {
        let userInterfaceIdiom = UIDevice.current.userInterfaceIdiom
        var formfactor: String
        
        switch userInterfaceIdiom {
        case .phone:
            formfactor = SyncFormFactorFormat.phone.rawValue
        case .pad:
            formfactor = SyncFormFactorFormat.tablet.rawValue
        default:
            formfactor = SyncFormFactorFormat.phone.rawValue
        }
        
        return formfactor
    }

    fileprivate func clientRecordToLocalClientEntry(_ record: Record<ClientPayload>) -> RemoteClient {
        let modified = record.modified
        let payload = record.payload
        return RemoteClient(json: payload.json, modified: modified)
    }

    // If this is a fresh start, do a wipe.
    // N.B., we don't wipe outgoing commands! (TODO: check this when we implement commands!)
    // N.B., but perhaps we should discard outgoing wipe/reset commands!
    fileprivate func wipeIfNecessary(_ localClients: RemoteClientsAndTabs) -> Success {
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
    fileprivate func processCommandsFromRecord(_ record: Record<ClientPayload>?, withServer storageClient: Sync15CollectionClient<ClientPayload>) -> Deferred<Maybe<(Bool, [Command])>> {
        log.debug("Processing commands from downloaded record.")

        // TODO: short-circuit based on the modified time of the record we uploaded, so we don't need to skip ahead.
        if let record = record {
            let commands = record.payload.commands
            if !commands.isEmpty {
                func parse(_ json: JSON) -> Command? {
                    if let name = json["command"].string,
                        let args = json["args"].array,
                        let constructor = Commands[name] {
                            return constructor(name, args)
                    }
                    return nil
                }

                // TODO: can we do anything better if a command fails?
                return deferMaybe((true, optFilter(commands.map(parse))))
            }
        }

        return deferMaybe((false, []))
    }

    fileprivate func uploadClientCommands(toLocalClients localClients: RemoteClientsAndTabs, withServer storageClient: Sync15CollectionClient<ClientPayload>) -> Success {
        return localClients.getCommands() >>== { clientCommands in
            return clientCommands.map { (clientGUID, commands) -> Success in
                self.syncClientCommands(clientGUID, commands: commands, clientsAndTabs: localClients, withServer: storageClient)
            }.allSucceed()
        }
    }

    fileprivate func syncClientCommands(_ clientGUID: GUID, commands: [SyncCommand], clientsAndTabs: RemoteClientsAndTabs, withServer storageClient: Sync15CollectionClient<ClientPayload>) -> Success {

        let deleteCommands: () -> Success = {
            return clientsAndTabs.deleteCommands(clientGUID).bind({ x in return succeed() })
        }

        log.debug("Fetching current client record for client \(clientGUID).")
        let fetch = storageClient.get(clientGUID)
        return fetch.bind() { result in
            if let response = result.successValue, response.value.payload.isValid() {
                let record = response.value
                if var clientRecord = record.payload.json.dictionary {
                    clientRecord["commands"] = JSON(record.payload.commands + commands.map { JSON(parseJSON: $0.value) })
                    let uploadRecord = Record(id: clientGUID, payload: ClientPayload(JSON(clientRecord)), ttl: ThreeWeeksInSeconds)
                    return storageClient.put(uploadRecord, ifUnmodifiedSince: record.modified)
                        >>== { resp in
                            log.debug("Client \(clientGUID) commands upload succeeded.")

                            // Always succeed, even if we couldn't delete the commands.
                            return deleteCommands()
                    }
                }
            } else {
                if let failure = result.failureValue {
                    log.warning("Failed to fetch record with GUID \(clientGUID).")
                    if failure is NotFound<HTTPURLResponse> {
                        log.debug("Not waiting to see if the client comes back.")

                        // TODO: keep these around and retry, expiring after a while.
                        // For now we just throw them away so we don't fail every time.
                        return deleteCommands()
                    }

                    if failure is BadRequestError<HTTPURLResponse> {
                        log.debug("We made a bad request. Throwing away queued commands.")
                        return deleteCommands()
                    }
                }
            }

            log.error("Client \(clientGUID) commands upload failed: No remote client for GUID")
            return deferMaybe(UnknownError())
        }
    }

    /**
     * Upload our record if either (a) we know we should upload, or (b)
     * our own notes tell us we're due to reupload.
     */
    fileprivate func maybeUploadOurRecord(_ should: Bool, ifUnmodifiedSince: Timestamp?, toServer storageClient: Sync15CollectionClient<ClientPayload>) -> Success {

        let lastUpload = self.clientRecordLastUpload
        let expired = lastUpload < (Date.now() - (2 * OneDayInMilliseconds))
        log.debug("Should we upload our client record? Caller = \(should), expired = \(expired).")
        if !should && !expired {
            return succeed()
        }

        let iUS: Timestamp? = ifUnmodifiedSince ?? ((lastUpload == 0) ? nil : lastUpload)

        var uploadStats = SyncUploadStats()
        return storageClient.put(getOurClientRecord(), ifUnmodifiedSince: iUS)
            >>== { resp in
                if let ts = resp.metadata.lastModifiedMilliseconds {
                    // Protocol says this should always be present for success responses.
                    log.debug("Client record upload succeeded. New timestamp: \(ts).")
                    self.clientRecordLastUpload = ts
                    uploadStats.sent += 1
                } else {
                    uploadStats.sentFailed += 1
                }
                self.statsSession.recordUpload(stats: uploadStats)
                return succeed()
        }
    }

    fileprivate func applyStorageResponse(_ response: StorageResponse<[Record<ClientPayload>]>, toLocalClients localClients: RemoteClientsAndTabs, withServer storageClient: Sync15CollectionClient<ClientPayload>) -> Success {
        log.debug("Applying clients response.")

        var downloadStats = SyncDownloadStats()

        let records = response.value
        let responseTimestamp = response.metadata.lastModifiedMilliseconds

        log.debug("Got \(records.count) client records.")

        let ourGUID = self.scratchpad.clientGUID
        var toInsert = [RemoteClient]()
        var ours: Record<ClientPayload>? = nil

        for (rec) in records {
            guard rec.payload.isValid() else {
                log.warning("Client record \(rec.id) is invalid. Skipping.")
                continue
            }

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

        downloadStats.applied += toInsert.count

        // Apply remote changes.
        // Collect commands from our own record and reupload if necessary.
        // Then run the commands and return.
        return localClients.insertOrUpdateClients(toInsert)
            >>== { succeeded in
                downloadStats.succeeded += succeeded
                downloadStats.failed += (toInsert.count - succeeded)
                self.statsSession.recordDownload(stats: downloadStats)
                return succeed()
            }
            >>== { self.processCommandsFromRecord(ours, withServer: storageClient) }
            >>== { (shouldUpload, commands) in
                return self.maybeUploadOurRecord(shouldUpload, ifUnmodifiedSince: ours?.modified, toServer: storageClient)
                    >>> { self.uploadClientCommands(toLocalClients: localClients, withServer: storageClient) }
                    >>> {
                        log.debug("Running \(commands.count) commands.")
                        for (command) in commands {
                            let _ = command.run(self)
                        }
                        self.lastFetched = responseTimestamp!
                        return succeed()
                }
        }
    }

    open func synchronizeLocalClients(_ localClients: RemoteClientsAndTabs, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> SyncResult {
        log.debug("Synchronizing clients.")

        if let reason = self.reasonToNotSync(storageClient) {
            switch reason {
            case .engineRemotelyNotEnabled:
                // This is a hard error for us.
                return deferMaybe(FatalError(message: "clients not mentioned in meta/global. Server wiped?"))
            default:
                return deferMaybe(SyncStatus.notStarted(reason))
            }
        }

        let keys = self.scratchpad.keys?.value
        let encoder = RecordEncoder<ClientPayload>(decode: { ClientPayload($0) }, encode: { $0.json })
        let encrypter = keys?.encrypter(self.collection, encoder: encoder)
        if encrypter == nil {
            log.error("Couldn't make clients encrypter.")
            return deferMaybe(FatalError(message: "Couldn't make clients encrypter."))
        }

        let clientsClient = storageClient.clientForCollection(self.collection, encrypter: encrypter!)

        if !self.remoteHasChanges(info) {
            log.debug("No remote changes for clients. (Last fetched \(self.lastFetched).)")
            statsSession.start()
            return self.maybeUploadOurRecord(false, ifUnmodifiedSince: nil, toServer: clientsClient)
                >>> { self.uploadClientCommands(toLocalClients: localClients, withServer: clientsClient) }
                >>> { deferMaybe(self.completedWithStats) }
        }

        // TODO: some of the commands we process might involve wiping collections or the
        // entire profile. We should model this as an explicit status, and return it here
        // instead of .completed.
        statsSession.start()
        return clientsClient.getSince(self.lastFetched)
            >>== { response in
                return self.wipeIfNecessary(localClients)
                    >>> { self.applyStorageResponse(response, toLocalClients: localClients, withServer: clientsClient) }
            }
            >>> { deferMaybe(self.completedWithStats) }
    }
}
