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

// A base implementation of a cache object. Useful if you want to hold a set of caches
// for something (for instance a memory and disk cache)
class GenericCache<K: Hashable, V>: Cache {
    func clear() { }
    subscript(key: K) -> V? {
        get { return nil }
        set { }
    }
}

// Stores a set number of items. Will throws the oldest items away if you try to insert
// more than the requested number
public class LRUCache<K: Hashable, V> : GenericCache<K,V> {
    // Order is important here, so we keep a separate array
    // of items in the order they were added
    private var order = [K]()

    // The actual map this cache is holding data in
    private var map: [K: V]

    private let cacheSize: Int

    init(cacheSize: Int = 10) {
        self.cacheSize = cacheSize;
        self.map = [K: V](minimumCapacity: cacheSize)
    }

    // All access to the cache goes through a subscript operator
    override subscript(key: K) -> V? {
        get {
            return self.map[key]
        }

        set(newValue) {
            while (usedEntries >= cacheSize) {
                if var first = order.first {
                    self.map.removeValueForKey(first)
                    var item = order.removeAtIndex(0)
                }
            }

            // if order contains the key, remove it
            var needsUpdate = false;
            for (index, obj) in enumerate(order) {
                if obj == key {
                    order.removeAtIndex(index);
                    needsUpdate = true;
                    break;
                }
            }

            order.append(key);
            map[key] = newValue;
        }
    }

    public override func clear() {
        order = []
        map.removeAll(keepCapacity: true)
    }
    
    private var usedEntries: Int {
    	return order.count;
    }
}
