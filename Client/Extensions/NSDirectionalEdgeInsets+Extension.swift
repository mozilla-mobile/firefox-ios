// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension NSDirectionalEdgeInsets {
    /// Convenience initializer to create an instance with all equal inset values.
    /// - Parameter inset: Inset value to set for each direction.
    init(equalInset inset: CGFloat) {
        self.init(top: inset, leading: inset, bottom: inset, trailing: inset)
    }
}
