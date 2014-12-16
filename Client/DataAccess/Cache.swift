/*  This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// A protcol for implementing a generic cache type object
protocol Cache {
    typealias KeyType
    typealias ValueType

    func clear()
    subscript(key: KeyType) -> ValueType? {get set}
}

// Swift won't let me hold an array of Cache objects in OrderedCache, so instead
// we use a stubbed out GenericCache version of it 
class GenericCache<K, V>: Cache {
    typealias KeyType = K
    typealias ValueType = V

    func clear() { }
    subscript(key: KeyType) -> ValueType? {
        get { return nil }
        set(newValue) { }
    }
}
