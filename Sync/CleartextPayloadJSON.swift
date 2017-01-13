/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

open class BasePayloadJSON: JSON {
    required public init(_ jsonString: String) {
        super.init(JSON.parse(jsonString))
    }

    override public init(_ json: JSON) {
        super.init(json)
    }

    // Override me.
    fileprivate func isValid() -> Bool {
        return !isError
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
        return super.isValid() && self["id"].isString
    }

    open var id: String {
        return self["id"].asString!
    }

    open var deleted: Bool {
        let d = self["deleted"]
        if d.isBool {
            return d.asBool!
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

extension JSON {
    public var isStringOrNull: Bool {
        return self.isString || self.isNull
    }
}
