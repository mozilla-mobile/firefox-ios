/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred
import Logins

public class RustLogins {
    let databasePath: String
    let encryptionKey: String

    let queue: DispatchQueue
    let storage: LoginsStorage

    public init(databasePath: String, encryptionKey: String) {
        self.databasePath = databasePath
        self.encryptionKey = encryptionKey

        self.queue =  DispatchQueue(label: "RustLogins queue: \(databasePath)", attributes: [])
        self.storage = LoginsStorage(databasePath: databasePath)
        do {
            try self.storage.unlock(withEncryptionKey: encryptionKey)
        } catch let err {
            print(err)
        }
    }

    public func sync(unlockInfo: SyncUnlockInfo) -> Success {
        //return succeed() // TEMP: Don't let this Sync yet
        let deferred = Success()

        queue.async {
            do {
                try self.storage.sync(unlockInfo: unlockInfo)
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func getLoginDataForGUID(_ guid: GUID) -> Deferred<Maybe<Login>> {
        return get(id: guid).bind({ result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            if let successValue = result.successValue, let record = successValue {
                let login = Login(guid: record.id, hostname: record.hostname, username: record.username ?? "", password: record.password)
                return deferMaybe(login)
            }

            return deferMaybe(LoginDataError(description: "Login not found for GUID \(guid)"))
        })
    }

    public func get(id: String) -> Deferred<Maybe<LoginRecord?>> {
        let deferred = Deferred<Maybe<LoginRecord?>>()

        queue.async {
            do {
                let record = try self.storage.get(id: id)
                if record?.formSubmitURL?.isEmpty ?? false {
                    record?.formSubmitURL = nil
                }
                if record?.httpRealm?.isEmpty ?? false {
                    record?.httpRealm = nil
                }
                deferred.fill(Maybe(success: record))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func searchLoginsWithQuery(_ query: String?) -> Deferred<Maybe<Cursor<Login>>> {
        return list().bind({ result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            guard let records = result.successValue else {
                return deferMaybe(ArrayCursor(data: []))
            }

            guard let query = query, !query.isEmpty else {
                let logins = records.map({ Login(guid: $0.id, hostname: $0.hostname, username: $0.username ?? "", password: $0.password )})
                return deferMaybe(ArrayCursor(data: logins))
            }

            let filteredRecords = records.filter({
                $0.hostname.contains(query) ||
                ($0.username ?? "").contains(query) ||
                $0.password.contains(query)
            })
            let filteredLogins = filteredRecords.map({ Login(guid: $0.id, hostname: $0.hostname, username: $0.username ?? "", password: $0.password )})
            return deferMaybe(ArrayCursor(data: filteredLogins))
        })
    }

    public func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace, withUsername username: String? = nil) -> Deferred<Maybe<Cursor<LoginData>>> {
        return list().bind({ result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            guard let records = result.successValue else {
                return deferMaybe(ArrayCursor(data: []))
            }

            let filteredRecords: [LoginRecord]
            if let username = username {
                filteredRecords = records.filter({
                    $0.username == username && (
                        $0.hostname == protectionSpace.urlString() ||
                        $0.hostname == protectionSpace.host
                    )
                })
            } else {
                filteredRecords = records.filter({
                    $0.hostname == protectionSpace.urlString() ||
                    $0.hostname == protectionSpace.host
                })
            }
            let filteredLogins = filteredRecords.map({ Login(guid: $0.id, hostname: $0.hostname, username: $0.username ?? "", password: $0.password )})
            return deferMaybe(ArrayCursor(data: filteredLogins))
        })
    }

    public func hasSyncedLogins() -> Deferred<Maybe<Bool>> {
        return list().bind({ result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            return deferMaybe((result.successValue?.count ?? 0) > 0)
        })
    }

    public func list() -> Deferred<Maybe<[LoginRecord]>> {
        let deferred = Deferred<Maybe<[LoginRecord]>>()

        queue.async {
            do {
                let records = try self.storage.list()
                deferred.fill(Maybe(success: records))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func addLogin(_ login: LoginData) -> Success {
        let record = loginRecord(from: login)

        return add(login: record).bind({ result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            return succeed()
        })
    }

    public func add(login: LoginRecord) -> Deferred<Maybe<String>> {
        let deferred = Deferred<Maybe<String>>()

        queue.async {
            do {
                let id = try self.storage.add(login: login)
                deferred.fill(Maybe(success: id))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func updateLoginByGUID(_ guid: GUID, new: LoginData) -> Success {
        let record = loginRecord(from: new)
        record.id = guid

        return update(login: record)
    }

    public func addUseOfLoginByGUID(_ guid: GUID) -> Success {
        return get(id: guid).bind({ result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            guard let successValue = result.successValue, let record = successValue else {
                return deferMaybe(LoginDataError(description: "Login not found for GUID \(guid)"))
            }

            record.timesUsed += 1
            record.timeLastUsed = Int64(Date.nowMicroseconds())

            return self.update(login: record)
        })
    }

    public func update(login: LoginRecord) -> Success {
        let deferred = Success()

        queue.async {
            do {
                try self.storage.update(login: login)
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func removeLoginByGUID(_ guid: GUID) -> Success {
        return delete(id: guid).bind({ result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            return succeed()
        })
    }

    public func removeLoginsWithGUIDs(_ guids: [GUID]) -> Success {
        return all(guids.map({ removeLoginByGUID($0) })).bind({ _ in
            return succeed()
        })
    }

    public func delete(id: String) -> Deferred<Maybe<Bool>> {
        let deferred = Deferred<Maybe<Bool>>()

        queue.async {
            do {
                let existed = try self.storage.delete(id: id)
                deferred.fill(Maybe(success: existed))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    public func reset() -> Success {
        let deferred = Success()

        queue.async {
            do {
                try self.storage.reset()
                deferred.fill(Maybe(success: ()))
            } catch let err as NSError {
                deferred.fill(Maybe(failure: err))
            }
        }

        return deferred
    }

    private func loginRecord(from loginData: LoginData) -> LoginRecord {
        let record = LoginRecord(fromJSONDict: loginData.toDict())

        if record.httpRealm?.isEmpty ?? false {
            record.httpRealm = nil
        }
        if record.formSubmitURL?.isEmpty ?? false {
            record.formSubmitURL = nil
        }

        return record
    }
}
