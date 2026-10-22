// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UITraitCollection {
    var duoExpanded: Bool {
        userInterfaceIdiom == .phone
            && horizontalSizeClass == .regular
            && verticalSizeClass == .regular
    }

    /// True when the system lays its status bar out vertically on a side of the screen ( folded iPhone Duo).
    var hasVerticalSystemBar: Bool {
        #if XCODE_2710 || XCODE_2720
        if #available(iOS 27.1, *) {
            return verticalBarEdge != .unspecified
        }
        #endif
        return false
    }
}
