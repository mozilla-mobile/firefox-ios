/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = Logger.syncLogger

let TableLoginsMirror = "loginsM"
let TableLoginsLocal = "loginsL"
let AllLoginTables: [String] = [TableLoginsMirror, TableLoginsLocal]


private class LoginsTable: Table {
    var name: String { return "LOGINS" }
    var version: Int { return 2 }

    func run(db: SQLiteDBConnection, sql: String, args: Args? = nil) -> Bool {
        let err = db.executeChange(sql, withArgs: args)
        if err != nil {
            log.error("Error running SQL in LoginsTable. \(err?.localizedDescription)")
            log.error("SQL was \(sql)")
        }
        return err == nil
    }

    // TODO: transaction.
    func run(db: SQLiteDBConnection, queries: [String]) -> Bool {
        for sql in queries {
            if !run(db, sql: sql, args: nil) {
                return false
            }
        }
        return true
    }

    func create(db: SQLiteDBConnection) -> Bool {
        let common =
        "id INTEGER PRIMARY KEY AUTOINCREMENT" +
        ", hostname TEXT NOT NULL" +
        ", httpRealm TEXT" +
        ", formSubmitURL TEXT" +
        ", usernameField TEXT" +
        ", passwordField TEXT" +
        ", timesUsed INTEGER NOT NULL DEFAULT 0" +
        ", timeCreated INTEGER NOT NULL" +
        ", timeLastUsed INTEGER" +
        ", timePasswordChanged INTEGER NOT NULL" +
        ", username TEXT" +
        ", password TEXT NOT NULL"

        let mirror = "CREATE TABLE IF NOT EXISTS \(TableLoginsMirror) (" +
            common +
            ", guid TEXT NOT NULL UNIQUE" +
            ", server_modified INTEGER NOT NULL" +              // Integer milliseconds.
            ", is_overridden TINYINT NOT NULL DEFAULT 0" +
        ")"

        let local = "CREATE TABLE IF NOT EXISTS \(TableLoginsLocal) (" +
            common +
            ", guid TEXT NOT NULL UNIQUE " +                  // Typically overlaps one in the mirror unless locally new.
            ", local_modified INTEGER" +                      // Can be null. Client clock. In extremis only.
            ", is_deleted TINYINT NOT NULL DEFAULT 0" +       // Boolean. Locally deleted.
            ", sync_status TINYINT " +                        // SyncStatus enum. Set when changed or created.
            "NOT NULL DEFAULT \(SyncStatus.Synced.rawValue)" +
        ")"

        return self.run(db, queries: [mirror, local])
    }

    func updateTable(db: SQLiteDBConnection, from: Int) -> Bool {
        let to = self.version
        if from == to {
            log.debug("Skipping update from \(from) to \(to).")
            return true
        }

        if from == 0 {
            // This is likely an upgrade from before Bug 1160399.
            log.debug("Updating logins tables from zero. Assuming drop and recreate.")
            return drop(db) && create(db)
        }

        // TODO: real update!
        log.debug("Updating logins table from \(from) to \(to).")
        return drop(db) && create(db)
    }

    func exists(db: SQLiteDBConnection) -> Bool {
        return db.tablesExist(AllLoginTables)
    }

    func drop(db: SQLiteDBConnection) -> Bool {
        log.debug("Dropping logins table.")
        let err = db.executeChange("DROP TABLE IF EXISTS \(name)", withArgs: nil)
        return err == nil
    }

}

public class SQLiteLogins: BrowserLogins {

    private let db: BrowserDB
    private static let MainColumns = "guid, username, password, hostname, httpRealm, formSubmitURL, usernameField, passwordField"
    private static let MainWithLastUsedColumns = MainColumns + ", timeLastUsed, timesUsed"
    private static let LoginColumns = MainColumns + ", timeCreated, timeLastUsed, timePasswordChanged, timesUsed"

    public init(db: BrowserDB) {
        self.db = db
        db.createOrUpdate(LoginsTable())
    }

    private class func populateLogin(login: Login, row: SDRow) {
        login.formSubmitURL = row["formSubmitURL"] as? String
        login.usernameField = row["usernameField"] as? String
        login.passwordField = row["passwordField"] as? String
        login.guid = row["guid"] as! String

        if let timeCreated = row.getTimestamp("timeCreated"),
            let timeLastUsed = row.getTimestamp("timeLastUsed"),
            let timePasswordChanged = row.getTimestamp("timePasswordChanged"),
            let timesUsed = row["timesUsed"] as? Int {
                login.timeCreated = timeCreated
                login.timeLastUsed = timeLastUsed
                login.timePasswordChanged = timePasswordChanged
                login.timesUsed = timesUsed
        }
    }

