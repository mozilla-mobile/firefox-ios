/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package mozilla.appservices.logins

import com.sun.jna.Native
import com.sun.jna.Pointer
import mozilla.appservices.logins.rust.PasswordSyncAdapter
import mozilla.appservices.logins.rust.RustError
import mozilla.appservices.support.native.toNioDirectBuffer
import mozilla.appservices.sync15.SyncTelemetryPing
import java.util.concurrent.atomic.AtomicLong
import org.json.JSONObject
import org.mozilla.appservices.logins.GleanMetrics.LoginsStore as LoginsStoreMetrics

/**
 * Import some private Glean types, so that we can use them in type declarations.
 *
 * I do not like importing these private classes, but I do like the nice generic
 * code they allow me to write! By agreement with the Glean team, we must not
 * instantiate anything from these classes, and it's on us to fix any bustage
 * on version updates.
 */
import mozilla.components.service.glean.private.CounterMetricType
import mozilla.components.service.glean.private.TimingDistributionMetricType
import mozilla.components.service.glean.private.LabeledMetricType

/**
 * LoginsStorage implementation backed by a database.
 */
class DatabaseLoginsStorage(private val dbPath: String) : AutoCloseable, LoginsStorage {
    private var raw: AtomicLong = AtomicLong(0)

    override fun isLocked(): Boolean {
        return raw.get() == 0L
    }

    private fun checkUnlocked(): Long {
        val handle = raw.get()
        if (handle == 0L) {
            throw LoginsStorageException("Using DatabaseLoginsStorage without unlocking first")
        }
        return handle
    }

    /**
     * Return the raw handle used to reference this logins database.
     *
     * Generally should only be used to pass the handle into `SyncManager.setLogins`.
     *
     * Note: handles do not remain valid after locking / unlocking the logins database.
     */
    override fun getHandle(): Long {
        return this.raw.get()
    }

    @Synchronized
    @Throws(LoginsStorageException::class)
    override fun lock() {
        val raw = this.raw.getAndSet(0)
        if (raw == 0L) {
            throw MismatchedLockException("Lock called when we are already locked")
        }
        rustCall { error ->
            PasswordSyncAdapter.INSTANCE.sync15_passwords_state_destroy(raw, error)
        }
    }

    @Synchronized
    @Throws(LoginsStorageException::class)
    override fun unlock(encryptionKey: String) {
        return unlockCounters.measure {
            rustCall {
                if (!isLocked()) {
                    throw MismatchedLockException("Unlock called when we are already unlocked")
                }
                LoginsStoreMetrics.unlockTime.measure {
                    raw.set(PasswordSyncAdapter.INSTANCE.sync15_passwords_state_new(
                            dbPath,
                            encryptionKey,
                            it))
                }
            }
        }
    }

    @Synchronized
    @Throws(LoginsStorageException::class)
    override fun unlock(encryptionKey: ByteArray) {
        return unlockCounters.measure {
            rustCall {
                if (!isLocked()) {
                    throw MismatchedLockException("Unlock called when we are already unlocked")
                }
                LoginsStoreMetrics.unlockTime.measure {
                    raw.set(PasswordSyncAdapter.INSTANCE.sync15_passwords_state_new_with_hex_key(
                            dbPath,
                            encryptionKey,
                            encryptionKey.size,
                            it))
                }
            }
        }
    }

    @Synchronized
    @Throws(LoginsStorageException::class)
    override fun ensureUnlocked(encryptionKey: String) {
        if (isLocked()) {
            this.unlock(encryptionKey)
        }
    }

    @Synchronized
    @Throws(LoginsStorageException::class)
    override fun ensureUnlocked(encryptionKey: ByteArray) {
        if (isLocked()) {
            this.unlock(encryptionKey)
        }
    }

    @Synchronized
    override fun ensureLocked() {
        if (!isLocked()) {
            this.lock()
        }
    }

    @Throws(LoginsStorageException::class)
    override fun sync(syncInfo: SyncUnlockInfo): SyncTelemetryPing {
        val json = rustCallWithLock { raw, error ->
            PasswordSyncAdapter.INSTANCE.sync15_passwords_sync(
                    raw,
                    syncInfo.kid,
                    syncInfo.fxaAccessToken,
                    syncInfo.syncKey,
                    syncInfo.tokenserverURL,
                    error
            )?.getAndConsumeRustString()
        }
        return SyncTelemetryPing.fromJSONString(json)
    }

    @Throws(LoginsStorageException::class)
    override fun reset() {
        rustCallWithLock { raw, error ->
            PasswordSyncAdapter.INSTANCE.sync15_passwords_reset(raw, error)
        }
    }

    @Throws(LoginsStorageException::class)
    override fun wipe() {
        rustCallWithLock { raw, error ->
            PasswordSyncAdapter.INSTANCE.sync15_passwords_wipe(raw, error)
        }
    }

    @Throws(LoginsStorageException::class)
    override fun wipeLocal() {
        rustCallWithLock { raw, error ->
            PasswordSyncAdapter.INSTANCE.sync15_passwords_wipe_local(raw, error)
        }
    }

