/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import XCGLogger
import SwiftyJSON

private let log = Logger.syncLogger

open class LoginPayload: CleartextPayloadJSON {
    fileprivate static let OptionalStringFields = [
        "formSubmitURL",
        "httpRealm",
    ]

    fileprivate static let OptionalNumericFields = [
        "timeLastUsed",
        "timeCreated",
        "timePasswordChanged",
        "timesUsed",
    ]

    fileprivate static let RequiredStringFields = [
        "hostname",
        "username",
        "password",
        "usernameField",
        "passwordField",
    ]

    open class func fromJSON(_ json: JSON) -> LoginPayload? {
        let p = LoginPayload(json)
        if p.isValid() {
            return p
        }
        return nil
    }

    override open func isValid() -> Bool {
        if !super.isValid() {
            return false
        }

        if self["deleted"].bool ?? false {
            return true
        }

        if !LoginPayload.RequiredStringFields.every({ self[$0].isString() }) {
            return false
        }

        if !LoginPayload.OptionalStringFields.every({ field in
            let val = self[field]
            // Yup, 404 is not found, so this means "string or nothing".
            let valid = val.isString() || val.isNull() || val.error?.code == 404
            if !valid {
                log.debug("Field \(field) is invalid: \(val)")
            }
            return valid
        }) {
            return false
        }

        if !LoginPayload.OptionalNumericFields.every({ field in
            let val = self[field]
            // Yup, 404 is not found, so this means "number or nothing".
            // We only check for number because we're including timestamps as NSNumbers.
            let valid = val.isNumber() || val.isNull() || val.error?.code == 404
            if !valid {
                log.debug("Field \(field) is invalid: \(val)")
            }
            return valid
        }) {
            return false
        }

        return true
    }

    open var hostname: String {
        return self["hostname"].string!
    }

    open var username: String {
        return self["username"].string!
    }

    open var password: String {
        return self["password"].string!
    }

    open var usernameField: String {
        return self["usernameField"].string!
    }

    open var passwordField: String {
        return self["passwordField"].string!
    }

    open var formSubmitURL: String? {
        return self["formSubmitURL"].string
    }

    open var httpRealm: String? {
        return self["httpRealm"].string
    }

    fileprivate func timestamp(_ field: String) -> Timestamp? {
        let json = self[field]
        if let i = json.int64, i > 0 {
            return Timestamp(i)
        }
        return nil
    }

    open var timesUsed: Int? {
        return self["timesUsed"].int
    }

    open var timeCreated: Timestamp? {
        return self.timestamp("timeCreated")
    }

    open var timeLastUsed: Timestamp? {
        return self.timestamp("timeLastUsed")
    }

    open var timePasswordChanged: Timestamp? {
        return self.timestamp("timePasswordChanged")
    }

    override open func equalPayloads(_ obj: CleartextPayloadJSON) -> Bool {
        if let p = obj as? LoginPayload {
            if !super.equalPayloads(p) {
                return false
            }

            if p.deleted || self.deleted {
                return self.deleted == p.deleted
            }

            // If either record is deleted, these other fields might be missing.
            // But we just checked, so we're good to roll on.

            return LoginPayload.RequiredStringFields.every({ field in
                p[field].string == self[field].string
            })

            // TODO: optional fields.
        }

        return false
    }
}