    private class func constructLogin<T: Login>(row: SDRow, c: T.Type) -> T {
        let credential = NSURLCredential(user: row["username"] as? String ?? "",
            password: row["password"] as! String,
            persistence: NSURLCredentialPersistence.None)
        let protectionSpace = NSURLProtectionSpace(host: row["hostname"] as! String,
            port: 0,
            `protocol`: nil,
            realm: row["httpRealm"] as? String,
            authenticationMethod: nil)

        let login = T(credential: credential, protectionSpace: protectionSpace)
        self.populateLogin(login, row: row)
        return login
    }

    class func LocalLoginFactory(row: SDRow) -> LocalLogin {
        let login = self.constructLogin(row, c: LocalLogin.self)

        login.localModified = row.getTimestamp("local_modified")!
        login.isDeleted = row.getBoolean("is_deleted")
        login.syncStatus = SyncStatus(rawValue: row["sync_status"] as! Int)!

        return login
    }

    class func MirrorLoginFactory(row: SDRow) -> MirrorLogin {
        let login = self.constructLogin(row, c: MirrorLogin.self)

        login.serverModified = row.getTimestamp("server_modified")!
        login.isOverridden = row.getBoolean("is_overridden")

        return login
    }

    private class func LoginFactory(row: SDRow) -> Login {
        return self.constructLogin(row, c: Login.self)
    }

    private class func LoginDataFactory(row: SDRow) -> LoginData {
        return LoginFactory(row) as LoginData
    }

    private class func LoginUsageDataFactory(row: SDRow) -> LoginUsageData {
        return LoginFactory(row) as LoginUsageData
    }

    func notifyLoginDidChange() {
        log.debug("Notifying login did change.")

        // For now we don't care about the contents.
        // This posts immediately to the shared notification center.
        let notification = NSNotification(name: NotificationDataLoginDidChange, object: nil)
        NSNotificationCenter.defaultCenter().postNotification(notification)
    }

    public func getUsageDataForLoginByGUID(guid: GUID) -> Deferred<Maybe<LoginUsageData>> {
        let projection = SQLiteLogins.LoginColumns
        let sql =
        "SELECT \(projection) FROM " +
        "\(TableLoginsLocal) WHERE is_deleted = 0 AND guid = ? " +
        "UNION ALL " +
        "SELECT \(projection) FROM " +
        "\(TableLoginsMirror) WHERE is_overridden = 0 AND guid = ? " +
        "LIMIT 1"

        let args: Args = [guid, guid]
        return db.runQuery(sql, args: args, factory: SQLiteLogins.LoginUsageDataFactory)
            >>== { value in
            deferMaybe(value[0]!)
        }
    }

    public func getLoginDataForGUID(guid: GUID) -> Deferred<Maybe<LoginData>> {
        let projection = SQLiteLogins.MainWithLastUsedColumns
        let sql =
        "SELECT \(projection) FROM " +
            "\(TableLoginsLocal) WHERE is_deleted = 0 AND guid = ? " +
            "UNION ALL " +
            "SELECT \(projection) FROM " +
            "\(TableLoginsMirror) WHERE guid = ? " +
        "ORDER BY hostname ASC " +
        "LIMIT 1"

        let args: Args = [guid, guid]
        return db.runQuery(sql, args: args, factory: SQLiteLogins.LoginDataFactory)
            >>== { value in
            if let login = value[0] {
                return deferMaybe(login)
            } else {
                return deferMaybe(LoginDataError(description: "Login not found for GUID \(guid)"))
            }
        }
    }

