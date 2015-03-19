/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import WebKit

public class Password : Equatable {
    public let hostname: String
    public let username: String
    public let password: String

    public var httpRealm: String = ""
    public var formSubmitUrl: String = "" {
        didSet {
            if self.formSubmitUrl == "" {
                return
            }

            let url2 = NSURL(string: self.hostname)
            let url1 = NSURL(string: self.formSubmitUrl)
            if url1?.host != url2?.host {
                formSubmitUrl = ""
            }
        }
    }
    public var usernameField: String = ""
    public var passwordField: String = ""

    var guid: String? = nil
    var timeCreated = NSDate()
    var timeLastUsed = NSDate()
    var timePasswordChanged = NSDate()
    var timesUsed = 0

    // var encryptedUsername: String { get }
    // var encryptedPassword: String { get }
    // var encType: String { get }

    public init(site: Site, username: String, password: String) {
        hostname = site.url
        self.username = username
        self.password = password
    }

    public func toDict() -> [String: String] {
        return ["hostname": hostname,
            "formSubmitURL": formSubmitUrl,
            "httpReal": httpRealm,
            "username": username,
            "password": password,
            "usernameField": usernameField,
            "passwordField": passwordField]
    }

    public class func fromScript(url: NSURL, script: [String: String]) -> Password {
        let site = Site(url: getPasswordOrigin(url.absoluteString!)!, title: "")

        let pswd = Password(site: site, username: script["username"]!, password: script["password"]!)

        if let formSubmit = script["formSubmitUrl"] {
            pswd.formSubmitUrl = formSubmit
        }

        if let passField = script["passwordField"] {
            pswd.passwordField = passField
        }

        if let userField = script["usernameField"] {
            pswd.usernameField = userField
        }

        return pswd
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

public func ==(lhs: Password, rhs: Password) -> Bool {
    return lhs.hostname == rhs.hostname && lhs.username == rhs.username && lhs.password == rhs.password
}

public protocol Passwords {
    func get(options: QueryOptions, complete: (cursor: Cursor) -> Void)
    func add(password: Password, complete: (success: Bool) -> Void)
    func remove(password: Password, complete: (success: Bool) -> Void)
    func removeAll(complete: (success: Bool) -> Void)
}

public class MockPasswords : Passwords {
    private var passwordsCache = [Password]()
    private var files: FileAccessor

    public init(files: FileAccessor) {
        self.files = files

        let site = Site(url: "https://m.facebook.com", title: "")
        passwordsCache.append(Password(site: site, username: "FakeUser", password: "FakePassword"))
        passwordsCache.append(Password(site: site, username: "Something", password: "else"))
    }

    public func get(options: QueryOptions, complete: (cursor: Cursor) -> Void) {
        dispatch_async(dispatch_get_main_queue()) { _ in
            complete(cursor: ArrayCursor<Password>(data: self.passwordsCache))
        }
    }

    public func add(password: Password, complete: (success: Bool) -> Void) {
        passwordsCache.append(password)
        complete(success: true)
    }

    public func remove(password: Password, complete: (success: Bool) -> Void) {
        if let index = find(passwordsCache, password) {
            passwordsCache.removeAtIndex(index)
            complete(success: true)
            return
        }
        complete(success: false)
    }

    public func removeAll(complete: (success: Bool) -> Void) {
        passwordsCache.removeAll(keepCapacity: false)
        complete(success: true)
    }
}