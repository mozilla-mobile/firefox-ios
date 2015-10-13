/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public extension Array {
    // Laughably inefficient, but good enough for a handful of items.
    func sameElements(arr: [Element], f: (Element, Element) -> Bool) -> Bool {
        return self.count == arr.count && every { arr.contains($0, f: f) }
    }

    func contains(x: Element, f: (Element, Element) -> Bool) -> Bool {
        for y in self {
            if f(x, y) {
                return true
            }
        }
        return false
    }

    func every(f: (Element) -> Bool) -> Bool {
        for x in self {
            if !f(x) {
                return false
            }
        }
        return true
    }
}