    public func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace) -> Deferred<Maybe<Cursor<LoginData>>> {
        let projection = SQLiteLogins.MainWithLastUsedColumns

        let sql =
        "SELECT \(projection) FROM " +
        "\(TableLoginsLocal) WHERE is_deleted = 0 AND hostname IS ? " +
        "UNION ALL " +
        "SELECT \(projection) FROM " +
        "\(TableLoginsMirror) WHERE is_overridden = 0 AND hostname IS ? " +
        "ORDER BY timeLastUsed DESC"

        let args: Args = [protectionSpace.host, protectionSpace.host]
        if Logger.logPII {
            log.debug("Looking for login: \(protectionSpace.host)")
        }
        return db.runQuery(sql, args: args, factory: SQLiteLogins.LoginDataFactory)
    }

    // username is really Either<String, NULL>; we explicitly match no username.
    public func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace, withUsername username: String?) -> Deferred<Maybe<Cursor<LoginData>>> {
        let projection = SQLiteLogins.MainWithLastUsedColumns

        let args: Args
        let usernameMatch: String
        if let username = username {
            args = [protectionSpace.host, username, protectionSpace.host, username]
            usernameMatch = "username = ?"
        } else {
            args = [protectionSpace.host, protectionSpace.host]
            usernameMatch = "username IS NULL"
        }

        if Logger.logPII {
            log.debug("Looking for login: \(username), \(args[0])")
        }

        let sql =
        "SELECT \(projection) FROM " +
        "\(TableLoginsLocal) WHERE is_deleted = 0 AND hostname IS ? AND \(usernameMatch) " +
        "UNION ALL " +
        "SELECT \(projection) FROM " +
        "\(TableLoginsMirror) WHERE is_overridden = 0 AND hostname IS ? AND username IS ? " +
        "ORDER BY timeLastUsed DESC"

        return db.runQuery(sql, args: args, factory: SQLiteLogins.LoginDataFactory)
    }

    public func getAllLogins() -> Deferred<Maybe<Cursor<LoginData>>> {
        return searchLoginsWithQuery(nil)
    }

    public func searchLoginsWithQuery(query: String?) -> Deferred<Maybe<Cursor<LoginData>>> {
        let projection = SQLiteLogins.MainWithLastUsedColumns
        var searchClauses = [String]()
        var args: Args? = nil
        if let query = query {
            // Add wildcards to change query to 'contains in' and add them to args. We need 6 args because
            // we include the where clause twice: Once for the local table and another for the remote.
            args = (0..<6).map { _ in
                return "%\(query)%" as String?
            }

            searchClauses.append(" username LIKE ? ")
            searchClauses.append(" password LIKE ? ")
            searchClauses.append(" hostname LIKE ? ")
        }

        let whereSearchClause = searchClauses.count > 0 ? "AND" + searchClauses.joinWithSeparator("OR") : ""
        let sql =
        "SELECT \(projection) FROM " +
            "\(TableLoginsLocal) WHERE is_deleted = 0 " + whereSearchClause +
            "UNION ALL " +
            "SELECT \(projection) FROM " +
            "\(TableLoginsMirror) WHERE is_overridden = 0 " + whereSearchClause +
        "ORDER BY hostname ASC"

        return db.runQuery(sql, args: args, factory: SQLiteLogins.LoginDataFactory)
    }

    public func addLogin(login: LoginData) -> Success {
        let nowMicro = NSDate.nowMicroseconds()
        let nowMilli = nowMicro / 1000
        let dateMicro = NSNumber(unsignedLongLong: nowMicro)
        let dateMilli = NSNumber(unsignedLongLong: nowMilli)

        let args: Args = [
            login.hostname,
            login.httpRealm,
            login.formSubmitURL,
            login.usernameField,
            login.passwordField,
            login.username,
            login.password,
            login.guid,
            dateMicro,            // timeCreated
            dateMicro,            // timeLastUsed
            dateMicro,            // timePasswordChanged
            dateMilli,            // localModified
        ]

        let sql =
        "INSERT OR IGNORE INTO \(TableLoginsLocal) " +
        // Shared fields.
        "( hostname" +
        ", httpRealm" +
        ", formSubmitURL" +
        ", usernameField" +
        ", passwordField" +
        ", timesUsed" +
        ", username" +
        ", password " +
        // Local metadata.
        ", guid " +
        ", timeCreated" +
        ", timeLastUsed" +
        ", timePasswordChanged" +
        ", local_modified " +
        ", is_deleted " +
        ", sync_status " +
        ") " +
        "VALUES (?,?,?,?,?,1,?,?,?,?,?, " +
        "?, ?, 0, \(SyncStatus.New.rawValue)" +         // Metadata.
        ")"

        return db.run(sql, withArgs: args)
                >>> effect(self.notifyLoginDidChange)
    }

    private func cloneMirrorToOverlay(whereClause whereClause: String?, args: Args?) -> Deferred<Maybe<Int>> {
        let shared =
        "guid " +
        ", hostname" +
        ", httpRealm" +
        ", formSubmitURL" +
        ", usernameField" +
        ", passwordField" +
        ", timeCreated" +
        ", timeLastUsed" +
        ", timePasswordChanged" +
        ", timesUsed" +
        ", username" +
        ", password "

        let local =
        ", local_modified " +
        ", is_deleted " +
        ", sync_status "

        let sql = "INSERT OR IGNORE INTO \(TableLoginsLocal) " +
        "(\(shared)\(local)) " +
        "SELECT \(shared), NULL AS local_modified, 0 AS is_deleted, 0 AS sync_status " +
        "FROM \(TableLoginsMirror) " +
        (whereClause ?? "")

        return self.db.write(sql, withArgs: args)
    }

    /**
     * Returns success if either a local row already existed, or
     * one could be copied from the mirror.
     */
    private func ensureLocalOverlayExistsForGUID(guid: GUID) -> Success {
        let sql = "SELECT guid FROM \(TableLoginsLocal) WHERE guid = ?"
        let args: Args = [guid]
        let c = db.runQuery(sql, args: args, factory: { row in 1 })

        return c >>== { rows in
            if rows.count > 0 {
                return succeed()
            }
            log.debug("No overlay; cloning one for GUID \(guid).")
            return self.cloneMirrorToOverlay(guid)
                >>== { count in
                    if count > 0 {
                        return succeed()
                    }
                    log.warning("Failed to create local overlay for GUID \(guid).")
                    return deferMaybe(NoSuchRecordError(guid: guid))
            }
        }
    }

    private func cloneMirrorToOverlay(guid: GUID) -> Deferred<Maybe<Int>> {
        let whereClause = "WHERE guid = ?"
        let args: Args = [guid]

        return self.cloneMirrorToOverlay(whereClause: whereClause, args: args)
    }

    private func markMirrorAsOverridden(guid: GUID) -> Success {
        let args: Args = [guid]
        let sql =
        "UPDATE \(TableLoginsMirror) SET " +
        "is_overridden = 1 " +
        "WHERE guid = ?"

        return self.db.run(sql, withArgs: args)
    }

    /**
     * Replace the local DB row with the provided GUID.
     * If no local overlay exists, one is first created.
     *
     * If `significant` is `true`, the `sync_status` of the row is bumped to at least `Changed`.
     * If it's already `New`, it remains marked as `New`.
     *
     * This flag allows callers to make minor changes (such as incrementing a usage count)
     * without triggering an upload or a conflict.
     */
    public func updateLoginByGUID(guid: GUID, new: LoginData, significant: Bool) -> Success {
        // Right now this method is only ever called if the password changes at
        // point of use, so we always set `timePasswordChanged` and `timeLastUsed`.
        // We can (but don't) also assume that `significant` will always be `true`,
        // at least for the time being.
        let nowMicro = NSDate.nowMicroseconds()
        let nowMilli = nowMicro / 1000
        let dateMicro = NSNumber(unsignedLongLong: nowMicro)
        let dateMilli = NSNumber(unsignedLongLong: nowMilli)

        let args: Args = [
            dateMilli,            // local_modified
            dateMicro,            // timeLastUsed
            dateMicro,            // timePasswordChanged
            new.httpRealm,
            new.formSubmitURL,
            new.usernameField,
            new.passwordField,
            new.password,
            new.hostname,
            new.username,
            guid,
        ]

        let update =
        "UPDATE \(TableLoginsLocal) SET " +
        "  local_modified = ?, timeLastUsed = ?, timePasswordChanged = ?" +
        ", httpRealm = ?, formSubmitURL = ?, usernameField = ?" +
        ", passwordField = ?, timesUsed = timesUsed + 1" +
        ", password = ?, hostname = ?, username = ?" +

        // We keep rows marked as New in preference to marking them as changed. This allows us to
        // delete them immediately if they don't reach the server.
        (significant ? ", sync_status = max(sync_status, 1) " : "") +
        " WHERE guid = ?"

        return self.ensureLocalOverlayExistsForGUID(guid)
           >>> { self.markMirrorAsOverridden(guid) }
           >>> { self.db.run(update, withArgs: args) }
            >>> effect(self.notifyLoginDidChange)
    }

    public func addUseOfLoginByGUID(guid: GUID) -> Success {
        let sql =
        "UPDATE \(TableLoginsLocal) SET " +
        "timesUsed = timesUsed + 1, timeLastUsed = ?, local_modified = ? " +
        "WHERE guid = ? AND is_deleted = 0"

        // For now, mere use is not enough to flip sync_status to Changed.

        let nowMicro = NSDate.nowMicroseconds()
        let nowMilli = nowMicro / 1000
        let args: Args = [NSNumber(unsignedLongLong: nowMicro), NSNumber(unsignedLongLong: nowMilli), guid]

        return self.ensureLocalOverlayExistsForGUID(guid)
           >>> { self.markMirrorAsOverridden(guid) }
           >>> { self.db.run(sql, withArgs: args) }
    }

    public func removeLoginByGUID(guid: GUID) -> Success {
        return removeLoginsWithGUIDs([guid])
    }

    public func removeLoginsWithGUIDs(guids: [GUID]) -> Success {
        if guids.isEmpty {
            return succeed()
        }

        let nowMillis = NSDate.now()
        let inClause = BrowserDB.varlist(guids.count)

        // Immediately delete anything that's marked as new -- i.e., it's never reached
        // the server.
        let delete =
        "DELETE FROM \(TableLoginsLocal) WHERE guid IN \(inClause) AND sync_status = \(SyncStatus.New.rawValue)"

        // Otherwise, mark it as changed.
        let update =
        "UPDATE \(TableLoginsLocal) SET " +
        " local_modified = \(nowMillis)" +
        ", sync_status = \(SyncStatus.Changed.rawValue)" +
        ", is_deleted = 1" +
        ", password = ''" +
        ", hostname = ''" +
        ", username = ''" +
        " WHERE guid IN \(inClause)"

       let markMirrorAsOverridden =
        "UPDATE \(TableLoginsMirror) SET " +
            "is_overridden = 1 " +
            "WHERE guid IN \(inClause)"

        let insert =
        "INSERT OR IGNORE INTO \(TableLoginsLocal) " +
            "(guid, local_modified, is_deleted, sync_status, hostname, timeCreated, timePasswordChanged, password, username) " +
        "SELECT guid, \(nowMillis), 1, \(SyncStatus.Changed.rawValue), '', timeCreated, \(nowMillis)000, '', '' FROM \(TableLoginsMirror) WHERE guid IN \(inClause)"

        let args: Args = guids.map { $0 as AnyObject }
        return self.db.run([
            (delete, args),
            (update, args),
            (markMirrorAsOverridden, args),
            (insert, args)
        ]) >>> effect(self.notifyLoginDidChange)
    }

    public func removeAll() -> Success {
        // Immediately delete anything that's marked as new -- i.e., it's never reached
        // the server. If Sync isn't set up, this will be everything.
        let delete =
        "DELETE FROM \(TableLoginsLocal) WHERE sync_status = \(SyncStatus.New.rawValue)"

        let nowMillis = NSDate.now()

        // Mark anything we haven't already deleted.
        let update =
        "UPDATE \(TableLoginsLocal) SET local_modified = \(nowMillis), sync_status = \(SyncStatus.Changed.rawValue), is_deleted = 1, password = '', hostname = '', username = '' WHERE is_deleted = 0"

        // Copy all the remaining rows from our mirror, marking them as locally deleted. The
        // OR IGNORE will cause conflicts due to non-unique guids to be dropped, preserving
        // anything we already deleted.
        let insert =
        "INSERT OR IGNORE INTO \(TableLoginsLocal) (guid, local_modified, is_deleted, sync_status, hostname, timeCreated, timePasswordChanged, password, username) " +
        "SELECT guid, \(nowMillis), 1, \(SyncStatus.Changed.rawValue), '', timeCreated, \(nowMillis)000, '', '' FROM \(TableLoginsMirror)"

        // After that, we mark all of the mirror rows as overridden.
        return self.db.run(delete)
           >>> { self.db.run(update) }
           >>> { self.db.run("UPDATE \(TableLoginsMirror) SET is_overridden = 1") }
           >>> { self.db.run(insert) }
            >>> effect(self.notifyLoginDidChange)
    }
}

