/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

public class InfoCollections {
    private let collections: [String: Timestamp]

    init(collections: [String: Timestamp]) {
        self.collections = collections
    }

    public class func fromJSON(_ json: JSON) -> InfoCollections? {
        if let dict = json.asDictionary {
            var coll = [String: Timestamp]()
            for (key, value) in dict {
                if let value = value.asDouble {
                    coll[key] = Timestamp(value * 1000)
                } else {
                    return nil       // Invalid, so bail out.
                }
            }
            return InfoCollections(collections: coll)
        }
        return nil
    }

    public func collectionNames() -> [String] {
        return Array(self.collections.keys)
    }

    public func modified(_ collection: String) -> Timestamp? {
        return self.collections[collection]
    }

    // Two I/Cs are the same if they have the same modified times for a set of
    // collections. If no collections are specified, they're considered the same
    // if the other I/C has the same values for this I/C's collections, and
    // they have the same collection array.
    public func same(_ other: InfoCollections, collections: [String]?) -> Bool {
        if let collections = collections {
            return collections.every({ self.modified($0) == other.modified($0) })
        }

        // Same collections?
        let ours = self.collectionNames()
        let theirs = other.collectionNames()
        return ours.sameElements(theirs, f: ==) && same(other, collections: ours)
    }
}
