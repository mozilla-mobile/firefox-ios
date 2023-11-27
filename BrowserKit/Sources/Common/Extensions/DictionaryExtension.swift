// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public extension Dictionary {
    func merge(with dictionary: Dictionary) -> Dictionary {
        return self.merging(dictionary) { (_, new) in new }
    }
}
