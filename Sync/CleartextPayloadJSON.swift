/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public class CleartextPayloadJSON: JSON {
    public init(_ jsonString: String) {
        super.init(JSON.parse(jsonString))
    }

    override public init(_ json: JSON) {
        super.init(json)
    }

    // Override me.
    public func isValid() -> Bool {
        return !isError
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
    public func equalPayloads (obj: CleartextPayloadJSON) -> Bool {
        return self.deleted == obj.deleted
    }
}