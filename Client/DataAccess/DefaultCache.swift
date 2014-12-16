/*  This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// A stub cache implementation that will return the same value for all
// keys. Useful as a way of providing the default fallback for a cache
class DefaultCache<K,V> : GenericCache<K, V> {
    let def: ValueType
    init(def: ValueType) {
        self.def = def
    }

    override subscript(key: KeyType) -> ValueType? {
        get {
            return def
        }
        set(newValue) { }
    }
}
