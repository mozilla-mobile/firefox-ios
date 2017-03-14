/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred

open class MockLogins: BrowserLogins, SyncableLogins {
    fileprivate var cache = [Login]()

    public init(files: FileAccessor) {
    }

    open func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace) -> Deferred<Maybe<Cursor<LoginData>>> {
        let cursor = ArrayCursor(data: cache.filter({ login in
            return login.protectionSpace.host == protectionSpace.host
        }).sorted(by: { (loginA, loginB) -> Bool in
            return loginA.timeLastUsed > loginB.timeLastUsed
        }).map({ login in
            return login as LoginData
        }))
        return Deferred(value: Maybe(success: cursor))
    }

    open func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace, withUsername username: String?) -> Deferred<Maybe<Cursor<LoginData>>> {
        let cursor = ArrayCursor(data: cache.filter({ login in
            return login.protectionSpace.host == protectionSpace.host &&
                   login.username == username
        }).sorted(by: { (loginA, loginB) -> Bool in
            return loginA.timeLastUsed > loginB.timeLastUsed
        }).map({ login in
            return login as LoginData
        }))
        return Deferred(value: Maybe(success: cursor))
    }

    open func getLoginDataForGUID(_ guid: GUID) -> Deferred<Maybe<Login>> {
        if let login = (cache.filter { $0.guid == guid }).first {
            return deferMaybe(login)
        } else {
            return deferMaybe(LoginDataError(description: "Login for GUID \(guid) not found"))
        }
    }

    open func getAllLogins() -> Deferred<Maybe<Cursor<Login>>> {
        let cursor = ArrayCursor(data: cache.sorted(by: { (loginA, loginB) -> Bool in
            return loginA.hostname > loginB.hostname
        }))
        return Deferred(value: Maybe(success: cursor))
    }

    open func searchLoginsWithQuery(_ query: String?) -> Deferred<Maybe<Cursor<Login>>> {
        let cursor = ArrayCursor(data: cache.filter({ login in
            var checks = [Bool]()
            if let query = query {
                checks.append(login.username?.contains(query) ?? false)
                checks.append(login.password.contains(query))
                checks.append(login.hostname.contains(query))
            }
            return checks.contains(true)
        }).sorted(by: { (loginA, loginB) -> Bool in
            return loginA.hostname > loginB.hostname
        }))
        return Deferred(value: Maybe(success: cursor))
    }

    // This method is only here for testing
    open func getUsageDataForLoginByGUID(_ guid: GUID) -> Deferred<Maybe<LoginUsageData>> {
        let res = cache.filter({ login in
            return login.guid == guid
        }).sorted(by: { (loginA, loginB) -> Bool in
            return loginA.timeLastUsed > loginB.timeLastUsed
        })[0] as LoginUsageData

        return Deferred(value: Maybe(success: res))
    }

    open func addLogin(_ login: LoginData) -> Success {
        if let _ = cache.index(of: login as! Login) {
            return deferMaybe(LoginDataError(description: "Already in the cache"))
        }
        cache.append(login as! Login)
        return succeed()
    }

    open func updateLoginByGUID(_ guid: GUID, new: LoginData, significant: Bool) -> Success {
        // TODO
        return succeed()
    }

    open func getModifiedLoginsToUpload() -> Deferred<Maybe<[Login]>> {
        // TODO
        return deferMaybe([])
    }

    open func getDeletedLoginsToUpload() -> Deferred<Maybe<[GUID]>> {
        // TODO
        return deferMaybe([])
    }

    open func updateLogin(_ login: LoginData) -> Success {
        if let index = cache.index(of: login as! Login) {
            cache[index].timePasswordChanged = Date.nowMicroseconds()
            return succeed()
        }
        return deferMaybe(LoginDataError(description: "Password wasn't cached yet. Can't update"))
    }

    open func addUseOfLoginByGUID(_ guid: GUID) -> Success {
        if let login = cache.filter({ $0.guid == guid }).first {
            login.timeLastUsed = Date.nowMicroseconds()
            return succeed()
        }
        return deferMaybe(LoginDataError(description: "Password wasn't cached yet. Can't update"))
    }

    open func removeLoginByGUID(_ guid: GUID) -> Success {
        let filtered = cache.filter { $0.guid != guid }
        if filtered.count == cache.count {
            return deferMaybe(LoginDataError(description: "Can not remove a password that wasn't stored"))
        }
        cache = filtered
        return succeed()
    }

    open func removeLoginsWithGUIDs(_ guids: [GUID]) -> Success {
        return walk(guids) { guid in
            self.removeLoginByGUID(guid)
        }
    }

    open func removeAll() -> Success {
        cache.removeAll(keepingCapacity: false)
        return succeed()
    }

    open func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }

    // TODO
    open func deleteByGUID(_ guid: GUID, deletedAt: Timestamp) -> Success { return succeed() }
    open func applyChangedLogin(_ upstream: ServerLogin) -> Success { return succeed() }
    open func markAsSynchronized<T: Collection>(_: T, modified: Timestamp) -> Deferred<Maybe<Timestamp>> where T.Iterator.Element == GUID { return deferMaybe(0) }
    open func markAsDeleted<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID { return succeed() }
    open func onRemovedAccount() -> Success { return succeed() }
}

extension MockLogins: ResettableSyncStorage {
    public func resetClient() -> Success {
        return succeed()
    }
}
