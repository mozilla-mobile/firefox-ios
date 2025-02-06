// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct List<E>: Decodable where E: Decodable {
    var items = [E]()

    init(from: Decoder) throws {
        var root = try from.unkeyedContainer()
        while !root.isAtEnd {
            if let item = try? root.decode(E.self) {
                items.append(item)
            } else {
                _ = try root.nestedContainer(keyedBy: Discard.self)
            }
        }
    }
}

private enum Discard: CodingKey { }
