/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = Logger.syncLogger
let PasswordsStorageVersion = 1

private func makeDeletedLoginRecord(_ guid: GUID) -> Record<LoginPayload> {
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

func makeLoginRecord(_ login: Login) -> Record<LoginPayload> {
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

    func getLogin(_ record: Record<LoginPayload>) -> ServerLogin {
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

    func applyIncomingToStorage(_ storage: SyncableLogins, records: [Record<LoginPayload>], fetched: Timestamp) -> Success {
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
                return storage.delete(byGUID: guid, deletedAt: rec.modified)
            }

            return storage.applyChangedLogin(self.getLogin(rec))
        }
    }

    private func uploadModifiedLogins(_ logins: [Login], lastTimestamp: Timestamp, fromStorage storage: SyncableLogins, withServer storageClient: Sync15CollectionClient<LoginPayload>) -> DeferredTimestamp {
        return self.uploadRecords(logins.map(makeLoginRecord), by: 50, lastTimestamp: lastTimestamp, storageClient: storageClient) {
            storage.markAsSynchronized($0.success, modified: $0.modified)
        }
    }

    private func uploadDeletedLogins(_ guids: [GUID], lastTimestamp: Timestamp, fromStorage storage: SyncableLogins, withServer storageClient: Sync15CollectionClient<LoginPayload>) -> DeferredTimestamp {

        let records = guids.map(makeDeletedLoginRecord)

        // Deletions are smaller, so upload 100 at a time.
        return self.uploadRecords(records, by: 100, lastTimestamp: lastTimestamp, storageClient: storageClient) {
            storage.markAsDeleted($0.success) >>> always($0.modified)
        }
    }

    // Find any records for which a local overlay exists. If we want to be really precise,
    // we can find the original server modified time for each record and use it as
    // If-Unmodified-Since on a PUT, or just use the last fetch timestamp, which should
    // be equivalent.
    // We will already have reconciled any conflicts on download, so this upload phase should
    // be as simple as uploading any changed or deleted items.
    private func uploadOutgoingFromStorage(_ storage: SyncableLogins, lastTimestamp: Timestamp, withServer storageClient: Sync15CollectionClient<LoginPayload>) -> Success {

        let uploadDeleted: (Timestamp) -> DeferredTimestamp = { timestamp in
            storage.getDeletedLoginsToUpload()
                >>== { guids in
                    return self.uploadDeletedLogins(guids, lastTimestamp: timestamp, fromStorage: storage, withServer: storageClient)
            }
        }

        let uploadModified: (Timestamp) -> DeferredTimestamp = { timestamp in
            storage.getModifiedLoginsToUpload()
                >>== { logins in
                    return self.uploadModifiedLogins(logins, lastTimestamp: timestamp, fromStorage: storage, withServer: storageClient)
            }
        }

        return deferMaybe(lastTimestamp)
            >>== uploadDeleted
            >>== uploadModified
            >>> effect({ log.debug("Done syncing.") })
            >>> succeed
    }

    public func synchronizeLocalLogins(_ logins: SyncableLogins, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> SyncResult {
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

        let applyIncomingToStorage: (StorageResponse<[Record<LoginPayload>]>) -> Success = { response in
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
