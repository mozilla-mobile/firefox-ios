/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

open class EnvelopeJSON {
    fileprivate let json: JSON

    public init(_ jsonString: String) {
        self.json = JSON.parse(jsonString)
    }

    public init(_ json: JSON) {
        self.json = json
    }

    open func isValid() -> Bool {
        return !self.json.isError &&
            self.json["id"].isString &&
            //self["collection"].isString &&
            self.json["payload"].isString
    }

    open var id: String {
        return self.json["id"].asString!
    }

    open var collection: String {
        return self.json["collection"].asString ?? ""
    }

    open var payload: String {
        return self.json["payload"].asString!
    }

    open var sortindex: Int {
        let s = self.json["sortindex"]
        return s.asInt ?? 0
    }

    open var modified: Timestamp {
        if (self.json["modified"].isInt) {
            return Timestamp(self.json["modified"].asInt!) * 1000
        }

        if (self.json["modified"].isDouble) {
            return Timestamp(1000 * (self.json["modified"].asDouble ?? 0.0))
        }

        return 0
    }

    open func toString() -> String {
        return self.json.toString()
    }

    open func withModified(_ now: Timestamp) -> EnvelopeJSON {
        if var d = self.json.asDictionary {
            d["modified"] = JSON(Double(now) / 1000)
            return EnvelopeJSON(JSON(d))
        }
        return EnvelopeJSON(JSON.parse("!")) // Intentionally bad JSON.
    }
}


extension EnvelopeJSON {
    func asJSON() -> JSON {
        return self.json
    }
}