// When a server change is detected (e.g., syncID changes), we should consider shifting the contents
// of the mirror into the local overlay, allowing a content-based reconciliation to occur on the next
// full sync. Or we could flag the mirror as to-clear, download the server records and un-clear, and
// resolve the remainder on completion. This assumes that a fresh start will typically end up with
// the exact same records, so we might as well keep the shared parents around and double-check.
extension SQLiteLogins: SyncableLogins {
    /**
     * Delete the login with the provided GUID. Succeeds if the GUID is unknown.
     */
    public func deleteByGUID(guid: GUID, deletedAt: Timestamp) -> Success {
        // Simply ignore the possibility of a conflicting local change for now.
        let local = "DELETE FROM \(TableLoginsLocal) WHERE guid = ?"
        let remote = "DELETE FROM \(TableLoginsMirror) WHERE guid = ?"
        let args: Args = [guid]

        return self.db.run(local, withArgs: args) >>> { self.db.run(remote, withArgs: args) }
    }

    func getExistingMirrorRecordByGUID(guid: GUID) -> Deferred<Maybe<MirrorLogin?>> {
        let sql = "SELECT * FROM \(TableLoginsMirror) WHERE guid = ? LIMIT 1"
        let args: Args = [guid]
        return self.db.runQuery(sql, args: args, factory: SQLiteLogins.MirrorLoginFactory) >>== { deferMaybe($0[0]) }
    }

