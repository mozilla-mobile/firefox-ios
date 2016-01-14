/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public class MockLogins: BrowserLogins, SyncableLogins {
    private var cache = [Login]()

    public init(files: FileAccessor) {
    }

    public func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace) -> Deferred<Maybe<Cursor<LoginData>>> {
        let cursor = ArrayCursor(data: cache.filter({ login in
            return login.protectionSpace.host == protectionSpace.host
        }).sort({ (loginA, loginB) -> Bool in
            return loginA.timeLastUsed > loginB.timeLastUsed
        }).map({ login in
            return login as LoginData
        }))
        return Deferred(value: Maybe(success: cursor))
    }

    public func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace, withUsername username: String?) -> Deferred<Maybe<Cursor<LoginData>>> {
        let cursor = ArrayCursor(data: cache.filter({ login in
            return login.protectionSpace.host == protectionSpace.host &&
                   login.username == username
        }).sort({ (loginA, loginB) -> Bool in
            return loginA.timeLastUsed > loginB.timeLastUsed
        }).map({ login in
            return login as LoginData
        }))
        return Deferred(value: Maybe(success: cursor))
    }

    public func getLoginDataForGUID(guid: GUID) -> Deferred<Maybe<Login>> {
        if let login = (cache.filter { $0.guid == guid }).first {
            return deferMaybe(login)
        } else {
            return deferMaybe(LoginDataError(description: "Login for GUID \(guid) not found"))
        }
    }

    public func getAllLogins() -> Deferred<Maybe<Cursor<Login>>> {
        let cursor = ArrayCursor(data: cache.sort({ (loginA, loginB) -> Bool in
            return loginA.hostname > loginB.hostname
        }))
        return Deferred(value: Maybe(success: cursor))
    }

    public func searchLoginsWithQuery(query: String?) -> Deferred<Maybe<Cursor<Login>>> {
        let cursor = ArrayCursor(data: cache.filter({ login in
            var checks = [Bool]()
            if let query = query {
                checks.append(login.username?.contains(query) ?? false)
                checks.append(login.password.contains(query))
                checks.append(login.hostname.contains(query))
            }
            return checks.contains(true)
        }).sort({ (loginA, loginB) -> Bool in
            return loginA.hostname > loginB.hostname
        }))
        return Deferred(value: Maybe(success: cursor))
    }

    // This method is only here for testing
    public func getUsageDataForLoginByGUID(guid: GUID) -> Deferred<Maybe<LoginUsageData>> {
        let res = cache.filter({ login in
            return login.guid == guid
        }).sort({ (loginA, loginB) -> Bool in
            return loginA.timeLastUsed > loginB.timeLastUsed
        })[0] as LoginUsageData

        return Deferred(value: Maybe(success: res))
    }

    public func addLogin(login: LoginData) -> Success {
        if let _ = cache.indexOf(login as! Login) {
            return deferMaybe(LoginDataError(description: "Already in the cache"))
        }
        cache.append(login as! Login)
        return succeed()
    }

    public func updateLoginByGUID(guid: GUID, new: LoginData, significant: Bool) -> Success {
        // TODO
        return succeed()
    }

    public func getModifiedLoginsToUpload() -> Deferred<Maybe<[Login]>> {
        // TODO
        return deferMaybe([])
    }

    public func getDeletedLoginsToUpload() -> Deferred<Maybe<[GUID]>> {
        // TODO
        return deferMaybe([])
    }

    public func updateLogin(login: LoginData) -> Success {
        if let index = cache.indexOf(login as! Login) {
            cache[index].timePasswordChanged = NSDate.nowMicroseconds()
            return succeed()
        }
        return deferMaybe(LoginDataError(description: "Password wasn't cached yet. Can't update"))
    }

    public func addUseOfLoginByGUID(guid: GUID) -> Success {
        if let login = cache.filter({ $0.guid == guid }).first {
            login.timeLastUsed = NSDate.nowMicroseconds()
            return succeed()
        }
        return deferMaybe(LoginDataError(description: "Password wasn't cached yet. Can't update"))
    }

    public func removeLoginByGUID(guid: GUID) -> Success {
        let filtered = cache.filter { $0.guid != guid }
        if filtered.count == cache.count {
            return deferMaybe(LoginDataError(description: "Can not remove a password that wasn't stored"))
        }
        cache = filtered
        return succeed()
    }

    public func removeLoginsWithGUIDs(guids: [GUID]) -> Success {
        return walk(guids) { guid in
            self.removeLoginByGUID(guid)
        }
    }

    public func removeAll() -> Success {
        cache.removeAll(keepCapacity: false)
        return succeed()
    }

    public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return deferMaybe(true)
    }

    // TODO
    public func deleteByGUID(guid: GUID, deletedAt: Timestamp) -> Success { return succeed() }
    public func applyChangedLogin(upstream: ServerLogin) -> Success { return succeed() }
    public func markAsSynchronized(_: [GUID], modified: Timestamp) -> Deferred<Maybe<Timestamp>> { return deferMaybe(0) }
    public func markAsDeleted(guids: [GUID]) -> Success { return succeed() }
    public func onRemovedAccount() -> Success { return succeed() }
}

extension MockLogins: ResettableSyncStorage {
    public func resetClient() -> Success {
        return succeed()
    }
}