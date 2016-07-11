/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public class BasePayloadJSON: JSON {
    required public init(_ jsonString: String) {
        super.init(JSON.parse(jsonString))
    }

    override public init(_ json: JSON) {
        super.init(json)
    }

    // Override me.
    private func isValid() -> Bool {
        return !isError
    }
}

/**
 * http://docs.services.mozilla.com/sync/objectformats.html
 * "In addition to these custom collection object structures, the
 *  Encrypted DataObject adds fields like id and deleted."
 */
public class CleartextPayloadJSON: BasePayloadJSON {
    // Override me.
    override public func isValid() -> Bool {
        return super.isValid() && self["id"].isString
    }

    public var id: String {
        return self["id"].asString!
    }

    public var deleted: Bool {
        let d = self["deleted"]
        if d.isBool {
            return d.asBool!
        } else {
            return false;
        }
    }

    // Override me.
    // Doesn't check id. Should it?
    public func equalPayloads (_ obj: CleartextPayloadJSON) -> Bool {
        return self.deleted == obj.deleted
    }
}

extension JSON {
    public var isStringOrNull: Bool {
        return self.isString || self.isNull
    }
}
