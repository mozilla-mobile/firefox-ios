/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public class MockLogins: Logins {
    private var cache = [Login]()

    public init(files: FileAccessor) {
    }

    public func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace) -> Deferred<Result<Cursor<LoginData>>> {
        let cursor = ArrayCursor(data: cache.filter({ login in
            return login.protectionSpace.host == protectionSpace.host
        }).sorted({ (loginA, loginB) -> Bool in
            return loginA.timeLastUsed > loginB.timeLastUsed
        }).map({ login in
            return login as LoginData
        }))
        return Deferred(value: Result(success: cursor))
    }

    // This method is only here for testing
    public func getUsageDataForLogin(login: LoginData) -> Deferred<Result<LoginUsageData>> {
        let res = cache.filter({ login in
            return login.protectionSpace.host == login.hostname
        }).sorted({ (loginA, loginB) -> Bool in
            return loginA.timeLastUsed > loginB.timeLastUsed
        })[0] as LoginUsageData

        return Deferred(value: Result(success: res))
    }

    public func addLogin(login: LoginData) -> Success {
        if let index = find(cache, login as! Login) {
            return deferResult(LoginDataError(description: "Already in the cache"))
        }
        cache.append(login as! Login)
        return succeed()
    }

    public func updateLogin(login: LoginData) -> Success {
        if let index = find(cache, login as! Login) {
            cache[index].timePasswordChanged = NSDate.nowMicroseconds()
            return succeed()
        }
        return deferResult(LoginDataError(description: "Password wasn't cached yet. Can't update"))
    }

    public func addUseOf(login: LoginData) -> Success {
        if let index = find(cache, login as! Login) {
            cache[index].timeLastUsed = NSDate.nowMicroseconds()
            return succeed()
        }
        return deferResult(LoginDataError(description: "Password wasn't cached yet. Can't update"))
    }

    public func removeLogin(login: LoginData) -> Success {
        if let index = find(cache, login as! Login) {
            cache.removeAtIndex(index)
            return succeed()
        }
        return deferResult(LoginDataError(description: "Can not remove a password that wasn't stored"))
    }

    public func removeAll() -> Success {
        cache.removeAll(keepCapacity: false)
        return succeed()
    }
}