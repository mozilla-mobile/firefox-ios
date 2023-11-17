// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIEdgeInsets {
    init(equalInset inset: CGFloat) {
        self.init(top: inset, left: inset, bottom: inset, right: inset)
    }
    
    // Ecosia: Add extension
    init(horizontal inset: CGFloat) {
        self.init(top: 0, left: inset, bottom: 0, right: inset)
    }
}
