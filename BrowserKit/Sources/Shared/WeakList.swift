// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/**
 * A list that weakly holds references to its items.
 * Note that while the references themselves are cleared, their wrapper objects
 * are not (though they are reused). Also note that since slots are reused,
 * order is not preserved.
 *
 * This class crashes at runtime with EXC_BAD_ACCESS if a protocol is given as
 * the type T. Make sure to use a class type.
 */
open class WeakList<T: AnyObject>: Sequence {
    private var items = [WeakRef<T>]()

    public init() {}

    /**
     * Adds an item to the list.
     * Note that every insertion iterates through the list to find any "holes" (items that have
     * been deallocated) to reuse them, so this class may not be appropriate in situations where
     * insertion is frequent.
     */
    open func insert(_ item: T, at: Int? = nil) {
        // Reuse any existing slots that have been deallocated.
        for wrapper in items where wrapper.value == nil {
            wrapper.value = item
            return
        }

        if let at = at, 0...items.endIndex ~= at {
            items.insert(WeakRef(item), at: at)
        } else {
            items.append(WeakRef(item))
        }
    }

    open var count: Int {
        return items.count
    }

    open var isEmpty: Bool {
        return items.isEmpty
    }

    open func removeAll() {
        items.removeAll()
    }

    @discardableResult
    open func remove(_ item: T) -> Int? {
        guard let index = self.index(of: item) else { return nil }
        items.remove(at: index)
        return index
    }

    open func at(_ index: Int) -> T? {
        return items[safe: index]?.value
    }

    open func index(of item: T) -> Int? {
        return items.firstIndex { $0.value === item }
    }

    open func firstIndexDel(where predicate: (WeakRef<T>) -> Bool) -> Int? {
        return items.firstIndex(where: predicate)
    }

    open func makeIterator() -> AnyIterator<T> {
        var index = 0

        return AnyIterator {
            if index >= self.items.count {
                return nil
            }

            for i in index..<self.items.count {
                if let value = self.items[i].value {
                    index = i + 1
                    return value
                }
            }

            index = self.items.count
            return nil
        }
    }
}

open class WeakRef<T: AnyObject> {
    public weak var value: T?

    public init(_ value: T) {
        self.value = value
    }
}
