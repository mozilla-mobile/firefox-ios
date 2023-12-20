// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation

enum ExpandButtonState {
    case trailing
    case down

    var image: UIImage? {
        switch self {
        case .trailing:
            return UIImage(named: StandardImageIdentifiers.Large.chevronRight)?
                .withRenderingMode(.alwaysTemplate)
                .imageFlippedForRightToLeftLayoutDirection()
        case .down:
            return UIImage(named: StandardImageIdentifiers.Large.chevronDown)?.withRenderingMode(.alwaysTemplate)
        }
    }
}
