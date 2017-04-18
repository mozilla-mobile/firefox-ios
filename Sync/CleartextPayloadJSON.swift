/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

open class BasePayloadJSON {
    let json: JSON
    required public init(_ jsonString: String) {
        self.json = JSON(parseJSON: jsonString)
    }

    public init(_ json: JSON) {
        self.json = json
    }

    // Override me.
    fileprivate func isValid() -> Bool {
        return self.json.type != .unknown &&
               self.json.error == nil
    }

    subscript(key: String) -> JSON {
        get {
            return json[key]
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
        return super.isValid() && self["id"].isString()
    }

    open var id: String {
        return self["id"].string!
    }

    open var deleted: Bool {
        let d = self["deleted"]
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
