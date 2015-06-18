/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import XCGLogger

private var log = XCGLogger.defaultInstance()

/**
 * LoginData is a wrapper around NSURLCredential and NSURLProtectionSpace to allow us to add extra fields where needed.
 **/
public protocol LoginData: class {
    var guid: String { get set }                 // It'd be nice if this were read-only.
    var credentials: NSURLCredential { get }
    var protectionSpace: NSURLProtectionSpace { get }
    var hostname: String { get }
    var username: String? { get }
    var password: String { get }
    var httpRealm: String? { get set }
    var formSubmitURL: String? { get set }
    var usernameField: String? { get set }
    var passwordField: String? { get set }

    func toDict() -> [String: String]

    func significantlyDiffersFrom(login: LoginData) -> Bool
}

public protocol LoginUsageData {
    var timesUsed: Int { get set }
    var timeCreated: MicrosecondTimestamp { get set }
    var timeLastUsed: MicrosecondTimestamp { get set }
    var timePasswordChanged: MicrosecondTimestamp { get set }
}

public class Login: Printable, LoginData, LoginUsageData, Equatable {
    public var guid: String

    public let credentials: NSURLCredential
    public let protectionSpace: NSURLProtectionSpace

    public var hostname: String { return protectionSpace.host }
    public var username: String? { return credentials.user }
    public var password: String { return credentials.password! }
    public var usernameField: String? = nil
    public var passwordField: String? = nil

    private var _httpRealm: String? = nil
    public var httpRealm: String? {
        get { return self._httpRealm ?? protectionSpace.realm }
        set { self._httpRealm = newValue }
    }

    private var _formSubmitURL: String? = nil
    public var formSubmitURL: String? {
        get {
            return self._formSubmitURL
        }
        set(value) {
            if value == nil || value!.isEmpty {
                self._formSubmitURL = nil
                return
            }

            let url2 = NSURL(string: self.hostname)
            let url1 = NSURL(string: value!)

            if url1?.host != url2?.host {
                assertionFailure("Form submit URL domain doesn't match login's domain.")
                self._formSubmitURL = nil
                return
            }
            self._formSubmitURL = value
        }
    }

    // LoginUsageData
    public var timesUsed = 0
    public var timeCreated = NSDate.nowMicroseconds()
    public var timeLastUsed = NSDate.nowMicroseconds()
    public var timePasswordChanged = NSDate.nowMicroseconds()

    // Printable
    public var description: String {
        return "Login for \(hostname)"
    }

    // Essentially: should we sync a change?
    // Desktop ignores usernameField and hostnameField.
    public func significantlyDiffersFrom(login: LoginData) -> Bool {
        return login.password != self.password ||
               login.hostname != self.hostname ||
               login.username != self.username ||
               login.formSubmitURL != self.formSubmitURL ||
               login.httpRealm != self.httpRealm
    }

    public class func createWithHostname(hostname: String, username: String, password: String) -> LoginData {
        return Login(hostname: hostname, username: username, password: password) as LoginData
    }

    public class func createWithCredential(credential: NSURLCredential, protectionSpace: NSURLProtectionSpace) -> LoginData {
        return Login(credential: credential, protectionSpace: protectionSpace) as LoginData
    }

    public init(guid: String, hostname: String, username: String, password: String) {
        self.guid = guid
        self.credentials = NSURLCredential(user: username, password: password, persistence: NSURLCredentialPersistence.None)
        self.protectionSpace = NSURLProtectionSpace(host: hostname, port: 0, `protocol`: nil, realm: nil, authenticationMethod: nil)
    }

    convenience init(hostname: String, username: String, password: String) {
        self.init(guid: Bytes.generateGUID(), hostname: hostname, username: username, password: password)
    }

    // Why do we need this initializer to be marked as required? Because otherwise we can't
    // use this type in our factory for MirrorLogin and LocalLogin.
    // SO: http://stackoverflow.com/questions/26280176/swift-generics-not-preserving-type
    // Playground: https://gist.github.com/rnewman/3fb0c4dbd25e7fda7e3d
    // Conversation: https://twitter.com/rnewman/status/611332618412359680
    required public init(credential: NSURLCredential, protectionSpace: NSURLProtectionSpace) {
        self.guid = Bytes.generateGUID()
        self.credentials = credential
        self.protectionSpace = protectionSpace
    }

    public func toDict() -> [String: String] {
        return [
            "hostname": hostname,
            "formSubmitURL": formSubmitURL ?? "",
            "httpRealm": httpRealm ?? "",
            "username": username ?? "",
            "password": password,
            "usernameField": usernameField ?? "",
            "passwordField": passwordField ?? ""
        ]
    }

    public class func fromScript(url: NSURL, script: [String: String]) -> LoginData {
        let login = Login(hostname: getPasswordOrigin(url.absoluteString!)!, username: script["username"]!, password: script["password"]!)

        if let formSubmit = script["formSubmitURL"] {
            login.formSubmitURL = formSubmit
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
            log.debug("Couldn't parse origin for \(uriString)")
            realm = nil
        }
        return realm
    }
}

public func ==(lhs: Login, rhs: Login) -> Bool {
    return lhs.credentials == rhs.credentials && lhs.protectionSpace == rhs.protectionSpace
}

public protocol BrowserLogins {
    func getUsageDataForLoginByGUID(guid: GUID) -> Deferred<Result<LoginUsageData>>
    func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace) -> Deferred<Result<Cursor<LoginData>>>
    func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace, withUsername username: String?) -> Deferred<Result<Cursor<LoginData>>>

    // Add a new login regardless of whether other logins might match some fields. Callers
    // are responsible for querying first if they care.
    func addLogin(login: LoginData) -> Success

    func updateLoginByGUID(guid: GUID, new: LoginData, significant: Bool) -> Success

    // Update based on username, hostname, httpRealm, formSubmitURL.
    //func updateLogin(login: LoginData) -> Success

    // Add the use of a login by GUID.
    func addUseOfLoginByGUID(guid: GUID) -> Success
    func removeLoginByGUID(guid: GUID) -> Success

    func removeAll() -> Success
}

public protocol SyncableLogins {
    /**
     * Delete the login with the provided GUID. Succeeds if the GUID is unknown.
     */
    func deleteByGUID(guid: GUID, deletedAt: Timestamp) -> Success

    func applyChangedLogin(upstream: Login, timestamp: Timestamp) -> Success

    /**
     * TODO: these might need some work.
     * Chains through the provided timestamp.
     */
    func markAsSynchronized([GUID], modified: Timestamp) -> Deferred<Result<Timestamp>>
    func markAsDeleted(guids: [GUID]) -> Success

    /**
     * Clean up any metadata.
     */
    func onRemovedAccount() -> Success
}

public class LoginDataError: ErrorType {
    public let description: String
    public init(description: String) {
        self.description = description
    }
}