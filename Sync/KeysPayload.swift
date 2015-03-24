/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public class KeysPayload: CleartextPayloadJSON {
    override public func isValid() -> Bool {
        // We should also call super.isValid(), but that'll fail:
        // Global is external, but doesn't have external or weak linkage!
        // Swift compiler bug #18422804.
        return !isError &&
               self["default"].isArray
    }
    
    var defaultKeys: KeyBundle? {
        if let pair: [JSON] = self["default"].asArray {
            if let encKey = pair[0].asString {
                if let hmacKey = pair[1].asString {
                    return KeyBundle(encKeyB64: encKey, hmacKeyB64: hmacKey)
                }
            }
        }
        return nil
    }

    override public func equalPayloads(obj: CleartextPayloadJSON) -> Bool {
        if !(obj is KeysPayload) {
            return false;
        }
        
        if !super.equalPayloads(obj) {
            return false;
        }
        
        let p = obj as KeysPayload
        if p.defaultKeys != self.defaultKeys {
            return false
        }

        // TODO: check collections.
        
        return true
    }
}