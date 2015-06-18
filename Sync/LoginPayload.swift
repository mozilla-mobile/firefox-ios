/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger

private let log = XCGLogger.defaultInstance()

public class LoginPayload: CleartextPayloadJSON {
    private static let OptionalStringFields = [
        "formSubmitURL",
        "httpRealm",
    ]

    private static let RequiredStringFields = [
        "hostname",
        "username",
        "password",
        "usernameField",
        "passwordField",
    ]

    public class func fromJSON(json: JSON) -> LoginPayload? {
        let p = LoginPayload(json)
        if p.isValid() {
            return p
        }
        return nil
    }

    override public func isValid() -> Bool {
        if !super.isValid() {
            return false
        }
        if self["deleted"].isBool {
            return true
        }
        return LoginPayload.RequiredStringFields.every({ self[$0].isString })
    }

    public var hostname: String {
        return self["hostname"].asString!
    }

    public var username: String {
        return self["username"].asString!
    }

    public var password: String {
        return self["password"].asString!
    }

    public var usernameField: String {
        return self["usernameField"].asString!
    }

    public var passwordField: String {
        return self["passwordField"].asString!
    }

    public var formSubmitURL: String? {
        return self["formSubmitURL"].asString
    }

    public var httpRealm: String? {
        return self["httpRealm"].asString
    }

    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
        if let p = obj as? LoginPayload {
            if !super.equalPayloads(p) {
                return false;
            }

            if p.deleted {
                return self.deleted == p.deleted
            }

            // If either record is deleted, these other fields might be missing.
            // But we just checked, so we're good to roll on.

            return LoginPayload.RequiredStringFields.every({ field in
                p[field].asString == self[field].asString
            })

            // TODO: optional fields.
        }

        return false
    }
}