    func getExistingLocalRecordByGUID(guid: GUID) -> Deferred<Maybe<LocalLogin?>> {
        let sql = "SELECT * FROM \(TableLoginsLocal) WHERE guid = ? LIMIT 1"
        let args: Args = [guid]
        return self.db.runQuery(sql, args: args, factory: SQLiteLogins.LocalLoginFactory) >>== { deferMaybe($0[0]) }
    }

    private func storeReconciledLogin(login: Login) -> Success {
        let dateMilli = NSNumber(unsignedLongLong: NSDate.now())

        let args: Args = [
            dateMilli,            // local_modified
            login.httpRealm,
            login.formSubmitURL,
            login.usernameField,
            login.passwordField,
            NSNumber(unsignedLongLong: login.timeLastUsed),
            NSNumber(unsignedLongLong: login.timePasswordChanged),
            login.timesUsed,
            login.password,
            login.hostname,
            login.username,
            login.guid,
        ]

        let update =
        "UPDATE \(TableLoginsLocal) SET " +
            "  local_modified = ?" +
            ", httpRealm = ?, formSubmitURL = ?, usernameField = ?" +
            ", passwordField = ?, timeLastUsed = ?, timePasswordChanged = ?, timesUsed = ?" +
            ", password = ?" +
            ", hostname = ?, username = ?" +
            ", sync_status = \(SyncStatus.Changed.rawValue) " +
        " WHERE guid = ?"

        return self.db.run(update, withArgs: args)
    }

