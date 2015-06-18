/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger

private let log = XCGLogger.defaultInstance()
private let PasswordsStorageVersion = 1

private func makeDeletedLoginRecord(guid: GUID) -> Record<LoginPayload> {
    // Local modified time is ignored in upload serialization.
    let modified: Timestamp = 0
    let sortindex = 5_000_000

    let json: JSON = JSON([
        "id": guid,
        "deleted": true,
        ])
    let payload = LoginPayload(json)
    return Record<LoginPayload>(id: guid, payload: payload, modified: modified, sortindex: sortindex)
}

/**
 * Our current local terminology ("logins") has diverged from the terminology in
 * use when Sync was built ("passwords"). I've done my best to draw a sane line
 * between the server collection/record format/etc. and local stuff.
 */
public class LoginsSynchronizer: IndependentRecordSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "passwords")
    }

    override var storageVersion: Int {
        return PasswordsStorageVersion
    }

    func getLogin(record: Record<LoginPayload>) -> Login {
        let guid = record.id
        let payload = record.payload
        let modified = record.modified

        let login = Login(guid: guid, hostname: payload.hostname, username: payload.username, password: payload.password)
        login.formSubmitURL = payload.formSubmitURL
        login.httpRealm = payload.httpRealm
        login.usernameField = payload.usernameField
        login.passwordField = payload.passwordField
        login.timeCreated = 0               // TODO
        login.timeLastUsed = 0              // TODO
        login.timePasswordChanged = 0       // TODO

        return login
    }

    func applyIncomingToStorage(storage: SyncableLogins, records: [Record<LoginPayload>], fetched: Timestamp) -> Success {
        return self.applyIncomingToStorage(records, fetched: fetched) { rec in
            let guid = rec.id
            let payload = rec.payload
            let modified = rec.modified

            // We apply deletions immediately. That might not be exactly what we want -- perhaps you changed
            // a password locally after deleting it remotely -- but it's expedient.
            if payload.deleted {
                return storage.deleteByGUID(guid, deletedAt: modified)
            }

            return storage.applyChangedLogin(self.getLogin(rec), timestamp: modified)
        }
    }

    // TODO
    func upload() {
        // Find any records for which a local overlay exists. If we want to be really precise,
        // we can find the original server modified time for each record and use it as
        // If-Unmodified-Since on a PUT, or just use the last fetch timestamp, which should
        // be equivalent.
        // New local items might have no GUID (decide!), so assign one if necessary.
        // We will already have reconciled any conflicts on download, so this upload phase should
        // be as simple as uploading any changed or deleted items.
    }

    public func synchronizeLocalLogins(logins: SyncableLogins, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> SyncResult {
        if let reason = self.reasonToNotSync(storageClient) {
            return deferResult(.NotStarted(reason))
        }

        let encoder = RecordEncoder<LoginPayload>(decode: { LoginPayload($0) }, encode: { $0 })
        if let passwordsClient = self.collectionClient(encoder, storageClient: storageClient) {
            let since: Timestamp = self.lastFetched
            log.debug("Synchronizing \(self.collection). Last fetched: \(since).")

            let applyIncomingToStorage: StorageResponse<[Record<LoginPayload>]> -> Success = { response in
                let ts = response.metadata.timestampMilliseconds
                let lm = response.metadata.lastModifiedMilliseconds!
                log.debug("Applying incoming password records from response timestamped \(ts), last modified \(lm).")
                log.debug("Records header hint: \(response.metadata.records)")
                return self.applyIncomingToStorage(logins, records: response.value, fetched: lm)
            }
            return passwordsClient.getSince(since)
                >>== applyIncomingToStorage
                // TODO: upload
                >>> { return deferResult(.Completed) }
        }

        log.error("Couldn't make logins factory.")
        return deferResult(FatalError(message: "Couldn't make logins factory."))
    }
}
