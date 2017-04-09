/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import SwiftyJSON

open class KeysPayload: CleartextPayloadJSON {
    override open func isValid() -> Bool {
        return super.isValid() &&
               self["default"].isArray()
    }
    
    fileprivate func keyBundleFromPair(_ input: JSON) -> KeyBundle? {
        if let pair: [JSON] = input.array {
            if let encKey = pair[0].string {
                if let hmacKey = pair[1].string {
                    return KeyBundle(encKeyB64: encKey, hmacKeyB64: hmacKey)
                }
            }
        }
        return nil
    }

    var defaultKeys: KeyBundle? {
        return self.keyBundleFromPair(self["default"])
    }

    var collectionKeys: [String: KeyBundle] {
        if let collections: [String: JSON] = self["collections"].dictionary {
            return optFilter(mapValues(collections, f: self.keyBundleFromPair))
        }
        return [:]
    }

    override open func equalPayloads(_ obj: CleartextPayloadJSON) -> Bool {
        if !(obj is KeysPayload) {
            return false
        }
        
        if !super.equalPayloads(obj) {
            return false
        }
        
        let p = obj as! KeysPayload
        if p.defaultKeys != self.defaultKeys {
            return false
        }

        // TODO: check collections.
        
        return true
    }
}
