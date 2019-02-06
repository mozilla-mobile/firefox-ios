/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Deferred

@_exported import Logins

public extension LoginRecord {
    public convenience init(credentials: URLCredential, protectionSpace: URLProtectionSpace) {
        let hostname: String
        if let _ = protectionSpace.`protocol` {
            hostname = protectionSpace.urlString()
        } else {
            hostname = protectionSpace.host
        }

        let httpRealm = protectionSpace.realm
        let username = credentials.user
        let password = credentials.password

        self.init(fromJSONDict: [
            "hostname": hostname,
            "httpRealm": httpRealm as Any,
            "username": username ?? "",
            "password": password ?? ""
        ])
    }

    public var credentials: URLCredential {
        return URLCredential(user: username ?? "", password: password, persistence: .none)
    }

    public var protectionSpace: URLProtectionSpace {
        // Break down the full url hostname into its scheme/protocol and host components
        let hostnameURL = hostname.asURL
        let host = hostnameURL?.host ?? hostname
        let scheme = hostnameURL?.scheme ?? ""

        // We should ignore any SSL or normal web ports in the URL.
        var port = hostnameURL?.port ?? 0
        if port == 443 || port == 80 {
            port = 0
        }

        return URLProtectionSpace(host: host, port: port, protocol: scheme, realm: nil, authenticationMethod: nil)
    }

    public var hasMalformedHostname: Bool {
        let hostnameURL = hostname.asURL
        guard let _ = hostnameURL?.host else {
            return true
        }

        return false
    }

    public var isValid: Maybe<()> {
        // Referenced from https://mxr.mozilla.org/mozilla-central/source/toolkit/components/passwordmgr/nsLoginManager.js?rev=f76692f0fcf8&mark=280-281#271

        // Logins with empty hostnames are not valid.
        if hostname.isEmpty {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with an empty hostname."))
        }

        // Logins with empty passwords are not valid.
        if password.isEmpty {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with an empty password."))
        }

        // Logins with both a formSubmitURL and httpRealm are not valid.
        if let _ = formSubmitURL, let _ = httpRealm {
            return Maybe(failure: LoginRecordError(description: "Can't add a login with both a httpRealm and formSubmitURL."))
        }

        // Login must have at least a formSubmitURL or httpRealm.
        if (formSubmitURL == nil) && (httpRealm == nil) {
            return Maybe(failure: LoginRecordError(description: "Can't add a login without a httpRealm or formSubmitURL."))
        }

        // All good.
        return Maybe(success: ())
    }
}

public class LoginRecordError: MaybeErrorType {
    public let description: String
    public init(description: String) {
        self.description = description
    }
}

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

    public func searchLoginsWithQuery(_ query: String?) -> Deferred<Maybe<Cursor<LoginRecord>>> {
        return list().bind({ result in
            if let error = result.failureValue {
                return deferMaybe(error)
            }

            guard let records = result.successValue else {
                return deferMaybe(ArrayCursor(data: []))
            }

            guard let query = query, !query.isEmpty else {
                return deferMaybe(ArrayCursor(data: records))
            }

            let filteredRecords = records.filter({
                $0.hostname.contains(query) ||
                ($0.username ?? "").contains(query) ||
                $0.password.contains(query)
            })
            return deferMaybe(ArrayCursor(data: filteredRecords))
        })
    }

    public func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace, withUsername username: String? = nil) -> Deferred<Maybe<Cursor<LoginRecord>>> {
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
            return deferMaybe(ArrayCursor(data: filteredRecords))
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

    public func use(login: LoginRecord) -> Success {
        login.timesUsed += 1
        login.timeLastUsed = Int64(Date.nowMicroseconds())

        return self.update(login: login)
    }

    public func update(login: LoginRecord) -> Success {
        let deferred = Success()

        // TEMP: Workaround for https://github.com/mozilla/application-services/issues/623
        if login.formSubmitURL?.isEmpty ?? false {
            login.formSubmitURL = nil
        }
        if login.httpRealm?.isEmpty ?? false {
            login.httpRealm = nil
        }

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

    public func delete(ids: [String]) -> Deferred<[Maybe<Bool>]> {
        return all(ids.map({ delete(id: $0) }))
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
}
