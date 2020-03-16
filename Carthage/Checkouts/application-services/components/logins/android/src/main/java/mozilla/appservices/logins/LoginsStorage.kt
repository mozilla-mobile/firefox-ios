/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.logins
import mozilla.appservices.sync15.SyncTelemetryPing
import org.json.JSONObject

class SyncUnlockInfo(
    val kid: String,
    val fxaAccessToken: String,
    val syncKey: String,
    val tokenserverURL: String
)

interface LoginsStorage : AutoCloseable {
    /**
     * Lock (close) the database.
     *
     * @throws [MismatchedLockException] if the database is already locked
     */
    @Throws(LoginsStorageException::class)
    fun lock()

    /**
     * Unlock (open) the database.
     *
     * @throws [MismatchedLockException] if the database is already unlocked
     * @throws [InvalidKeyException] if the encryption key is wrong, or the db is corrupt
     * @throws [LoginsStorageException] if there was some other error opening the database
     */
    @Throws(LoginsStorageException::class)
    fun unlock(encryptionKey: String)

    /**
     * Unlock (open) the database, using a byte string as the key.
     * This is equivalent to calling unlock() after hex-encoding the bytes (lower
     * case hexadecimal characters are used).
     *
     * @throws [MismatchedLockException] if the database is already unlocked
     * @throws [InvalidKeyException] if the encryption key is wrong, or the db is corrupt
     * @throws [LoginsStorageException] if there was some other error opening the database
     */
    @Throws(LoginsStorageException::class)
    fun unlock(encryptionKey: ByteArray)

    /**
     * Returns true if the database is locked, false otherwise.
     */
    fun isLocked(): Boolean

    /**
     * Equivalent to `unlock(encryptionKey)`, but does not throw in the case
     * that the database is already unlocked.
     *
     * @throws [InvalidKeyException] if the encryption key is wrong, or the db is corrupt
     * @throws [LoginsStorageException] if there was some other error opening the database
     */
    @Throws(LoginsStorageException::class)
    fun ensureUnlocked(encryptionKey: String)

    /**
     * Equivalent to `unlock(encryptionKey)`, but does not throw in the case
     * that the database is already unlocked.
     *
     * @throws [InvalidKeyException] if the encryption key is wrong, or the db is corrupt
     * @throws [LoginsStorageException] if there was some other error opening the database
     */
    @Throws(LoginsStorageException::class)
    fun ensureUnlocked(encryptionKey: ByteArray)

    /**
     * Equivalent to `lock()`, but does not throw in the case that
     * the database is already unlocked. Never throws.
     */
    fun ensureLocked()

    /**
     * Synchronize the logins storage layer with a remote layer.
     *
     * @throws [SyncAuthInvalidException] if authentication needs to be refreshed
     * @throws [RequestFailedException] if there was a network error during connection.
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    fun sync(syncInfo: SyncUnlockInfo): SyncTelemetryPing

    /**
     * Delete all locally stored login sync metadata (last sync timestamps, etc).
     *
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    @Deprecated("Most uses should be replaced with wipe or wipeLocal instead")
    fun reset()

    /**
     * Delete all login records. These deletions will be synced to the server on the next call to sync.
     *
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    fun wipe()

    /**
     * Clear out all local state, bringing us back to the state before the first sync.
     *
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    fun wipeLocal()

    /**
     * Deletes the password with the given ID.
     *
     * Returns true if the deletion did anything, false if no such record exists.
     *
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    fun delete(id: String): Boolean

    /**
     * Fetch a password from the underlying storage layer by ID.
     *
     * Returns `null` if the record does not exist.
     *
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    fun get(id: String): ServerPassword?

    /**
     * Mark the login with the given ID as `in-use`.
     *
     * @throws [NoSuchRecordException] If the record with that ID does not exist.
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    fun touch(id: String)

    /**
     * Fetch the full list of passwords from the underlying storage layer.
     *
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    fun list(): List<ServerPassword>

    /**
     * Fetch the list of passwords for some base domain from the underlying storage layer.
     *
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    fun getByBaseDomain(baseDomain: String): List<ServerPassword>

    /**
     * Inserts the provided login into the database, returning its id.
     *
     * This function ignores values in metadata fields (`timesUsed`,
     * `timeCreated`, `timeLastUsed`, and `timePasswordChanged`).
     *
     * If login has an empty id field, then a GUID will be
     * generated automatically. The format of generated guids
     * are left up to the implementation of LoginsStorage (in
     * practice the [DatabaseLoginsStorage] generates 12-character
     * base64url (RFC 4648) encoded strings, and [MemoryLoginsStorage]
     * generates strings using [java.util.UUID.toString])
     *
     * This will return an error result if a GUID is provided but
     * collides with an existing record, or if the provided record
     * is invalid (missing password, hostname, or doesn't have exactly
     * one of formSubmitURL and httpRealm).
     *
     * @throws [IdCollisionException] if a nonempty id is provided, and
     * @throws [InvalidRecordException] if the record is invalid.
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    fun add(login: ServerPassword): String

    /**
     * Imports provided logins into the database.
     * GUIDs are thrown away and replaced by auto-generated ones from the crate.
     *
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    fun importLogins(logins: Array<ServerPassword>): JSONObject

    /**
     * Updates the fields in the provided record.
     *
     * This will return an error if `login.id` does not refer to
     * a record that exists in the database, or if the provided record
     * is invalid (missing password, hostname, or doesn't have exactly
     * one of formSubmitURL and httpRealm).
     *
     * Like `add`, this function will ignore values in metadata
     * fields (`timesUsed`, `timeCreated`, `timeLastUsed`, and
     * `timePasswordChanged`).
     *
     * @throws [NoSuchRecordException] if the login does not exist.
     * @throws [InvalidRecordException] if the update would create an invalid record.
     * @throws [LoginsStorageException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(LoginsStorageException::class)
    fun update(login: ServerPassword)

    /**
     * Return the raw handle used to reference this logins database.
     *
     * This is only valid for the DatabaseLoginsStorage, and was added to this
     * interface regardless by popular demand. Other types will throw an
     * UnsupportedOperationException.
     *
     * Generally should only be used to pass the handle into `SyncManager.setLogins`.
     *
     * Note: handles do not remain valid after locking / unlocking the logins database.
     */
    fun getHandle(): Long

    /**
     * Checks if login already exists and is valid. Throws a [InvalidRecordException] if it is not.
     *
     * ```
     * try {
     *     db.ensureValid(record)
     * } catch (e: InvalidRecordException) {
     *     // The reason the record is invalid is stored in `e.reason`.
     * }
     * ```
     *
     * @throws [InvalidRecordException] On unexpected errors (IO failure, rust panics, etc)
     */
    @Throws(InvalidRecordException::class)
    fun ensureValid(login: ServerPassword)

    /**
     * Change the key on an existing encrypted database.
     */
    @Throws(LoginsStorageException::class)
    fun rekeyDatabase(newEncryptionKey: String)

    /**
     * Change the key on an existing encrypted database.
     */
    @Throws(LoginsStorageException::class)
    fun rekeyDatabase(newEncryptionKey: ByteArray)
}
