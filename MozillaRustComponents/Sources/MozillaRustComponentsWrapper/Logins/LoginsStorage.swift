/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Glean
import UIKit

typealias LoginsStoreError = LoginsApiError

/*
 ** We probably should have this class go away eventually as it's really only a thin wrapper
 * similar to its kotlin equivalents, however the only thing preventing this from being removed is
 * the queue.sync which we should be moved over to the consumer side of things
 */
open class LoginsStorage {
    private var store: LoginStore
    private let queue = DispatchQueue(label: "com.mozilla.logins-storage")

    public init(databasePath: String, keyManager: KeyManager) throws {
        store = try LoginStore(path: databasePath, encdec: createManagedEncdec(keyManager: keyManager))
    }

    open func wipeLocal() throws {
        try queue.sync {
            try self.store.wipeLocal()
        }
    }

    /// Delete the record with the given ID. Returns false if no such record existed.
    open func delete(id: String) throws -> Bool {
        return try queue.sync {
            try self.store.delete(id: id)
        }
    }

    /// Locally delete records from the store that cannot be decrypted. For exclusive
    /// use in the iOS logins verification process.
    open func deleteUndecryptableRecordsForRemoteReplacement() throws {
        return try queue.sync {
            let result = try self.store.deleteUndecryptableRecordsForRemoteReplacement()

            if result.localDeleted > 0 {
                GleanMetrics.LoginsStore.localUndecryptableDeleted.add(Int32(result.localDeleted))
            }

            if result.mirrorDeleted > 0 {
                GleanMetrics.LoginsStore.mirrorUndecryptableDeleted.add(Int32(result.mirrorDeleted))
            }
        }
    }

    /// Bump the usage count for the record with the given id.
    ///
    /// Throws `LoginStoreError.NoSuchRecord` if there was no such record.
    open func touch(id: String) throws {
        try queue.sync {
            try self.store.touch(id: id)
        }
    }

    /// Insert `login` into the database. If `login.id` is not empty,
    /// then this throws `LoginStoreError.DuplicateGuid` if there is a collision
    ///
    /// Returns the `id` of the newly inserted record.
    open func add(login: LoginEntry) throws -> Login {
        return try queue.sync {
            try self.store.add(login: login)
        }
    }

    /// Update `login` in the database. If `login.id` does not refer to a known
    /// login, then this throws `LoginStoreError.NoSuchRecord`.
    open func update(id: String, login: LoginEntry) throws -> Login {
        return try queue.sync {
            try self.store.update(id: id, login: login)
        }
    }

    /// Get the record with the given id. Returns nil if there is no such record.
    open func get(id: String) throws -> Login? {
        return try queue.sync {
            try self.store.get(id: id)
        }
    }

    /// Check whether the database is empty.
    open func isEmpty() throws -> Bool {
        return try queue.sync {
            try self.store.isEmpty()
        }
    }

    /// Get the entire list of records.
    open func list() throws -> [Login] {
        return try queue.sync {
            try self.store.list()
        }
    }

    /// Check whether logins exist for some base domain.
    open func hasLoginsByBaseDomain(baseDomain: String) throws -> Bool {
        return try queue.sync {
            try self.store.hasLoginsByBaseDomain(baseDomain: baseDomain)
        }
    }

    /// Get the list of records for some base domain.
    open func getByBaseDomain(baseDomain: String) throws -> [Login] {
        return try queue.sync {
            try self.store.getByBaseDomain(baseDomain: baseDomain)
        }
    }

    /// Register with the sync manager
    open func registerWithSyncManager() {
        return queue.sync {
            self.store.registerWithSyncManager()
        }
    }
}