    @Throws(LoginsStorageException::class)
    override fun delete(id: String): Boolean {
        return writeQueryCounters.measure {
            rustCallWithLock { raw, error ->
                val deleted = LoginsStoreMetrics.writeQueryTime.measure {
                    PasswordSyncAdapter.INSTANCE.sync15_passwords_delete(raw, id, error)
                }
                deleted.toInt() != 0
            }
        }
    }

    @Throws(LoginsStorageException::class)
    override fun get(id: String): ServerPassword? {
        return readQueryCounters.measure {
            val rustBuf = rustCallWithLock { raw, error ->
                LoginsStoreMetrics.readQueryTime.measure {
                    PasswordSyncAdapter.INSTANCE.sync15_passwords_get_by_id(raw, id, error)
                }
            }
            try {
                rustBuf.asCodedInputStream()?.let { stream ->
                    ServerPassword.fromMessage(MsgTypes.PasswordInfo.parseFrom(stream))
                }
            } finally {
                PasswordSyncAdapter.INSTANCE.sync15_passwords_destroy_buffer(rustBuf)
            }
        }
    }

    @Throws(LoginsStorageException::class)
    override fun touch(id: String) {
        writeQueryCounters.measure {
            rustCallWithLock { raw, error ->
                LoginsStoreMetrics.writeQueryTime.measure {
                    PasswordSyncAdapter.INSTANCE.sync15_passwords_touch(raw, id, error)
                }
            }
        }
    }

    @Throws(LoginsStorageException::class)
    override fun list(): List<ServerPassword> {
        return readQueryCounters.measure {
            val rustBuf = rustCallWithLock { raw, error ->
                LoginsStoreMetrics.readQueryTime.measure {
                    PasswordSyncAdapter.INSTANCE.sync15_passwords_get_all(raw, error)
                }
            }
            try {
                ServerPassword.fromCollectionMessage(MsgTypes.PasswordInfos.parseFrom(rustBuf.asCodedInputStream()!!))
            } finally {
                PasswordSyncAdapter.INSTANCE.sync15_passwords_destroy_buffer(rustBuf)
            }
        }
    }

    @Throws(LoginsStorageException::class)
    override fun getByBaseDomain(baseDomain: String): List<ServerPassword> {
        return readQueryCounters.measure {
            val rustBuf = rustCallWithLock { raw, error ->
                PasswordSyncAdapter.INSTANCE.sync15_passwords_get_by_base_domain(raw, baseDomain, error)
            }
            try {
                ServerPassword.fromCollectionMessage(MsgTypes.PasswordInfos.parseFrom(rustBuf.asCodedInputStream()!!))
            } finally {
                PasswordSyncAdapter.INSTANCE.sync15_passwords_destroy_buffer(rustBuf)
            }
        }
    }

    @Throws(LoginsStorageException::class)
    override fun add(login: ServerPassword): String {
        return writeQueryCounters.measure {
            val buf = login.toProtobuf()
            val (nioBuf, len) = buf.toNioDirectBuffer()
            rustCallWithLock { raw, error ->
                val ptr = Native.getDirectBufferPointer(nioBuf)
                LoginsStoreMetrics.writeQueryTime.measure {
                    PasswordSyncAdapter.INSTANCE.sync15_passwords_add(raw, ptr, len, error)
                }
            }.getAndConsumeRustString()
        }
    }

    @Throws(LoginsStorageException::class)
    override fun importLogins(logins: Array<ServerPassword>): JSONObject {
        return writeQueryCounters.measure {
            val buf = logins.toCollectionMessage()
            val (nioBuf, len) = buf.toNioDirectBuffer()
            val ptr = Native.getDirectBufferPointer(nioBuf)
            val json = rustCallWithLock { raw, error ->
                PasswordSyncAdapter.INSTANCE.sync15_passwords_import(raw, ptr, len, error)
            }.getAndConsumeRustString()
            JSONObject(json)
        }
    }

    @Throws(LoginsStorageException::class)
    override fun update(login: ServerPassword) {
        return writeQueryCounters.measure {
            val buf = login.toProtobuf()
            val (nioBuf, len) = buf.toNioDirectBuffer()
            rustCallWithLock { raw, error ->
                val ptr = Native.getDirectBufferPointer(nioBuf)
                LoginsStoreMetrics.writeQueryTime.measure {
                    PasswordSyncAdapter.INSTANCE.sync15_passwords_update(raw, ptr, len, error)
                }
            }
        }
    }

    @Throws(InvalidRecordException::class)
    override fun ensureValid(login: ServerPassword) {
        readQueryCounters.measure {
            val buf = login.toProtobuf()
            val (nioBuf, len) = buf.toNioDirectBuffer()
            rustCallWithLock { raw, error ->
                val ptr = Native.getDirectBufferPointer(nioBuf)
                LoginsStoreMetrics.readQueryTime.measure {
                    PasswordSyncAdapter.INSTANCE.sync15_passwords_check_valid(raw, ptr, len, error)
                }
            }
        }
    }

