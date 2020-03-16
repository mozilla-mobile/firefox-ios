/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit

open class LoginsStorage {
    private var raw: UInt64 = 0
    let dbPath: String
    private var interruptHandle: LoginsInterruptHandle?
    // It's not 100% clear to me that this is necessary, but without it
    // we might have a data race between reading `interruptHandle` in
    // `interrupt()`, and writing it in `doDestroy` (or `doOpen`)
    private let interruptHandleLock: NSLock = NSLock()
    private let queue = DispatchQueue(label: "com.mozilla.logins-storage")

    public init(databasePath: String) {
        dbPath = databasePath
    }

    deinit {
        self.close()
    }

    /// Returns the number of open LoginsStorage connections.
    public static func numOpenConnections() -> UInt64 {
        // Note: This should only be err if there's a bug in the Rust.
        return try! LoginsStoreError.unwrap { err in
            sync15_passwords_num_open_connections(err)
        }
    }

    private func doDestroy() {
        let raw = self.raw
        self.raw = 0
        if raw != 0 {
            // Is `try!` the right thing to do? We should only hit an error here
            // for panics and handle misuse, both inidicate bugs in our code
            // (the first in the rust code, the 2nd in this swift wrapper).
            try! LoginsStoreError.unwrap { err in
                sync15_passwords_state_destroy(raw, err)
            }
            interruptHandleLock.lock()
            defer { self.interruptHandleLock.unlock() }
            interruptHandle = nil
        }
    }

    /// Manually close the database (this is automatically called from deinit(), so
    /// manually calling it is usually unnecessary).
    open func close() {
        queue.sync {
            self.doDestroy()
        }
    }

    /// Test if the database is locked.
    open func isLocked() -> Bool {
        return queue.sync {
            self.raw == 0
        }
    }

    // helper to reduce boilerplate, we don't use queue.sync
    // since we expect the caller to do so.
    private func getUnlocked() throws -> UInt64 {
        if raw == 0 {
            throw LockError.mismatched
        }
        return raw
    }

    /// Unlock the database and reads the salt.
    ///
    /// Throws `LockError.mismatched` if the database is already unlocked.
    ///
    /// Throws a `LoginStoreError.InvalidKey` if the key is incorrect, or if dbPath does not point
    /// to a database, (may also throw `LoginStoreError.Unspecified` or `.Panic`).
    open func getDbSaltForKey(key: String) throws -> String {
        try queue.sync {
            if self.raw != 0 {
                throw LockError.mismatched
            }
            let ptr = try LoginsStoreError.unwrap { err in
                sync15_passwords_get_db_salt(self.dbPath, key, err)
            }
            return String(freeingRustString: ptr)
        }
    }

    /// Migrate an existing database to a sqlcipher plaintext header.
    /// If your application calls this method without reading and persisting
    /// the salt, the database will be rendered un-usable.
    ///
    /// Throws `LockError.mismatched` if the database is already unlocked.
    ///
    /// Throws a `LoginStoreError.InvalidKey` if the key is incorrect, or if dbPath does not point
    /// to a database, (may also throw `LoginStoreError.Unspecified` or `.Panic`).
    open func migrateToPlaintextHeader(key: String, salt: String) throws {
        try queue.sync {
            if self.raw != 0 {
                throw LockError.mismatched
            }
            try LoginsStoreError.unwrap { err in
                sync15_passwords_migrate_plaintext_header(self.dbPath, key, salt, err)
            }
        }
    }

    private func doOpen(_ key: String, salt: String?) throws {
        if raw != 0 {
            return
        }

        if let salt = salt {
            raw = try LoginsStoreError.unwrap { err in
                sync15_passwords_state_new_with_salt(self.dbPath, key, salt, err)
            }
        } else {
            raw = try LoginsStoreError.unwrap { err in
                sync15_passwords_state_new(self.dbPath, key, err)
            }
        }

        do {
            interruptHandleLock.lock()
            defer { self.interruptHandleLock.unlock() }
            interruptHandle = LoginsInterruptHandle(ptr: try LoginsStoreError.unwrap { err in
                sync15_passwords_new_interrupt_handle(self.raw, err)
            })
        } catch let e {
            // This should only happen on panic, but make sure we don't
            // leak a database in that case.
            self.doDestroy()
            throw e
        }
    }

    /// Unlock the database.
    /// `key` must be a random string.
    /// `salt` must be an hex-encoded string of 32 characters (e.g. `a6a97a03ac3e5a20617175355ea2da5c`).
    ///
    /// Throws `LockError.mismatched` if the database is already unlocked.
    ///
    /// Throws a `LoginStoreError.InvalidKey` if the key is incorrect, or if dbPath does not point
    /// to a database, (may also throw `LoginStoreError.Unspecified` or `.Panic`).
    open func unlockWithKeyAndSalt(key: String, salt: String) throws {
        try queue.sync {
            if self.raw != 0 {
                throw LockError.mismatched
            }
            try self.doOpen(key, salt: salt)
        }
    }

