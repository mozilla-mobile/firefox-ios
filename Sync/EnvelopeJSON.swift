// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Foundation
import Shared
import SwiftyJSON

open class EnvelopeJSON {
    fileprivate let json: JSON

    public init(_ jsonString: String) {
        self.json = JSON(parseJSON: jsonString)
    }

    public init(_ json: JSON) {
        self.json = json
    }

    open func isValid() -> Bool {
        !self.json.isError() &&
                self.json["id"].isString() &&
                // self["collection"].isString &&
                self.json["payload"].isString()
    }

    open var id: String {
        self.json["id"].string!
    }

    open var collection: String {
        self.json["collection"].string ?? ""
    }

    open var payload: String {
        self.json["payload"].string!
    }

    open var sortindex: Int {
        let s = self.json["sortindex"]
        return s.int ?? 0
    }

    open var modified: Timestamp {
//        if let intValue = self.json["modified"].int64 {
//            return Timestamp(intValue) * 1000
//        }

        if let doubleValue = self.json["modified"].double {
            return Timestamp(1000 * (doubleValue))
        }

        return 0
    }

    open func stringify() -> String {
        self.json.stringify()!
    }

    open func withModified(_ now: Timestamp) -> EnvelopeJSON {
        if var d = self.json.dictionary {
            d["modified"] = JSON(Double(now) / 1000)
            return EnvelopeJSON(JSON(d))
        }
        return EnvelopeJSON(JSON(parseJSON: "!")) // Intentionally bad JSON.
    }
}

extension EnvelopeJSON {
    func asJSON() -> JSON {
        self.json
    }
}
