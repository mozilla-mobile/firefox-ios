/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public extension Array {

    func find(_ f: (Iterator.Element) -> Bool) -> Iterator.Element? {
        for x in self {
            if f(x) {
                return x
            }
        }
        return nil
    }

    // Laughably inefficient, but good enough for a handful of items.
    func sameElements(_ arr: [Element], f: (Element, Element) -> Bool) -> Bool {
        return self.count == arr.count && every { arr.contains($0, f: f) }
    }

    func contains(_ x: Element, f: (Element, Element) -> Bool) -> Bool {
        for y in self {
            if f(x, y) {
                return true
            }
        }
        return false
    }

    // Performs a union operator using the result of f(Element) as the value to base uniqueness on.
    func union<T: Hashable>(_ arr: [Element], f: ((Element) -> T)) -> [Element] {
        let result = self + arr
        return result.unique(f)
    }

    // Returns unique values in an array using the result of f()
    func unique<T: Hashable>(_ f: ((Element) -> T)) -> [Element] {
        var map: [T: Element] = [T: Element]()
        return self.flatMap { a in
            let t = f(a)
            if map[t] == nil {
                map[t] = a
                return a
            } else {
                return nil
            }
        }
    }

}

public extension Sequence {
    func every(_ f: (Self.Iterator.Element) -> Bool) -> Bool {
        for x in self {
            if !f(x) {
                return false
            }
        }
        return true
    }
}