    public func applyChangedLogin(upstream: ServerLogin) -> Success {
        // Our login storage tracks the shared parent from the last sync (the "mirror").
        // This allows us to conclusively determine what changed in the case of conflict.
        //
        // Our first step is to determine whether the record is changed or new: i.e., whether
        // or not it's present in the mirror.
        //
        // TODO: these steps can be done in a single query. Make it work, make it right, make it fast.
        // TODO: if there's no mirror record, all incoming records can be applied in one go; the only
        // reason we need to fetch first is to establish the shared parent. That would be nice.
        let guid = upstream.guid
        return self.getExistingMirrorRecordByGUID(guid) >>== { mirror in
            return self.getExistingLocalRecordByGUID(guid) >>== { local in
                return self.applyChangedLogin(upstream, local: local, mirror: mirror)
            }
        }
    }

    private func applyChangedLogin(upstream: ServerLogin, local: LocalLogin?, mirror: MirrorLogin?) -> Success {
        // Once we have the server record, the mirror record (if any), and the local overlay (if any),
        // we can always know which state a record is in.

        // If it's present in the mirror, then we can proceed directly to handling the change;
        // we assume that once a record makes it into the mirror, that the local record association
        // has already taken place, and we're tracking local changes correctly.
        if let mirror = mirror {
            log.debug("Mirror record found for changed record \(mirror.guid).")
            if let local = local {
                log.debug("Changed local overlay found for \(local.guid). Resolving conflict with 3WM.")
                // * Changed remotely and locally (conflict). Resolve the conflict using a three-way merge: the
                //   local mirror is the shared parent of both the local overlay and the new remote record.
                //   Apply results as in the co-creation case.
                return self.resolveConflictBetween(local: local, upstream: upstream, shared: mirror)
            }

            log.debug("No local overlay found. Updating mirror to upstream.")
            // * Changed remotely but not locally. Apply the remote changes to the mirror.
            //   There is no local overlay to discard or resolve against.
            return self.updateMirrorToLogin(upstream, fromPrevious: mirror)
        }

        // * New both locally and remotely with no shared parent (cocreation).
        //   Or we matched the GUID, and we're assuming we just forgot the mirror.
        //
        //   Merge and apply the results remotely, writing the result into the mirror and discarding the overlay
        //   if the upload succeeded. (Doing it in this order allows us to safely replay on failure.)
        //
        //   If the local and remote record are the same, this is trivial.
        //   At this point we also switch our local GUID to match the remote.
        if let local = local {
            // We might have randomly computed the same GUID on two devices connected
            // to the same Sync account.
            // With our 9-byte GUIDs, the chance of that happening is very small, so we
            // assume that this device has previously connected to this account, and we
            // go right ahead with a merge.
            log.debug("Local record with GUID \(local.guid) but no mirror. This is unusual; assuming disconnect-reconnect scenario. Smushing.")
            return self.resolveConflictWithoutParentBetween(local: local, upstream: upstream)
        }

        // If it's not present, we must first check whether we have a local record that's substantially
        // the same -- the co-creation or re-sync case.
        //
        // In this case, we apply the server record to the mirror, change the local record's GUID,
        // and proceed to reconcile the change on a content basis.
        return self.findLocalRecordByContent(upstream) >>== { local in
            if let local = local {
                log.debug("Local record \(local.guid) content-matches new remote record \(upstream.guid). Smushing.")
                return self.resolveConflictWithoutParentBetween(local: local, upstream: upstream)
            }

            // * New upstream only; no local overlay, content-based merge,
            //   or shared parent in the mirror. Insert it in the mirror.
            log.debug("Never seen remote record \(upstream.guid). Mirroring.")
            return self.insertNewMirror(upstream)
        }
    }

    // N.B., the final guid is sometimes a WHERE and sometimes inserted.
    private func mirrorArgs(login: ServerLogin) -> Args {
        let args: Args = [
            NSNumber(unsignedLongLong: login.serverModified),
            login.httpRealm,
            login.formSubmitURL,
            login.usernameField,
            login.passwordField,
            login.timesUsed,
            NSNumber(unsignedLongLong: login.timeLastUsed),
            NSNumber(unsignedLongLong: login.timePasswordChanged),
            NSNumber(unsignedLongLong: login.timeCreated),
            login.password,
            login.hostname,
            login.username,
            login.guid,
        ]
        return args
    }

    /**
     * Called when we have a changed upstream record and no local changes.
     * There's no need to flip the is_overridden flag.
     */
    private func updateMirrorToLogin(login: ServerLogin, fromPrevious previous: Login) -> Success {
        let args = self.mirrorArgs(login)
        let sql =
        "UPDATE \(TableLoginsMirror) SET " +
        " server_modified = ?" +
        ", httpRealm = ?, formSubmitURL = ?, usernameField = ?" +
        ", passwordField = ?" +

        // These we need to coalesce, because we might be supplying zeroes if the remote has
        // been overwritten by an older client. In this case, preserve the old value in the
        // mirror.
        ", timesUsed = coalesce(nullif(?, 0), timesUsed)" +
        ", timeLastUsed = coalesce(nullif(?, 0), timeLastUsed)" +
        ", timePasswordChanged = coalesce(nullif(?, 0), timePasswordChanged)" +
        ", timeCreated = coalesce(nullif(?, 0), timeCreated)" +
        ", password = ?, hostname = ?, username = ?" +
        " WHERE guid = ?"

        return self.db.run(sql, withArgs: args)
    }

