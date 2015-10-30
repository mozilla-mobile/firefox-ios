/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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
public class WeakList<T: AnyObject>: SequenceType {
    private var items = [WeakRef<T>]()

    public init() {}

    /**
     * Adds an item to the list.
     * Note that every insertion iterates through the list to find any "holes" (items that have
     * been deallocated) to reuse them, so this class may not be appropriate in situations where
     * insertion is frequent.
     */
    public func insert(item: T) {
        for wrapper in items {
            // Reuse any existing slots that have been deallocated.
            if wrapper.value == nil {
                wrapper.value = item
                return
            }
        }

        items.append(WeakRef(item))
    }

    public func generate() -> AnyGenerator<T> {
        var index = 0

        return anyGenerator(){
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

private class WeakRef<T: AnyObject> {
    weak var value: T?

    init(_ value: T) {
        self.value = value
    }
}