// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit
import Shared
import Storage
import SwiftyJSON

let ClientsStorageVersion = 1

public protocol Command {
    static func fromName(_ command: String, args: [JSON]) -> Command?
    func run(_ synchronizer: ClientsSynchronizer) -> Success
    static func commandFromSyncCommand(_ syncCommand: SyncCommand) -> Command?
}

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

    public static func commandFromSyncCommand(_ syncCommand: SyncCommand) -> Command? {
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
    let sender: String

    public init?(command: String, args: [JSON]) {
        if let uri = args[0].string?.asURL,
            let sender = args[1].string,
            let title = args[2].string {
            self.uri = uri
            self.sender = sender
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
        func display(_ deviceName: String? = nil) -> Success {
            synchronizer.delegate.displaySentTab(for: uri, title: title, from: deviceName)
            return succeed()
        }

        guard let sender = synchronizer.localClients?.getClient(guid: sender) else {
            return display()
        }

        return sender >>== { client in
            return display(client?.name)
        }
    }

    public static func commandFromSyncCommand(_ syncCommand: SyncCommand) -> Command? {
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
    // repairResponse
]

open class ClientsSynchronizer: TimestampedSingleCollectionSynchronizer, Synchronizer {
    private var logger: Logger

    public required init(scratchpad: Scratchpad,
                         delegate: SyncDelegate,
                         basePrefs: Prefs,
                         why: OldSyncReason,
                         logger: Logger = DefaultLogger.shared) {
        self.logger = logger
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, why: why, collection: "clients")
    }

    var localClients: RemoteClientsAndTabs?
    // Indicates whether the local client record has been updated to used the
    // FxA Device ID rather than the native client GUID
    var clientGuidIsMigrated = false

    override var storageVersion: Int {
        return ClientsStorageVersion
    }

    var clientRecordLastUpload: Timestamp {
        get {
            return self.prefs.unsignedLongForKey("lastClientUpload") ?? 0
        }

        set(value) {
            self.prefs.setLong(value, forKey: "lastClientUpload")
        }
    }

    // Sync Object Format (Version 1) for Form Factors: http://docs.services.mozilla.com/sync/objectformats.html#id2
    fileprivate enum SyncFormFactorFormat: String {
        case phone
        case tablet
    }

    open func getOurClientRecord() -> Record<ClientPayload> {
        let fxaDeviceId = self.scratchpad.fxaDeviceId
        let formfactor = formFactorString()

        let json = JSON([
            "id": fxaDeviceId,
            "fxaDeviceId": fxaDeviceId,
            "version": AppInfo.appVersion,
            "protocols": ["1.5"],
            "name": self.scratchpad.clientName,
            "os": "iOS",
            "commands": [JSON](),
            "type": "mobile",
            "appPackage": AppInfo.baseBundleIdentifier,
            "application": AppInfo.displayName,
            "device": DeviceInfo.deviceModel(),
            "formfactor": formfactor] as [String: Any])

        let payload = ClientPayload(json)
        return Record(id: fxaDeviceId, payload: payload, ttl: ThreeWeeksInSeconds)
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
        logger.log("Processing commands from downloaded record.",
                   level: .debug,
                   category: .sync)

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

        logger.log("Fetching current client record for client \(clientGUID).",
                   level: .debug,
                   category: .sync)
        let fetch = storageClient.get(clientGUID)
        return fetch.bind { result in
            if let response = result.successValue, response.value.payload.isValid() {
                let record = response.value
                if var clientRecord = record.payload.json.dictionary {
                    clientRecord["commands"] = JSON(record.payload.commands + commands.map { JSON(parseJSON: $0.value) })
                    let uploadRecord = Record(id: clientGUID, payload: ClientPayload(JSON(clientRecord)), ttl: ThreeWeeksInSeconds)
                    return storageClient.put(uploadRecord, ifUnmodifiedSince: record.modified)
                        >>== { resp in
                            self.logger.log("Client \(clientGUID) commands upload succeeded.",
                                            level: .debug,
                                            category: .sync)

                            // Always succeed, even if we couldn't delete the commands.
                            return deleteCommands()
                        }
                }
            } else {
                if let failure = result.failureValue {
                    self.logger.log("Failed to fetch record with GUID \(clientGUID).",
                                    level: .warning,
                                    category: .sync)
                    if failure is NotFound<HTTPURLResponse> {
                        // TODO: keep these around and retry, expiring after a while.
                        // For now we just throw them away so we don't fail every time.
                        return deleteCommands()
                    }

                    if failure is BadRequestError<HTTPURLResponse> {
                        return deleteCommands()
                    }
                }
            }

            self.logger.log("Client \(clientGUID) commands upload failed: No remote client for GUID",
                            level: .warning,
                            category: .sync)
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
        logger.log("Should we upload our client record? Caller = \(should), expired = \(expired).",
                   level: .debug,
                   category: .sync)
        if !should && !expired {
            return succeed()
        }

        let iUS: Timestamp? = ifUnmodifiedSince ?? ((lastUpload == 0) ? nil : lastUpload)

        var uploadStats = SyncUploadStats()
        return storageClient.put(getOurClientRecord(), ifUnmodifiedSince: iUS)
        >>== { resp in
            if let ts = resp.metadata.lastModifiedMilliseconds {
                // Protocol says this should always be present for success responses.
                self.logger.log("Client record upload succeeded. New timestamp: \(ts).",
                                level: .debug,
                                category: .sync)
                self.clientRecordLastUpload = ts
                uploadStats.sent += 1
            } else {
                uploadStats.sentFailed += 1
            }
            self.statsSession.recordUpload(stats: uploadStats)
            return succeed()
        }
    }

    fileprivate func applyStorageResponse(
        _ response: StorageResponse<[Record<ClientPayload>]>,
        toLocalClients localClients: RemoteClientsAndTabs,
        withServer storageClient: Sync15CollectionClient<ClientPayload>
    ) -> Success {
        var downloadStats = SyncDownloadStats()

        let records = response.value
        let responseTimestamp = response.metadata.lastModifiedMilliseconds

        logger.log("Got \(records.count) client records.",
                   level: .debug,
                   category: .sync)

        let ourGUID = self.scratchpad.clientGUID
        let ourFxaDeviceId = self.scratchpad.fxaDeviceId
        var toInsert = [RemoteClient]()
        var ours: Record<ClientPayload>?

        // Indicates whether the local client records include a record with an ID
        // matching the FxA Device ID
        var ourClientRecordExists = false

        for (rec) in records {
            guard rec.payload.isValid() else {
                logger.log("Client record \(rec.id) is invalid. Skipping.",
                           level: .warning,
                           category: .sync)
                continue
            }

            if rec.id == ourGUID {
                if self.clientGuidIsMigrated {
                    logger.log("Skipping our own client records since the guid is not the fxa device ID",
                               level: .debug,
                               category: .sync)
                } else {
                    logger.log("An unmigrated client record was found with a GUID for an ID",
                               level: .warning,
                               category: .sync)
                }
            } else if rec.id == ourFxaDeviceId {
                ourClientRecordExists = true
                if rec.modified == self.clientRecordLastUpload {
                    logger.log("Skipping our own unmodified record.",
                               level: .debug,
                               category: .sync)
                } else {
                    logger.log("Saw our own record in response.",
                               level: .debug,
                               category: .sync)
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
                let ourRecordDidChange = self.why == .didLogin || self.why == .clientNameChanged
                return self.maybeUploadOurRecord(shouldUpload || ourRecordDidChange || self.clientGuidIsMigrated || !ourClientRecordExists, ifUnmodifiedSince: ours?.modified, toServer: storageClient)
                    >>> { self.uploadClientCommands(toLocalClients: localClients, withServer: storageClient) }
                    >>> {
                        self.logger.log("Running \(commands.count) commands.",
                                        level: .debug,
                                        category: .sync)
                        for command in commands {
                            _ = command.run(self)
                        }
                        self.lastFetched = responseTimestamp!
                        return succeed()
                }
        }
    }

    open func synchronizeLocalClients(_ localClients: RemoteClientsAndTabs, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> OldSyncResult {
        logger.log("Synchronizing clients.",
                   level: .debug,
                   category: .sync)
        self.localClients = localClients // Store for later when we process a repairResponse command

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
            logger.log("Couldn't make clients encrypter.",
                       level: .warning,
                       category: .sync)
            return deferMaybe(FatalError(message: "Couldn't make clients encrypter."))
        }

        let clientsClient = storageClient.clientForCollection(self.collection, encrypter: encrypter!)

        // TODO: some of the commands we process might involve wiping collections or the
        // entire profile. We should model this as an explicit status, and return it here
        // instead of .completed.
        statsSession.start()
        // XXX: This is terrible. We always force a re-sync of the clients to work around
        // the fact that `fxaDeviceId` may not have been populated if the list of clients
        // hadn't changed since before the update to v8.0. To force a re-sync, we get all
        // clients since the beginning of time instead of looking at `self.lastFetched`.
        return clientsClient.getSince(0)
            >>== { response in
                return self.maybeDeleteClients(response: response, withServer: storageClient)
                    >>> { self.wipeIfNecessary(localClients)
                                >>> { self.applyStorageResponse(response, toLocalClients: localClients, withServer: clientsClient) }
                    }
            }
            >>> { deferMaybe(self.completedWithStats) }
    }

    private func maybeDeleteClients(response: StorageResponse<[Record<ClientPayload>]>, withServer storageClient: Sync15StorageClient) -> Success {
        let hasOldClientId = response.value.contains { $0.id == self.scratchpad.clientGUID }
        self.clientGuidIsMigrated = false

        if hasOldClientId {
            // Here we are deleting the old client record with the client GUID as the sync ID record. If the browser schema,
            // needs to be reverted from version 41, the client record with an FxA device ID as the record ID will need to
            // be deleted in a similar manner.
            return storageClient.deleteObject(collection: "clients", guid: self.scratchpad.clientGUID).bind { result in
                if result.isSuccess {
                    self.clientGuidIsMigrated = true
                    return succeed()
                } else {
                    if let error = result.failureValue {
                        self.logger.log("Unable to delete records from client engine",
                                        level: .debug,
                                        category: .sync)
                        return deferMaybe(error as MaybeErrorType)
                    } else {
                        self.logger.log("Unable to delete records from client engine with unknown error",
                                        level: .debug,
                                        category: .sync)
                        return deferMaybe(UnknownError() as MaybeErrorType)
                    }
                }
            }
        }
        return succeed()
    }

    public static func resetClientsWithStorage(_ storage: ResettableSyncStorage, basePrefs: Prefs) -> Success {
        let clientPrefs = BaseCollectionSynchronizer.prefsForCollection("clients", withBasePrefs: basePrefs)
        clientPrefs.removeObjectForKey("lastFetched")
        return storage.resetClient()
    }
}