    @Throws(LoginsStorageException::class)
    override fun rekeyDatabase(newEncryptionKey: String) {
        return rustCallWithLock { raw, error ->
            PasswordSyncAdapter.INSTANCE.sync15_passwords_rekey_database(raw, newEncryptionKey, error)
        }
    }

    @Throws(LoginsStorageException::class)
    override fun rekeyDatabase(newEncryptionKey: ByteArray) {
        return rustCallWithLock { raw, error ->
            PasswordSyncAdapter.INSTANCE.sync15_passwords_rekey_database_with_hex_key(
                    raw,
                    newEncryptionKey,
                    newEncryptionKey.size,
                    error)
        }
    }

    @Synchronized
    @Throws(LoginsStorageException::class)
    override fun close() {
        val handle = this.raw.getAndSet(0)
        if (handle != 0L) {
            rustCall { err ->
                PasswordSyncAdapter.INSTANCE.sync15_passwords_state_destroy(handle, err)
            }
        }
    }

    // In practice we usually need to be synchronized to call this safely, so it doesn't
    // synchronize itself
    private inline fun <U> nullableRustCall(callback: (RustError.ByReference) -> U?): U? {
        val e = RustError.ByReference()
        try {
            val ret = callback(e)
            if (e.isFailure()) {
                throw e.intoException()
            }
            return ret
        } finally {
            // This only matters if `callback` throws (or does a non-local return, which
            // we currently don't do)
            e.ensureConsumed()
        }
    }

    private inline fun <U> rustCall(callback: (RustError.ByReference) -> U?): U {
        return nullableRustCall(callback)!!
    }

    private inline fun <U> nullableRustCallWithLock(callback: (Long, RustError.ByReference) -> U?): U? {
        return synchronized(this) {
            val handle = checkUnlocked()
            nullableRustCall { callback(handle, it) }
        }
    }

    private inline fun <U> rustCallWithLock(callback: (Long, RustError.ByReference) -> U?): U {
        return nullableRustCallWithLock(callback)!!
    }

    private val unlockCounters: LoginsStoreCounterMetrics by lazy {
        LoginsStoreCounterMetrics(
            LoginsStoreMetrics.unlockCount,
            LoginsStoreMetrics.unlockErrorCount
        )
    }

    private val readQueryCounters: LoginsStoreCounterMetrics by lazy {
        LoginsStoreCounterMetrics(
            LoginsStoreMetrics.readQueryCount,
            LoginsStoreMetrics.readQueryErrorCount
        )
    }

    private val writeQueryCounters: LoginsStoreCounterMetrics by lazy {
        LoginsStoreCounterMetrics(
            LoginsStoreMetrics.writeQueryCount,
            LoginsStoreMetrics.writeQueryErrorCount
        )
    }
}

/**
 * Helper to read a null terminated String out of the Pointer and free it.
 *
 * Important: Do not use this pointer after this! For anything!
 */
internal fun Pointer.getAndConsumeRustString(): String {
    try {
        return this.getRustString()
    } finally {
        PasswordSyncAdapter.INSTANCE.sync15_passwords_destroy_string(this)
    }
}

/**
 * Helper to read a null terminated string out of the pointer.
 *
 * Important: doesn't free the pointer, use [getAndConsumeRustString] for that!
 */
internal fun Pointer.getRustString(): String {
    return this.getString(0, "utf8")
}

/**
 * A helper extension method for conveniently measuring execution time of a closure.
 *
 * N.B. since we're measuring calls to Rust code here, the provided callback may be doing
 * unsafe things. It's very imporant that we always call the function exactly once here
 * and don't try to do anything tricky like stashing it for later or calling it multiple times.
 */
inline fun <U> TimingDistributionMetricType.measure(funcToMeasure: () -> U): U {
    val timerId = this.start()
    try {
        return funcToMeasure()
    } finally {
        this.stopAndAccumulate(timerId)
    }
}

/**
 * A helper class for gathering basic count metrics on different kinds of LoginsStore operation.
 *
 * For each type of operation, we want to measure:
 *    - total count of operations performed
 *    - count of operations that produced an error, labeled by type
 *
 * This is a convenince wrapper to measure the two in one shot.
 */
class LoginsStoreCounterMetrics(
    val count: CounterMetricType,
    val errCount: LabeledMetricType<CounterMetricType>
) {
    @Suppress("ComplexMethod", "TooGenericExceptionCaught")
    inline fun <U> measure(callback: () -> U): U {
        count.add()
        try {
            return callback()
        } catch (e: Exception) {
            when (e) {
                is NoSuchRecordException -> {
                    errCount["no_such_recod"].add()
                }
                is IdCollisionException -> {
                    errCount["id_collision"].add()
                }
                is InvalidKeyException -> {
                    errCount["invalid_key"].add()
                }
                is InterruptedException -> {
                    errCount["interrupted"].add()
                }
                is InvalidRecordException -> {
                    errCount["invalid_record"].add()
                }
                is LoginsStorageException -> {
                    errCount["storage_error"].add()
                }
                else -> {
                    errCount["__other__"].add()
                }
            }
            throw e
        }
    }
}