    /// Equivalent to `unlockWithKeyAndSalt(key:, salt:)`, but does not throw if the
    /// database is already unlocked.
    open func ensureUnlockedWithKeyAndSalt(key: String, salt: String) throws {
        try queue.sync {
            try self.doOpen(key, salt: salt)
        }
    }

    /// Unlock the database.
    ///
    /// Throws `LockError.mismatched` if the database is already unlocked.
    ///
    /// Throws a `LoginStoreError.InvalidKey` if the key is incorrect, or if dbPath does not point
    /// to a database, (may also throw `LoginStoreError.Unspecified` or `.Panic`).
    @available(*, deprecated, message: "Use unlockWithKeyAndSalt instead.")
    open func unlock(withEncryptionKey key: String) throws {
        try queue.sync {
            if self.raw != 0 {
                throw LockError.mismatched
            }
            try self.doOpen(key, salt: nil)
        }
    }

    /// equivalent to `unlock(withEncryptionKey:)`, but does not throw if the
    /// database is already unlocked.
    @available(*, deprecated, message: "Use ensureUnlockedWithKeyAndSalt instead.")
    open func ensureUnlocked(withEncryptionKey key: String) throws {
        try queue.sync {
            try self.doOpen(key, salt: nil)
        }
    }

    /// Lock the database.
    ///
    /// Throws `LockError.mismatched` if the database is already locked.
    open func lock() throws {
        try queue.sync {
            if self.raw == 0 {
                throw LockError.mismatched
            }
            self.doDestroy()
        }
    }

    /// Locks the database, but does not throw in the case that the database is
    /// already locked. This is an alias for `close()`, provided for convenience
    /// (and consistency with Android)
    open func ensureLocked() {
        close()
    }

    /// Synchronize with the server. Returns the sync telemetry "ping" as a JSON
    /// string.
    open func sync(unlockInfo: SyncUnlockInfo) throws -> String {
        return try queue.sync {
            let engine = try self.getUnlocked()
            let ptr = try LoginsStoreError.unwrap { err in
                sync15_passwords_sync(engine,
                                      unlockInfo.kid,
                                      unlockInfo.fxaAccessToken,
                                      unlockInfo.syncKey,
                                      unlockInfo.tokenserverURL,
                                      err)
            }
            return String(freeingRustString: ptr)
        }
    }

    /// Delete all locally stored login sync metadata. It's unclear if
    /// there's ever a reason for users to call this
    open func reset() throws {
        try queue.sync {
            let engine = try self.getUnlocked()
            try LoginsStoreError.unwrap { err in
                sync15_passwords_reset(engine, err)
            }
        }
    }

    /// Disable memory security, which prevents keys from being swapped to disk.
    /// This allows some esoteric attacks, but can have a performance benefit.
    open func disableMemSecurity() throws {
        try queue.sync {
            let engine = try self.getUnlocked()
            try LoginsStoreError.unwrap { err in
                sync15_passwords_disable_mem_security(engine, err)
            }
        }
    }

    open func rekeyDatabase(withNewEncryptionKey newKey: String) throws {
        try queue.sync {
            let engine = try self.getUnlocked()
            try LoginsStoreError.unwrap { err in
                sync15_passwords_rekey_database(engine, newKey, err)
            }
        }
    }

    /// Delete all locally stored login data.
    open func wipe() throws {
        try queue.sync {
            let engine = try self.getUnlocked()
            try LoginsStoreError.unwrap { err in
                sync15_passwords_wipe(engine, err)
            }
        }
    }

    open func wipeLocal() throws {
        try queue.sync {
            let engine = try self.getUnlocked()
            try LoginsStoreError.unwrap { err in
                sync15_passwords_wipe_local(engine, err)
            }
        }
    }

    /// Delete the record with the given ID. Returns false if no such record existed.
    open func delete(id: String) throws -> Bool {
        return try queue.sync {
            let engine = try self.getUnlocked()
            let boolAsU8 = try LoginsStoreError.unwrap { err in
                sync15_passwords_delete(engine, id, err)
            }
            return boolAsU8 != 0
        }
    }

    /// Ensure that the record is valid and a duplicate record doesn't exist.
    open func ensureValid(login: LoginRecord) throws {
        let data = try! login.toProtobuf().serializedData()
        let size = Int32(data.count)
        try queue.sync {
            try data.withUnsafeBytes { bytes in
                let engine = try self.getUnlocked()
                try LoginsStoreError.unwrap { err in
                    sync15_passwords_check_valid(engine, bytes.bindMemory(to: UInt8.self).baseAddress!, size, err)
                }
            }
        }
    }

