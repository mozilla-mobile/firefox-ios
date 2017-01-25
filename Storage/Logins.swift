/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import Deferred
import XCGLogger

private var log = Logger.syncLogger

enum SyncStatus: Int {
    // Ordinarily not needed; synced items are removed from the overlay. But they start here when cloned.
    case synced = 0

    // A material change that we want to upload on next sync.
    case changed = 1

    // Created locally.
    case new = 2
}

public enum CommutativeLoginField {
    case timesUsed(increment: Int)
}

public protocol Indexable {
    var index: Int { get }
}

public enum NonCommutativeLoginField: Indexable {
    case hostname(to: String)
    case password(to: String)
    case username(to: String?)
    case httpRealm(to: String?)
    case formSubmitURL(to: String?)
    case timeCreated(to: MicrosecondTimestamp)                  // Should be immutable.
    case timeLastUsed(to: MicrosecondTimestamp)
    case timePasswordChanged(to: MicrosecondTimestamp)

    public var index: Int {
        switch self {
        case .hostname:
            return 0
        case .password:
            return 1
        case .username:
            return 2
        case .httpRealm:
            return 3
        case .formSubmitURL:
            return 4
        case .timeCreated:
            return 5
        case .timeLastUsed:
            return 6
        case .timePasswordChanged:
            return 7
        }
    }

    static let Entries: Int = 8
}

// We don't care about these, because they're slated for removal at some point --
// we don't really use them for form fill.
// We handle them in the same way as NonCommutative, just broken out to allow us
// flexibility in removing them or reconciling them differently.
public enum NonConflictingLoginField: Indexable {
    case usernameField(to: String?)
    case passwordField(to: String?)

    public var index: Int {
        switch self {
        case .usernameField:
            return 0
        case .passwordField:
            return 1
        }
    }

    static let Entries: Int = 2
}

public typealias LoginDeltas = (
    commutative: [CommutativeLoginField],
    nonCommutative: [NonCommutativeLoginField],
    nonConflicting: [NonConflictingLoginField]
)

public typealias TimestampedLoginDeltas = (at: Timestamp, changed: LoginDeltas)

/**
 * LoginData is a wrapper around NSURLCredential and NSURLProtectionSpace to allow us to add extra fields where needed.
 **/
public protocol LoginData: class {
    var guid: String { get set }                 // It'd be nice if this were read-only.
    var credentials: URLCredential { get }
    var protectionSpace: URLProtectionSpace { get }
    var hostname: String { get }
    var username: String? { get }
    var password: String { get }
    var httpRealm: String? { get set }
    var formSubmitURL: String? { get set }
    var usernameField: String? { get set }
    var passwordField: String? { get set }
    var isValid: Maybe<()> { get }

    // https://bugzilla.mozilla.org/show_bug.cgi?id=1238103
    var hasMalformedHostname: Bool { get set }

    func toDict() -> [String: String]

    func isSignificantlyDifferentFrom(_ login: LoginData) -> Bool
}

public protocol LoginUsageData {
    var timesUsed: Int { get set }
    var timeCreated: MicrosecondTimestamp { get set }
    var timeLastUsed: MicrosecondTimestamp { get set }
    var timePasswordChanged: MicrosecondTimestamp { get set }
}

open class Login: CustomStringConvertible, LoginData, LoginUsageData, Equatable {
    open var guid: String

    open fileprivate(set) var credentials: URLCredential
    open let protectionSpace: URLProtectionSpace

    open var hostname: String {
        if let _ = protectionSpace.`protocol` {
            return protectionSpace.urlString()
        }
        return protectionSpace.host
    }

    open var hasMalformedHostname: Bool = false

    open var username: String? { return credentials.user }
    open var password: String { return credentials.password! }
    open var usernameField: String?
    open var passwordField: String?

    fileprivate var _httpRealm: String?
    open var httpRealm: String? {
        get { return self._httpRealm ?? protectionSpace.realm }
        set { self._httpRealm = newValue }
    }

