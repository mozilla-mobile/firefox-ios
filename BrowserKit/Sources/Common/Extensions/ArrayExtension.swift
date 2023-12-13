// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public extension Array {
    func find(_ f: (Iterator.Element) -> Bool) -> Iterator.Element? {
        for x in self where f(x) {
            return x
        }
        return nil
    }
}
