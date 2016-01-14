/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit
import Shared
import XCGLogger

private var log = Logger.syncLogger

enum SyncStatus: Int {
    // Ordinarily not needed; synced items are removed from the overlay. But they start here when cloned.
    case Synced = 0

    // A material change that we want to upload on next sync.
    case Changed = 1

    // Created locally.
    case New = 2
}

public enum CommutativeLoginField {
    case TimesUsed(increment: Int)
}

public protocol Indexable {
    var index: Int { get }
}

public enum NonCommutativeLoginField: Indexable {
    case Hostname(to: String)
    case Password(to: String)
    case Username(to: String?)
    case HTTPRealm(to: String?)
    case FormSubmitURL(to: String?)
    case TimeCreated(to: MicrosecondTimestamp)                  // Should be immutable.
    case TimeLastUsed(to: MicrosecondTimestamp)
    case TimePasswordChanged(to: MicrosecondTimestamp)

    public var index: Int {
        switch self {
        case .Hostname:
            return 0
        case .Password:
            return 1
        case .Username:
            return 2
        case .HTTPRealm:
            return 3
        case .FormSubmitURL:
            return 4
        case .TimeCreated:
            return 5
        case .TimeLastUsed:
            return 6
        case .TimePasswordChanged:
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
    case UsernameField(to: String?)
    case PasswordField(to: String?)

    public var index: Int {
        switch self {
        case .UsernameField:
            return 0
        case .PasswordField:
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

    func isSignificantlyDifferentFrom(login: LoginData) -> Bool
}

public protocol LoginUsageData {
    var timesUsed: Int { get set }
    var timeCreated: MicrosecondTimestamp { get set }
    var timeLastUsed: MicrosecondTimestamp { get set }
    var timePasswordChanged: MicrosecondTimestamp { get set }
}

public class Login: CustomStringConvertible, LoginData, LoginUsageData, Equatable {
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
                log.warning("Form submit URL domain doesn't match login's domain.")
            }

            self._formSubmitURL = value
        }
    }

    // LoginUsageData. These defaults only apply to locally created records.
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
    public func isSignificantlyDifferentFrom(login: LoginData) -> Bool {
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

    public class func fromScript(url: NSURL, script: [String: AnyObject]) -> LoginData? {
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

    private class func getPasswordOrigin(uriString: String, allowJS: Bool = false) -> String? {
        var realm: String? = nil
        if let uri = NSURL(string: uriString) where !uri.scheme.isEmpty {
            if allowJS && uri.scheme == "javascript" {
                return "javascript:"
            }

            realm = "\(uri.scheme)://\(uri.host!)"

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
    public func deltas(from from: Login) -> LoginDeltas {
        let commutative: [CommutativeLoginField]

        if self.timesUsed > 0 && self.timesUsed != from.timesUsed {
            commutative = [CommutativeLoginField.TimesUsed(increment: self.timesUsed - from.timesUsed)]
        } else {
            commutative = []
        }

        var nonCommutative = [NonCommutativeLoginField]()

        if self.hostname != from.hostname {
            nonCommutative.append(NonCommutativeLoginField.Hostname(to: self.hostname))
        }
        if self.password != from.password {
            nonCommutative.append(NonCommutativeLoginField.Password(to: self.password))
        }
        if self.username != from.username {
            nonCommutative.append(NonCommutativeLoginField.Username(to: self.username))
        }
        if self.httpRealm != from.httpRealm {
            nonCommutative.append(NonCommutativeLoginField.HTTPRealm(to: self.httpRealm))
        }
        if self.formSubmitURL != from.formSubmitURL {
            nonCommutative.append(NonCommutativeLoginField.FormSubmitURL(to: self.formSubmitURL))
        }
        if self.timeCreated > 0 && self.timeCreated != from.timeCreated {
            nonCommutative.append(NonCommutativeLoginField.TimeCreated(to: self.timeCreated))
        }
        if self.timeLastUsed > 0 && self.timeLastUsed != from.timeLastUsed {
            nonCommutative.append(NonCommutativeLoginField.TimeLastUsed(to: self.timeLastUsed))
        }
        if self.timeLastUsed > 0 && self.timePasswordChanged != from.timePasswordChanged {
            nonCommutative.append(NonCommutativeLoginField.TimePasswordChanged(to: self.timePasswordChanged))
        }

        var nonConflicting = [NonConflictingLoginField]()

        if self.passwordField != from.passwordField {
            nonConflicting.append(NonConflictingLoginField.PasswordField(to: self.passwordField))
        }
        if self.usernameField != from.usernameField {
            nonConflicting.append(NonConflictingLoginField.UsernameField(to: self.usernameField))
        }

        return (commutative, nonCommutative, nonConflicting)
    }

    private class func mergeDeltaFields<T: Indexable>(count: Int, a: [T], b: [T], preferBToA: Bool) -> [T] {
        var deltas = Array<T?>(count: count, repeatedValue: nil)

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

    public class func mergeDeltas(a a: TimestampedLoginDeltas, b: TimestampedLoginDeltas) -> LoginDeltas {
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
    public func applyDeltas(deltas: LoginDeltas) -> Login {
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
            case let .TimesUsed(increment):
                timesUsed += increment
            }
        }

        for delta in deltas.nonCommutative {
            switch delta {
            case let .Hostname(to):
                hostname = to
                break
            case let .Password(to):
                password = to
                break
            case let .Username(to):
                username = to
                break
            case let .HTTPRealm(to):
                httpRealm = to
                break
            case let .FormSubmitURL(to):
                formSubmitURL = to
                break
            case let .TimeCreated(to):
                timeCreated = to
                break
            case let .TimeLastUsed(to):
                timeLastUsed = to
                break
            case let .TimePasswordChanged(to):
                timePasswordChanged = to
                break
            }
        }

        for delta in deltas.nonConflicting {
            switch delta {
            case let .UsernameField(to):
                usernameField = to
                break
            case let .PasswordField(to):
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

public class ServerLogin: Login {
    var serverModified: Timestamp = 0

    public init(guid: String, hostname: String, username: String, password: String, modified: Timestamp) {
        self.serverModified = modified
        super.init(guid: guid, hostname: hostname, username: username, password: password)
    }

    required public init(credential: NSURLCredential, protectionSpace: NSURLProtectionSpace) {
        super.init(credential: credential, protectionSpace: protectionSpace)
    }
}

class MirrorLogin: ServerLogin {
    var isOverridden: Bool = false
}

class LocalLogin: Login {
    var syncStatus: SyncStatus = .Synced
    var isDeleted: Bool = false
    var localModified: Timestamp = 0
}

public protocol BrowserLogins {
    func getUsageDataForLoginByGUID(guid: GUID) -> Deferred<Maybe<LoginUsageData>>
    func getLoginDataForGUID(guid: GUID) -> Deferred<Maybe<Login>>
    func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace) -> Deferred<Maybe<Cursor<LoginData>>>
    func getLoginsForProtectionSpace(protectionSpace: NSURLProtectionSpace, withUsername username: String?) -> Deferred<Maybe<Cursor<LoginData>>>
    func getAllLogins() -> Deferred<Maybe<Cursor<Login>>>
    func searchLoginsWithQuery(query: String?) -> Deferred<Maybe<Cursor<Login>>>

    // Add a new login regardless of whether other logins might match some fields. Callers
    // are responsible for querying first if they care.
    func addLogin(login: LoginData) -> Success

    func updateLoginByGUID(guid: GUID, new: LoginData, significant: Bool) -> Success

    // Add the use of a login by GUID.
    func addUseOfLoginByGUID(guid: GUID) -> Success
    func removeLoginByGUID(guid: GUID) -> Success
    func removeLoginsWithGUIDs(guids: [GUID]) -> Success

    func removeAll() -> Success
}

public protocol SyncableLogins: AccountRemovalDelegate {
    /**
     * Delete the login with the provided GUID. Succeeds if the GUID is unknown.
     */
    func deleteByGUID(guid: GUID, deletedAt: Timestamp) -> Success

    func applyChangedLogin(upstream: ServerLogin) -> Success

    func getModifiedLoginsToUpload() -> Deferred<Maybe<[Login]>>
    func getDeletedLoginsToUpload() -> Deferred<Maybe<[GUID]>>

    /**
     * Chains through the provided timestamp.
     */
    func markAsSynchronized(_: [GUID], modified: Timestamp) -> Deferred<Maybe<Timestamp>>
    func markAsDeleted(guids: [GUID]) -> Success

    /**
     * For inspecting whether we're an active participant in login sync.
     */
    func hasSyncedLogins() -> Deferred<Maybe<Bool>>
}

public class LoginDataError: MaybeErrorType {
    public let description: String
    public init(description: String) {
        self.description = description
    }
}