    /**
     * Called when we have a completely new record. Naturally the new record
     * is marked as non-overridden.
     */
    private func insertNewMirror(login: ServerLogin, isOverridden: Int = 0) -> Success {
        let args = self.mirrorArgs(login)
        let sql =
        "INSERT OR IGNORE INTO \(TableLoginsMirror) (" +
            " is_overridden, server_modified" +
            ", httpRealm, formSubmitURL, usernameField" +
            ", passwordField, timesUsed, timeLastUsed, timePasswordChanged, timeCreated" +
            ", password, hostname, username, guid" +
        ") VALUES (\(isOverridden), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

        return self.db.run(sql, withArgs: args)
    }

    /**
     * We assume a local record matches if it has the same username (password can differ),
     * hostname, httpRealm. We also check that the formSubmitURLs are either blank or have the
     * same host and port.
     *
     * This is roughly the same as desktop's .matches():
     * <https://mxr.mozilla.org/mozilla-central/source/toolkit/components/passwordmgr/nsLoginInfo.js#41>
     */
    private func findLocalRecordByContent(login: Login) -> Deferred<Maybe<LocalLogin?>> {
        let primary =
        "SELECT * FROM \(TableLoginsLocal) WHERE " +
        "hostname IS ? AND httpRealm IS ? AND username IS ?"

        var args: Args = [login.hostname, login.httpRealm, login.username]
        let sql: String

        if login.formSubmitURL == nil {
            sql = primary + " AND formSubmitURL IS NULL"
        } else if login.formSubmitURL!.isEmpty {
            sql = primary
        } else {
            if let hostPort = login.formSubmitURL?.asURL?.hostPort {
                // Substring check will suffice for now. TODO: proper host/port check after fetching the cursor.
                sql = primary + " AND (formSubmitURL = '' OR (instr(formSubmitURL, ?) > 0))"
                args.append(hostPort)
            } else {
                log.warning("Incoming formSubmitURL is non-empty but is not a valid URL with a host. Not matching local.")
                return deferMaybe(nil)
            }
        }

        return self.db.runQuery(sql, args: args, factory: SQLiteLogins.LocalLoginFactory)
          >>== { cursor in
            switch (cursor.count) {
            case 0:
                return deferMaybe(nil)
            case 1:
                // Great!
                return deferMaybe(cursor[0])
            default:
                // TODO: join against the mirror table to exclude local logins that
                // already match a server record.
                // Right now just take the first.
                log.warning("Got \(cursor.count) local logins with matching details! This is most unexpected.")
                return deferMaybe(cursor[0])
            }
        }
    }

    private func resolveConflictBetween(local local: LocalLogin, upstream: ServerLogin, shared: Login) -> Success {
        // Attempt to compute two delta sets by comparing each new record to the shared record.
        // Then we can merge the two delta sets -- either perfectly or by picking a winner in the case
        // of a true conflict -- and produce a resultant record.

        let localDeltas = (local.localModified, local.deltas(from: shared))
        let upstreamDeltas = (upstream.serverModified, upstream.deltas(from: shared))

        let mergedDeltas = Login.mergeDeltas(a: localDeltas, b: upstreamDeltas)

        // Not all Sync clients handle the optional timestamp fields introduced in Bug 555755.
        // We might get a server record with no timestamps, and it will differ from the original
        // mirror!
        // We solve that by refusing to generate deltas that discard information. We'll preserve
        // the local values -- either from the local record or from the last shared parent that
        // still included them -- and propagate them back to the server.
        // It's OK for us to reconcile and reupload; it causes extra work for every client, but
        // should not cause looping.
        let resultant = shared.applyDeltas(mergedDeltas)

        // We can immediately write the downloaded upstream record -- the old one -- to
        // the mirror store.
        // We then apply this record to the local store, and mark it as needing upload.
        // When the reconciled record is uploaded, it'll be flushed into the mirror
        // with the correct modified time.
        return self.updateMirrorToLogin(upstream, fromPrevious: shared)
            >>> { self.storeReconciledLogin(resultant) }
    }