    fileprivate var _formSubmitURL: String?
    open var formSubmitURL: String? {
        get {
            return self._formSubmitURL
        }
        set(value) {
            if value == nil || value!.isEmpty {
                self._formSubmitURL = nil
                return
            }

            let url2 = URL(string: self.hostname)
            let url1 = URL(string: value!)

            if url1?.host != url2?.host {
                log.warning("Form submit URL domain doesn't match login's domain.")
            }

            self._formSubmitURL = value
        }
    }

    // LoginUsageData. These defaults only apply to locally created records.
    open var timesUsed = 0
    open var timeCreated = Date.nowMicroseconds()
    open var timeLastUsed = Date.nowMicroseconds()
    open var timePasswordChanged = Date.nowMicroseconds()

    // Printable
    open var description: String {
        return "Login for \(hostname)"
    }

    open var isValid: Maybe<()> {
        // Referenced from https://mxr.mozilla.org/mozilla-central/source/toolkit/components/passwordmgr/nsLoginManager.js?rev=f76692f0fcf8&mark=280-281#271

        // Logins with empty hostnames are not valid.
        if hostname.isEmpty {
            return Maybe(failure: LoginDataError(description: "Can't add a login with an empty hostname."))
        }

        // Logins with empty passwords are not valid.
        if password.isEmpty {
            return Maybe(failure: LoginDataError(description: "Can't add a login with an empty password."))
        }

        // Logins with both a formSubmitURL and httpRealm are not valid.
        if let _ = formSubmitURL, let _ = httpRealm {
            return Maybe(failure: LoginDataError(description: "Can't add a login with both a httpRealm and formSubmitURL."))
        }

        // Login must have at least a formSubmitURL or httpRealm.
        if (formSubmitURL == nil) && (httpRealm == nil) {
            return Maybe(failure: LoginDataError(description: "Can't add a login without a httpRealm or formSubmitURL."))
        }

        // All good.
        return Maybe(success: ())
    }

    open func update(password: String, username: String) {
        self.credentials =
            URLCredential(user: username, password: password, persistence: credentials.persistence)
    }

    // Essentially: should we sync a change?
    // Desktop ignores usernameField and hostnameField.
    open func isSignificantlyDifferentFrom(_ login: LoginData) -> Bool {
        return login.password != self.password ||
               login.hostname != self.hostname ||
               login.username != self.username ||
               login.formSubmitURL != self.formSubmitURL ||
               login.httpRealm != self.httpRealm
    }

    /* Used for testing purposes since formSubmitURL should be given back to use from the Logins.js script */
    open class func createWithHostname(_ hostname: String, username: String, password: String, formSubmitURL: String?) -> LoginData {
        let loginData = Login(hostname: hostname, username: username, password: password) as LoginData
        loginData.formSubmitURL = formSubmitURL
        return loginData
    }

    open class func createWithHostname(_ hostname: String, username: String, password: String) -> LoginData {
        return Login(hostname: hostname, username: username, password: password) as LoginData
    }

    open class func createWithCredential(_ credential: URLCredential, protectionSpace: URLProtectionSpace) -> LoginData {
        return Login(credential: credential, protectionSpace: protectionSpace) as LoginData
    }

    public init(guid: String, hostname: String, username: String, password: String) {
        self.guid = guid
        self.credentials = URLCredential(user: username, password: password, persistence: URLCredential.Persistence.none)

        // Break down the full url hostname into its scheme/protocol and host components
        let hostnameURL = hostname.asURL
        let host = hostnameURL?.host ?? hostname
        let scheme = hostnameURL?.scheme ?? ""

        // We should ignore any SSL or normal web ports in the URL.
        var port = hostnameURL?.port ?? 0
        if port == 443 || port == 80 {
            port = 0
        }

        self.protectionSpace = URLProtectionSpace(host: host, port: port, protocol: scheme, realm: nil, authenticationMethod: nil)
    }

    convenience init(hostname: String, username: String, password: String) {
        self.init(guid: Bytes.generateGUID(), hostname: hostname, username: username, password: password)
    }

