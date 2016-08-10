/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import Deferred

private let log = Logger.syncLogger
let PasswordsStorageVersion = 1

private func makeDeletedLoginRecord(guid: GUID) -> Record<LoginPayload> {
    // Local modified time is ignored in upload serialization.
    let modified: Timestamp = 0

    // Arbitrary large number: deletions sync down first.
    let sortindex = 5_000_000

    let json: JSON = JSON([
        "id": guid,
        "deleted": true,
        ])
    let payload = LoginPayload(json)
    return Record<LoginPayload>(id: guid, payload: payload, modified: modified, sortindex: sortindex)
}

func makeLoginRecord(login: Login) -> Record<LoginPayload> {
    let id = login.guid
    let modified: Timestamp = 0    // Ignored in upload serialization.
    let sortindex = 1

    let tLU = NSNumber(unsignedLongLong: login.timeLastUsed / 1000)
    let tPC = NSNumber(unsignedLongLong: login.timePasswordChanged / 1000)
    let tC = NSNumber(unsignedLongLong: login.timeCreated / 1000)

    let dict: [String: AnyObject] = [
        "id": id,
        "hostname": login.hostname,
        "httpRealm": login.httpRealm ?? JSON.null,
        "formSubmitURL": login.formSubmitURL ?? JSON.null,
        "username": login.username ?? "",
        "password": login.password,
        "usernameField": login.usernameField ?? "",
        "passwordField": login.passwordField ?? "",
        "timesUsed": login.timesUsed,
        "timeLastUsed": tLU,
        "timePasswordChanged": tPC,
        "timeCreated": tC,
    ]

    let payload = LoginPayload(JSON(dict))
    return Record<LoginPayload>(id: id, payload: payload, modified: modified, sortindex: sortindex)
}

/**
 * Our current local terminology ("logins") has diverged from the terminology in
 * use when Sync was built ("passwords"). I've done my best to draw a reasonable line
 * between the server collection/record format/etc. and local stuff: local storage
 * works with logins, server records and collection are passwords.
 */