    private func resolveConflictWithoutParentBetween(local local: LocalLogin, upstream: ServerLogin) -> Success {
        // Do the best we can. Either the local wins and will be
        // uploaded, or the remote wins and we delete our overlay.
        if local.timePasswordChanged > upstream.timePasswordChanged {
            log.debug("Conflicting records with no shared parent. Using newer local record.")
            return self.insertNewMirror(upstream, isOverridden: 1)
        }

        log.debug("Conflicting records with no shared parent. Using newer remote record.")
        let args: Args = [local.guid]
        return self.insertNewMirror(upstream, isOverridden: 0)
            >>> { self.db.run("DELETE FROM \(TableLoginsLocal) WHERE guid = ?", withArgs: args) }
    }

    public func getModifiedLoginsToUpload() -> Deferred<Maybe<[Login]>> {
        let sql =
        "SELECT * FROM \(TableLoginsLocal) " +
        "WHERE sync_status IS NOT \(SyncStatus.Synced.rawValue) AND is_deleted = 0"

        // Swift 2.0: use Cursor.asArray directly.
        return self.db.runQuery(sql, args: nil, factory: SQLiteLogins.LoginFactory)
          >>== { deferMaybe($0.asArray()) }
    }

    public func getDeletedLoginsToUpload() -> Deferred<Maybe<[GUID]>> {
        // There are no logins that are marked as deleted that were not originally synced --
        // others are deleted immediately.
        let sql =
        "SELECT guid FROM \(TableLoginsLocal) " +
        "WHERE is_deleted = 1"

        // Swift 2.0: use Cursor.asArray directly.
        return self.db.runQuery(sql, args: nil, factory: { return $0["guid"] as! GUID })
            >>== { deferMaybe($0.asArray()) }
    }

    /**
     * Chains through the provided timestamp.
     */
    public func markAsSynchronized(guids: [GUID], modified: Timestamp) -> Deferred<Maybe<Timestamp>> {
        // Update the mirror from the local record that we just uploaded.
        // sqlite doesn't support UPDATE FROM, so instead of running 10 subqueries * n GUIDs,
        // we issue a single DELETE and a single INSERT on the mirror, then throw away the
        // local overlay that we just uploaded with another DELETE.
        log.debug("Marking \(guids.count) GUIDs as synchronized.")

        // TODO: transaction!
        let args: Args = guids.map { $0 as AnyObject }
        let inClause = BrowserDB.varlist(args.count)

        let delMirror = "DELETE FROM \(TableLoginsMirror) WHERE guid IN \(inClause)"

        let insMirror =
        "INSERT OR IGNORE INTO \(TableLoginsMirror) (" +
            " is_overridden, server_modified" +
            ", httpRealm, formSubmitURL, usernameField" +
            ", passwordField, timesUsed, timeLastUsed, timePasswordChanged, timeCreated" +
            ", password, hostname, username, guid" +
        ") SELECT 0, \(modified)" +
        ", httpRealm, formSubmitURL, usernameField" +
        ", passwordField, timesUsed, timeLastUsed, timePasswordChanged, timeCreated" +
        ", password, hostname, username, guid " +
        "FROM \(TableLoginsLocal) " +
        "WHERE guid IN \(inClause)"

        let delLocal = "DELETE FROM \(TableLoginsLocal) WHERE guid IN \(inClause)"

        return self.db.run(delMirror, withArgs: args)
         >>> { self.db.run(insMirror, withArgs: args) }
         >>> { self.db.run(delLocal, withArgs: args) }
         >>> always(modified)
    }

    public func markAsDeleted(guids: [GUID]) -> Success {
        log.debug("Marking \(guids.count) GUIDs as deleted.")

        let args: Args = guids.map { $0 as AnyObject }
        let inClause = BrowserDB.varlist(args.count)

        return self.db.run("DELETE FROM \(TableLoginsMirror) WHERE guid IN \(inClause)", withArgs: args)
         >>> { self.db.run("DELETE FROM \(TableLoginsLocal) WHERE guid IN \(inClause)", withArgs: args) }
    }

    public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        let checkLoginsMirror = "SELECT 1 FROM \(TableLoginsMirror)"
        let checkLoginsLocal = "SELECT 1 FROM \(TableLoginsLocal) WHERE sync_status IS NOT \(SyncStatus.New.rawValue)"

        let sql = "\(checkLoginsMirror) UNION ALL \(checkLoginsLocal)"
        return self.db.queryReturnsResults(sql)
    }
}

extension SQLiteLogins: ResettableSyncStorage {
    /**
     * Clean up any metadata.
     * TODO: is this safe for a regular reset? It forces a content-based merge.
     */
    public func resetClient() -> Success {
        // Clone all the mirrors so we don't lose data.
        return self.cloneMirrorToOverlay(whereClause: nil, args: nil)

        // Drop all of the mirror data.
        >>> { self.db.run("DELETE FROM \(TableLoginsMirror)") }

        // Mark all of the local data as new.
        >>> { self.db.run("UPDATE \(TableLoginsLocal) SET sync_status = \(SyncStatus.New.rawValue)") }
    }
}

extension SQLiteLogins: AccountRemovalDelegate {
    public func onRemovedAccount() -> Success {
        return self.resetClient()
    }
}
