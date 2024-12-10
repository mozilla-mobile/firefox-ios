// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public extension Array where Element: Comparable {
    func sameElements(_ arr: [Element]) -> Bool {
        guard self.count == arr.count else { return false }
        let sorted = self.sorted(by: <)
        let arrSorted = arr.sorted(by: <)
        for elements in sorted.zip(arrSorted) where elements.0 != elements.1 {
            return false
        }
        return true
    }
}

public extension Array {
    func contains(_ x: Element, f: (Element, Element) -> Bool) -> Bool {
        for y in self where f(x, y) {
            return true
        }
        return false
    }

    // Performs a union operator using the result of f(Element) as the value to base uniqueness on.
    func union<T: Hashable>(_ arr: [Element], f: (Element) -> T) -> [Element] {
        let result = self + arr
        return result.unique(f)
    }

    // Returns unique values in an array using the result of f()
    func unique<T: Hashable>(_ f: (Element) -> T) -> [Element] {
        var map: [T: Element] = [T: Element]()
        return self.compactMap { a in
            let t = f(a)
            if map[t] == nil {
                map[t] = a
                return a
            } else {
                return nil
            }
        }
    }

    /// Removes the first element of the Array and returns the rest of the array.
    /// If the array is empty, it returns an empty array.
    var tail: Array {
        return Array(self.dropFirst())
    }
}

public extension Sequence where Iterator.Element: Hashable {
    /// Return a de-duplicated sequence with the order preserved. `o(N)` complexity.
    func uniqued() -> [Iterator.Element] {
        var seen: Set<Iterator.Element> = []
        return filter { seen.insert($0).inserted }
    }
}

public extension Sequence {
    func every(_ f: (Self.Iterator.Element) -> Bool) -> Bool {
        for x in self where !f(x) {
            return false
        }
        return true
    }
}

public extension Collection {
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public extension Array where Element: NSAttributedString {
    /// If the array is made up of `NSAttributedStrings`, this allows the reduction
    /// of the array into a single `NSAttributedString`.
    func joined() -> NSAttributedString {
        return self.reduce(NSMutableAttributedString()) { result, element in
            result.append(element)
            return result
        }
    }
}