    /// Bump the usage count for the record with the given id.
    ///
    /// Throws `LoginStoreError.NoSuchRecord` if there was no such record.
    open func touch(id: String) throws {
        try queue.sync {
            let engine = try self.getUnlocked()
            try LoginsStoreError.unwrap { err in
                sync15_passwords_touch(engine, id, err)
            }
        }
    }

    /// Insert `login` into the database. If `login.id` is not empty,
    /// then this throws `LoginStoreError.DuplicateGuid` if there is a collision
    ///
    /// Returns the `id` of the newly inserted record.
    open func add(login: LoginRecord) throws -> String {
        let data = try! login.toProtobuf().serializedData()
        let size = Int32(data.count)
        return try queue.sync {
            return try data.withUnsafeBytes { bytes in
                let engine = try self.getUnlocked()
                let ptr = try LoginsStoreError.unwrap { err in
                    sync15_passwords_add(engine, bytes.bindMemory(to: UInt8.self).baseAddress!, size, err)
                }
                return String(freeingRustString: ptr)
            }
        }
    }

    /// Update `login` in the database. If `login.id` does not refer to a known
    /// login, then this throws `LoginStoreError.NoSuchRecord`.
    open func update(login: LoginRecord) throws {
        let data = try! login.toProtobuf().serializedData()
        let size = Int32(data.count)
        try queue.sync {
            try data.withUnsafeBytes { bytes in
                let engine = try self.getUnlocked()
                try LoginsStoreError.unwrap { err in
                    sync15_passwords_update(engine, bytes.bindMemory(to: UInt8.self).baseAddress!, size, err)
                }
            }
        }
    }

    /// Get the record with the given id. Returns nil if there is no such record.
    open func get(id: String) throws -> LoginRecord? {
        return try queue.sync {
            let engine = try self.getUnlocked()
            let buffer = try LoginsStoreError.unwrap { err in
                sync15_passwords_get_by_id(engine, id, err)
            }
            if buffer.data == nil {
                return nil
            }
            defer { sync15_passwords_destroy_buffer(buffer) }
            let msg = try MsgTypes_PasswordInfo(serializedData: Data(loginsRustBuffer: buffer))
            return unpackProtobufInfo(msg: msg)
        }
    }

    /// Get the entire list of records.
    open func list() throws -> [LoginRecord] {
        return try queue.sync {
            let engine = try self.getUnlocked()
            let buffer = try LoginsStoreError.unwrap { err in
                sync15_passwords_get_all(engine, err)
            }
            defer { sync15_passwords_destroy_buffer(buffer) }
            let msgList = try MsgTypes_PasswordInfos(serializedData: Data(loginsRustBuffer: buffer))
            return unpackProtobufInfoList(msgList: msgList)
        }
    }

    /// Get the list of records for some base domain.
    open func getByBaseDomain(baseDomain: String) throws -> [LoginRecord] {
        return try queue.sync {
            let engine = try self.getUnlocked()
            let buffer = try LoginsStoreError.unwrap { err in
                sync15_passwords_get_by_base_domain(engine, baseDomain, err)
            }
            defer { sync15_passwords_destroy_buffer(buffer) }
            let msgList = try MsgTypes_PasswordInfos(serializedData: Data(loginsRustBuffer: buffer))
            return unpackProtobufInfoList(msgList: msgList)
        }
    }

    /// Interrupt a pending operation on another thread, causing it to fail with
    /// `LoginsStoreError.interrupted`.
    ///
    /// This is done on a best-effort basis, and may not work for all APIs, and even
    /// for APIs that support it, it may fail to respect the call to `interrupt()`.
    ///
    /// (In practice, it should, but we might miss it if you call after we "finish" the work).
    ///
    /// Throws: `LoginsStoreError.Panic` if the rust code panics (please report this to us if it happens).
    open func interrupt() throws {
        interruptHandleLock.lock()
        defer { self.interruptHandleLock.unlock() }
        // We don't throw mismatch in the case where `self.interruptHandle` is nil,
        // because that would require users perform external synchronization.
        if let h = interruptHandle {
            try h.interrupt()
        }
    }
}

private class LoginsInterruptHandle {
    let ptr: OpaquePointer
    init(ptr: OpaquePointer) {
        self.ptr = ptr
    }

    deinit {
        sync15_passwords_interrupt_handle_destroy(self.ptr)
    }

    func interrupt() throws {
        try LoginsStoreError.tryUnwrap { error in
            sync15_passwords_interrupt(self.ptr, error)
        }
    }
}
