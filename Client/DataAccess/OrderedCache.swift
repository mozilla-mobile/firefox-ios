/*  This Source Code Form is subject to the terms of the Mozilla Public
* License, v. 2.0. If a copy of the MPL was not distributed with this
* file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// Stores an array of Cache objects. Will iterate through them to find the first
// cache that contains the requested key. Storing an item will store it in all the
// caches. Clearing will clear all the caches
public class OrderedCache<K, V> : GenericCache<K,V> {
    private let caches: [GenericCache<K,V>]

    init(caches: [GenericCache<K,V>]) {
        self.caches = caches
    }

    override subscript(key: K) -> V? {
        get {
            for cache in caches {
                if var item = cache[key] {
                    return item
                }
            }
            return nil
        }

        set(newValue) {
            for cache in caches {
                cache[key] = newValue
            }
        }
    }

    override func clear() {
        for cache in caches {
            cache.clear()
        }
    }
}