public class LoginsSynchronizer: IndependentRecordSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "passwords")
    }

    override var storageVersion: Int {
        return PasswordsStorageVersion
    }

    func getLogin(record: Record<LoginPayload>) -> ServerLogin {
        let guid = record.id
        let payload = record.payload
        let modified = record.modified

        let login = ServerLogin(guid: guid, hostname: payload.hostname, username: payload.username, password: payload.password, modified: modified)
        login.formSubmitURL = payload.formSubmitURL
        login.httpRealm = payload.httpRealm
        login.usernameField = payload.usernameField
        login.passwordField = payload.passwordField

        // Microseconds locally, milliseconds remotely. We should clean this up.
        login.timeCreated = 1000 * (payload.timeCreated ?? 0)
        login.timeLastUsed = 1000 * (payload.timeLastUsed ?? 0)
        login.timePasswordChanged = 1000 * (payload.timePasswordChanged ?? 0)
        login.timesUsed = payload.timesUsed ?? 0
        return login
    }

    func applyIncomingToStorage(storage: SyncableLogins, records: [Record<LoginPayload>], fetched: Timestamp) -> Success {
        return self.applyIncomingToStorage(records, fetched: fetched) { rec in
            let guid = rec.id
            let payload = rec.payload

            guard payload.isValid() else {
                log.warning("Login record \(guid) is invalid. Skipping.")
                return succeed()
            }

            // We apply deletions immediately. That might not be exactly what we want -- perhaps you changed
            // a password locally after deleting it remotely -- but it's expedient.
            if payload.deleted {
                return storage.deleteByGUID(guid, deletedAt: rec.modified)
            }

            return storage.applyChangedLogin(self.getLogin(rec))
        }
    }

    private func uploadChangedRecords<T>(deleted: [GUID], modified: [GUID], records: [Record<T>], lastTimestamp: Timestamp,
                                      storage: SyncableLogins, withServer storageClient: Sync15CollectionClient<T>) -> Success {
        let onUpload: (POSTResult) -> DeferredTimestamp = { result in
            let uploaded = result.success

            // Figure out which ones the server deleted and which ones were modified
            let guidsDeleted = deleted.filter(uploaded.contains)
            let guidsModified = modified.filter(uploaded.contains)

            return storage.markAsDeleted(guidsDeleted) >>> { storage.markAsSynchronized(guidsModified, modified: result.modified) }
        }

        return uploadRecordsInChunks(records,
                                     lastTimestamp: lastTimestamp,
                                     storageClient: storageClient,
                                     onUpload: onUpload) >>> effect({ log.debug("Done syncing.") })
    }

    // Find any records for which a local overlay exists. If we want to be really precise,
    // we can find the original server modified time for each record and use it as
    // If-Unmodified-Since on a PUT, or just use the last fetch timestamp, which should
    // be equivalent.
    // We will already have reconciled any conflicts on download, so this upload phase should
    // be as simple as uploading any changed or deleted items.
    private func uploadOutgoingFromStorage(storage: SyncableLogins, lastTimestamp: Timestamp, withServer storageClient: Sync15CollectionClient<LoginPayload>) -> Success {
        let deleted: () -> Deferred<Maybe<([GUID], [Record<LoginPayload>])>> = {
            return storage.getDeletedLoginsToUpload() >>== { guids in
                let records = guids.map(makeDeletedLoginRecord)
                return deferMaybe((guids, records))
            }
        }

        let modified: () -> Deferred<Maybe<([GUID], [Record<LoginPayload>])>> = {
            return storage.getModifiedLoginsToUpload() >>== { logins in
                let guids = logins.map { $0.guid }
                let records = logins.map(makeLoginRecord)
                return deferMaybe((guids, records))
            }
        }

        return accumulate([deleted, modified]) >>== { result in
            let (deletedGUIDs, deletedRecords) = result[0]
            let (modifiedGUIDs, modifiedRecords) = result[1]
            let allRecords = deletedRecords + modifiedRecords

            return self.uploadChangedRecords(deletedGUIDs, modified: modifiedGUIDs, records: allRecords,
                                             lastTimestamp: lastTimestamp, storage: storage, withServer: storageClient)
        }
    }

    public func synchronizeLocalLogins(logins: SyncableLogins, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> SyncResult {
        if let reason = self.reasonToNotSync(storageClient) {
            return deferMaybe(.NotStarted(reason))
        }

        let encoder = RecordEncoder<LoginPayload>(decode: { LoginPayload($0) }, encode: { $0 })
        guard let passwordsClient = self.collectionClient(encoder, storageClient: storageClient) else {
            log.error("Couldn't make logins factory.")
            return deferMaybe(FatalError(message: "Couldn't make logins factory."))
        }

        let since: Timestamp = self.lastFetched
        log.debug("Synchronizing \(self.collection). Last fetched: \(since).")

        let applyIncomingToStorage: StorageResponse<[Record<LoginPayload>]> -> Success = { response in
            let ts = response.metadata.timestampMilliseconds
            let lm = response.metadata.lastModifiedMilliseconds!
            log.debug("Applying incoming password records from response timestamped \(ts), last modified \(lm).")
            log.debug("Records header hint: \(response.metadata.records)")
            return self.applyIncomingToStorage(logins, records: response.value, fetched: lm) >>> effect {
                NSNotificationCenter.defaultCenter().postNotificationName(NotificationDataRemoteLoginChangesWereApplied, object: nil)
            }
        }
        return passwordsClient.getSince(since)
            >>== applyIncomingToStorage
            // TODO: If we fetch sorted by date, we can bump the lastFetched timestamp
            // to the last successfully applied record timestamp, no matter where we fail.
            // There's no need to do the upload before bumping -- the storage of local changes is stable.
            >>> { self.uploadOutgoingFromStorage(logins, lastTimestamp: 0, withServer: passwordsClient) }
            >>> { return deferMaybe(.Completed) }
    }
}