    // Why do we need this initializer to be marked as required? Because otherwise we can't
    // use this type in our factory for MirrorLogin and LocalLogin.
    // SO: http://stackoverflow.com/questions/26280176/swift-generics-not-preserving-type
    // Playground: https://gist.github.com/rnewman/3fb0c4dbd25e7fda7e3d
    // Conversation: https://twitter.com/rnewman/status/611332618412359680
    required public init(credential: URLCredential, protectionSpace: URLProtectionSpace) {
        self.guid = Bytes.generateGUID()
        self.credentials = credential
        self.protectionSpace = protectionSpace
    }

    open func toDict() -> [String: String] {
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

    open class func fromScript(_ url: URL, script: [String: Any]) -> LoginData? {
        guard let username = script["username"] as? String,
              let password = script["password"] as? String else {
                return nil
        }

        let login = Login(hostname: getPasswordOrigin(url.absoluteString)!, username: username, password: password)

        if let formSubmit = script["formSubmitURL"] as? String {
            login.formSubmitURL = formSubmit
        }

        if let passwordField = script["passwordField"] as? String {
            login.passwordField = passwordField
        }

        if let userField = script["usernameField"] as? String {
            login.usernameField = userField
        }

        return login as LoginData
    }

    fileprivate class func getPasswordOrigin(_ uriString: String, allowJS: Bool = false) -> String? {
        var realm: String? = nil
        if let uri = URL(string: uriString),
            let scheme = uri.scheme, !scheme.isEmpty {
            if allowJS && scheme == "javascript" {
                return "javascript:"
            }

            realm = "\(scheme)://\(uri.host!)"

            // If the URI explicitly specified a port, only include it when
            // it's not the default. (We never want "http://foo.com:80")
            if let port = uri.port {
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

    /**
     * Produce a delta stream by comparing this record to a source.
     * Note that the source might be missing the timestamp and counter fields
     * introduced in Bug 555755, so we pay special attention to those, checking for
     * and ignoring transitions to zero.
     *
     * TODO: it's possible that we'll have, say, two iOS clients working with a desktop.
     * Each time the desktop changes the password fields, it'll upload a record without
     * these extra timestamp fields. We need to make sure the right thing happens.
     *
     * There are three phases in this process:
     * 1. Producing deltas. There is no intrinsic ordering here, but we yield ordered
     *    arrays for convenience and ease of debugging.
     * 2. Comparing deltas. This is done through a kind of array-based Perlish Schwartzian
     *    transform, where each field has a known index in space to allow for trivial
     *    comparison; this, of course, is ordered.
     * 3. Applying a merged delta stream to a record. Again, this is unordered, but we
     *    use arrays for convenience.
     */
    open func deltas(from: Login) -> LoginDeltas {
        let commutative: [CommutativeLoginField]

        if self.timesUsed > 0 && self.timesUsed != from.timesUsed {
            commutative = [CommutativeLoginField.timesUsed(increment: self.timesUsed - from.timesUsed)]
        } else {
            commutative = []
        }

        var nonCommutative = [NonCommutativeLoginField]()

        if self.hostname != from.hostname {
            nonCommutative.append(NonCommutativeLoginField.hostname(to: self.hostname))
        }
        if self.password != from.password {
            nonCommutative.append(NonCommutativeLoginField.password(to: self.password))
        }
        if self.username != from.username {
            nonCommutative.append(NonCommutativeLoginField.username(to: self.username))
        }
        if self.httpRealm != from.httpRealm {
            nonCommutative.append(NonCommutativeLoginField.httpRealm(to: self.httpRealm))
        }
        if self.formSubmitURL != from.formSubmitURL {
            nonCommutative.append(NonCommutativeLoginField.formSubmitURL(to: self.formSubmitURL))
        }
        if self.timeCreated > 0 && self.timeCreated != from.timeCreated {
            nonCommutative.append(NonCommutativeLoginField.timeCreated(to: self.timeCreated))
        }
        if self.timeLastUsed > 0 && self.timeLastUsed != from.timeLastUsed {
            nonCommutative.append(NonCommutativeLoginField.timeLastUsed(to: self.timeLastUsed))
        }
        if self.timeLastUsed > 0 && self.timePasswordChanged != from.timePasswordChanged {
            nonCommutative.append(NonCommutativeLoginField.timePasswordChanged(to: self.timePasswordChanged))
        }

        var nonConflicting = [NonConflictingLoginField]()

        if self.passwordField != from.passwordField {
            nonConflicting.append(NonConflictingLoginField.passwordField(to: self.passwordField))
        }
        if self.usernameField != from.usernameField {
            nonConflicting.append(NonConflictingLoginField.usernameField(to: self.usernameField))
        }

        return (commutative, nonCommutative, nonConflicting)
    }

    fileprivate class func mergeDeltaFields<T: Indexable>(_ count: Int, a: [T], b: [T], preferBToA: Bool) -> [T] {
        var deltas = Array<T?>(repeating: nil, count: count)

        // Let's start with the 'a's.
        for f in a {
            deltas[f.index] = f
        }

        // Then detect any conflicts and fill out the rest.
        for f in b {
            let index = f.index
            if deltas[index] != nil {
                log.warning("Collision in \(T.self) \(f.index). Using latest.")
                if preferBToA {
                    deltas[index] = f
                }
            } else {
                deltas[index] = f
            }
        }

        return optFilter(deltas)
    }

    open class func mergeDeltas(a: TimestampedLoginDeltas, b: TimestampedLoginDeltas) -> LoginDeltas {
        let (aAt, aChanged) = a
        let (bAt, bChanged) = b
        let (aCommutative, aNonCommutative, aNonConflicting) = aChanged
        let (bCommutative, bNonCommutative, bNonConflicting) = bChanged

        // If the timestamps are exactly the same -- an exceedingly rare occurrence -- we default
        // to 'b', which is the remote record by convention.
        let bLatest = aAt <= bAt

        let commutative = aCommutative + bCommutative
        let nonCommutative: [NonCommutativeLoginField]
        let nonConflicting: [NonConflictingLoginField]

        if aNonCommutative.isEmpty {
            nonCommutative = bNonCommutative
        } else if bNonCommutative.isEmpty {
            nonCommutative = aNonCommutative
        } else {
            nonCommutative = mergeDeltaFields(NonCommutativeLoginField.Entries, a: aNonCommutative, b: bNonCommutative, preferBToA: bLatest)
        }

        if aNonConflicting.isEmpty {
            nonConflicting = bNonConflicting
        } else if bNonCommutative.isEmpty {
            nonConflicting = aNonConflicting
        } else {
            nonConflicting = mergeDeltaFields(NonConflictingLoginField.Entries, a: aNonConflicting, b: bNonConflicting, preferBToA: bLatest)
        }

        return (
            commutative: commutative,
            nonCommutative: nonCommutative,
            nonConflicting: nonConflicting
        )
    }

    /**
     * Apply the provided changes to yield a new login.
     */
    open func applyDeltas(_ deltas: LoginDeltas) -> Login {
        let guid = self.guid
        var hostname = self.hostname
        var username = self.username
        var password = self.password
        var usernameField = self.usernameField
        var passwordField = self.passwordField
        var timesUsed = self.timesUsed
        var httpRealm = self.httpRealm
        var formSubmitURL = self.formSubmitURL
        var timeCreated = self.timeCreated
        var timeLastUsed = self.timeLastUsed
        var timePasswordChanged = self.timePasswordChanged

        for delta in deltas.commutative {
            switch delta {
            case let .timesUsed(increment):
                timesUsed += increment
            }
        }

        for delta in deltas.nonCommutative {
            switch delta {
            case let .hostname(to):
                hostname = to
                break
            case let .password(to):
                password = to
                break
            case let .username(to):
                username = to
                break
            case let .httpRealm(to):
                httpRealm = to
                break
            case let .formSubmitURL(to):
                formSubmitURL = to
                break
            case let .timeCreated(to):
                timeCreated = to
                break
            case let .timeLastUsed(to):
                timeLastUsed = to
                break
            case let .timePasswordChanged(to):
                timePasswordChanged = to
                break
            }
        }

        for delta in deltas.nonConflicting {
            switch delta {
            case let .usernameField(to):
                usernameField = to
                break
            case let .passwordField(to):
                passwordField = to
                break
            }
        }

        let out = Login(guid: guid, hostname: hostname, username: username!, password: password)
        out.timesUsed = timesUsed
        out.httpRealm = httpRealm
        out.formSubmitURL = formSubmitURL
        out.timeCreated = timeCreated
        out.timeLastUsed = timeLastUsed
        out.timePasswordChanged = timePasswordChanged
        out.usernameField = usernameField
        out.passwordField = passwordField

        return out
    }
}

public func ==(lhs: Login, rhs: Login) -> Bool {
    return lhs.credentials == rhs.credentials && lhs.protectionSpace == rhs.protectionSpace
}

open class ServerLogin: Login {
    var serverModified: Timestamp = 0

    public init(guid: String, hostname: String, username: String, password: String, modified: Timestamp) {
        self.serverModified = modified
        super.init(guid: guid, hostname: hostname, username: username, password: password)
    }

    required public init(credential: URLCredential, protectionSpace: URLProtectionSpace) {
        super.init(credential: credential, protectionSpace: protectionSpace)
    }
}

class MirrorLogin: ServerLogin {
    var isOverridden: Bool = false
}

class LocalLogin: Login {
    var syncStatus: SyncStatus = .synced
    var isDeleted: Bool = false
    var localModified: Timestamp = 0
}

public protocol BrowserLogins {
    func getUsageDataForLoginByGUID(_ guid: GUID) -> Deferred<Maybe<LoginUsageData>>
    func getLoginDataForGUID(_ guid: GUID) -> Deferred<Maybe<Login>>
    func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace) -> Deferred<Maybe<Cursor<LoginData>>>
    func getLoginsForProtectionSpace(_ protectionSpace: URLProtectionSpace, withUsername username: String?) -> Deferred<Maybe<Cursor<LoginData>>>
    func getAllLogins() -> Deferred<Maybe<Cursor<Login>>>
    func searchLoginsWithQuery(_ query: String?) -> Deferred<Maybe<Cursor<Login>>>

    // Add a new login regardless of whether other logins might match some fields. Callers
    // are responsible for querying first if they care.
    @discardableResult func addLogin(_ login: LoginData) -> Success

    @discardableResult func updateLoginByGUID(_ guid: GUID, new: LoginData, significant: Bool) -> Success

    // Add the use of a login by GUID.
    @discardableResult func addUseOfLoginByGUID(_ guid: GUID) -> Success
    func removeLoginByGUID(_ guid: GUID) -> Success
    func removeLoginsWithGUIDs(_ guids: [GUID]) -> Success

    func removeAll() -> Success
}

public protocol SyncableLogins: AccountRemovalDelegate {
    /**
     * Delete the login with the provided GUID. Succeeds if the GUID is unknown.
     */
    func deleteByGUID(_ guid: GUID, deletedAt: Timestamp) -> Success

    func applyChangedLogin(_ upstream: ServerLogin) -> Success

    func getModifiedLoginsToUpload() -> Deferred<Maybe<[Login]>>
    func getDeletedLoginsToUpload() -> Deferred<Maybe<[GUID]>>

    /**
     * Chains through the provided timestamp.
     */
    func markAsSynchronized<T: Collection>(_: T, modified: Timestamp) -> Deferred<Maybe<Timestamp>> where T.Iterator.Element == GUID
    func markAsDeleted<T: Collection>(_ guids: T) -> Success where T.Iterator.Element == GUID

    /**
     * For inspecting whether we're an active participant in login sync.
     */
    func hasSyncedLogins() -> Deferred<Maybe<Bool>>
}

open class LoginDataError: MaybeErrorType {
    open let description: String
    public init(description: String) {
        self.description = description
    }
}
