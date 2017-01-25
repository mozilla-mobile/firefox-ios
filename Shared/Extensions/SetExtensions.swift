/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

public extension SetIterator {
    mutating func take(_ n: Int) -> [Element]? {
        precondition(n >= 0)

        if n == 0 {
            return []
        }

        var count: Int = 0
        var out: [Element] = []

        while count < n {
            count += 1
            guard let val = self.next() else {
                if out.isEmpty {
                    return nil
                }
                return out
            }
            out.append(val)
        }
        return out
    }
}

public extension Set {
    func withSubsetsOfSize(_ n: Int, f: (Set<Iterator.Element>) -> Void) {
        precondition(n > 0)

        if self.isEmpty {
            return
        }

        if n > self.count {
            f(self)
            return
        }

        if n == 1 {
            self.forEach { f(Set([$0])) }
            return
        }

        var generator = self.makeIterator()
        while let next = generator.take(n) {
            if !next.isEmpty {
                f(Set(next))
            }
        }
    }

    func subsetsOfSize(_ n: Int) -> [Set<Iterator.Element>] {
        precondition(n > 0)

        if self.isEmpty {
            return []
        }

        if n > self.count {
            return [self]
        }

        if n == 1 {
            // Special case.
            return self.map({ Set([$0]) })
        }

        var generator = self.makeIterator()
        var out: [Set<Iterator.Element>] = []
        out.reserveCapacity(self.count / n)
        while let next = generator.take(n) {
            if !next.isEmpty {
                out.append(Set(next))
            }
        }
        return out
    }
}
