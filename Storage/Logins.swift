/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared

/**
 * Login is a wrapper around NSURLCredential and NSURLProtectionSpace to allow us to add extra fields where needed.
 **/
public protocol LoginData {
    var credentials: NSURLCredential { get }
    var protectionSpace: NSURLProtectionSpace { get }
    var hostname: String { get }
    var username: String? { get }
    var password: String { get }
    var httpRealm: String? { get set }
    var formSubmitUrl: String? { get set }
    var usernameField: String? { get set }
    var passwordField: String? { get set }

    func toDict() -> [String: String]
}

public protocol LoginUsageData: LoginData {
    var timeCreated: MicrosecondTimestamp { get set }
    var timeLastUsed: MicrosecondTimestamp { get set }
    var timePasswordChanged: MicrosecondTimestamp { get set }
}

public protocol SyncableLoginData {
    var guid: String? { get set }
    var isDeleted: Bool { get set }
}

public class Login : Printable, SyncableLoginData, LoginUsageData, Equatable {
    public let credentials: NSURLCredential
    public let protectionSpace: NSURLProtectionSpace

    public var hostname: String { return protectionSpace.host }
    public var username: String? { return credentials.user }
    public var password: String { return credentials.password! }
    private var _httpRealm: String? = nil
    public var usernameField: String? = nil
    public var passwordField: String? = nil

    public var httpRealm: String? {
        get { return self._httpRealm ?? protectionSpace.realm }
        set { self._httpRealm = newValue }
    }

    public var formSubmitUrl: String? = nil {
        didSet {
            if self.formSubmitUrl == nil || self.formSubmitUrl!.isEmpty {
                return
            }

            let url2 = NSURL(string: self.hostname)
            let url1 = NSURL(string: self.formSubmitUrl!)
            if url1?.host != url2?.host {
                assertionFailure("Form submit url domain doesn't match login's domain")
                formSubmitUrl = nil
            }
        }
    }

    // SyncableLoginData
    public var guid: String? = nil
    public var isDeleted: Bool = false

    // UsageLignData
    public var timeCreated = NSDate.nowMicroseconds()
    public var timeLastUsed = NSDate.nowMicroseconds()
    public var timePasswordChanged = NSDate.nowMicroseconds()

    // Printable
    public var description: String {
        return "Login: \(username) for \(hostname)"
    }

    public class func createWith(hostname: String, username: String, password: String) -> LoginData {
        return Login(hostname: hostname, username: username, password: password) as LoginData
    }

    public class func createWith(credential: NSURLCredential, protectionSpace: NSURLProtectionSpace) -> LoginData {
        return Login(credential: credential, protectionSpace: protectionSpace) as LoginData
    }

    init(hostname: String, username: String, password: String) {
        self.credentials = NSURLCredential(user: username, password: password, persistence: NSURLCredentialPersistence.None)
        self.protectionSpace = NSURLProtectionSpace(host: hostname, port: 0, `protocol`: nil, realm: nil, authenticationMethod: nil)
    }

    init(credential: NSURLCredential, protectionSpace: NSURLProtectionSpace) {
        self.credentials = credential
        self.protectionSpace = protectionSpace
    }

    public func toDict() -> [String: String] {
        return [
            "hostname": hostname,
            "formSubmitURL": formSubmitUrl ?? "",
            "httpRealm": httpRealm ?? "",
            "username": username ?? "",
            "password": password,
            "usernameField": usernameField ?? "",
            "passwordField": passwordField ?? ""
        ]
    }

    public class func fromScript(url: NSURL, script: [String: String]) -> LoginData {
        let login = Login(hostname: getPasswordOrigin(url.absoluteString!)!, username: script["username"]!, password: script["password"]!)

        if let formSubmit = script["formSubmitUrl"] {
            login.formSubmitUrl = formSubmit
        }

        if let passwordField = script["passwordField"] {
            login.passwordField = passwordField
        }

        if let userField = script["usernameField"] {
            login.usernameField = userField
        }

        return login as LoginData
    }

    private class func getPasswordOrigin(uriString: String, allowJS: Bool = false) -> String? {
        var realm: String? = nil
        if let uri = NSURL(string: uriString) {
            if allowJS && uri.scheme == "javascript" {
                return "javascript:"
            }

            realm = "\(uri.scheme!)://\(uri.host!)"

            // If the URI explicitly specified a port, only include it when
            // it's not the default. (We never want "http://foo.com:80")
            if var port = uri.port {
                realm? += ":\(port)"
            }
        } else {
            // bug 159484 - disallow url types that don't support a hostPort.
            // (although we handle "javascript:..." as a special case above.)
            println("Couldn't parse origin for \(uriString)")
            realm = nil
        }
        return realm
    }
}

public func ==(lhs: Login, rhs: Login) -> Bool {
    return lhs.credentials == rhs.credentials && lhs.protectionSpace == rhs.protectionSpace
}

public protocol Logins {
    func getUsageDataForLogin(login: LoginData) -> Deferred<Result<LoginUsageData>>
    func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace) -> Deferred<Result<Cursor<LoginData>>>
    func addLogin(login: LoginData) -> Success
    func updateLogin(login: LoginData) -> Success
    func addVisitFor(login: LoginData) -> Success
    func removeLogin(login: LoginData) -> Success
    func removeAll() -> Success
}

public class LoginDataError: ErrorType {
    public let description: String
    public init(description: String) {
        self.description = description
    }
}

public class MockLogins : Logins {
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

    public func addVisitFor(login: LoginData) -> Success {
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