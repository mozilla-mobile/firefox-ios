/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

open class BasePayloadJSON {
    var _json: JSON
    required public init(_ jsonString: String) {
        self._json = JSON.init(parseJSON: jsonString)
    }

    public init(_ json: JSON) {
        self._json = json
    }

    // Override me.
    fileprivate func isValid() -> Bool {
        return self._json.error == nil
    }

    subscript(key: String) -> JSON {
        get {
            return _json[key]
        }

        set {
            _json[key] = newValue
        }
    }
}

/**
 * http://docs.services.mozilla.com/sync/objectformats.html
 * "In addition to these custom collection object structures, the
 *  Encrypted DataObject adds fields like id and deleted."
 */
open class CleartextPayloadJSON: BasePayloadJSON {
    // Override me.
    override open func isValid() -> Bool {
        return super.isValid() && _json["id"].isStringOrNull()
    }

    open var id: String {
        return _json["id"].string!
    }

    open var deleted: Bool {
        let d = _json["deleted"]
        if let bool = d.bool {
            return bool
        } else {
            return false
        }
    }

    // Override me.
    // Doesn't check id. Should it?
    open func equalPayloads (_ obj: CleartextPayloadJSON) -> Bool {
        return self.deleted == obj.deleted
    }
}

public extension JSON {
    func isStringOrNull() -> Bool {
        return isNull() || isString()
    }

    func isError() -> Bool {
        return self.error != nil
    }

    func isString() -> Bool {
        return self.type == .string
    }

    func isBool() -> Bool {
        return self.type == .bool
    }

    func isArray() -> Bool {
        return self.type == .array
    }

    func isDictionary() -> Bool {
        return self.type == .dictionary
    }

    func isNull() -> Bool {
        return self.type == .null
    }

    func isInt() -> Bool {
        return self.type == .number && self.int != nil
    }

    func isDouble() -> Bool {
        return self.type == .number && self.double != nil
    }
}
