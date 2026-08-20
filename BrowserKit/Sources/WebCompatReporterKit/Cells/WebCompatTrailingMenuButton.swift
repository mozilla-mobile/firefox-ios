// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A pull-down button that hangs its menu off its own trailing edge. `UIKit` otherwise lays the
/// menu out against the source control, which centres it under a button spanning a whole row.
final class WebCompatTrailingMenuButton: UIButton {
    override func menuAttachmentPoint(for configuration: UIContextMenuConfiguration) -> CGPoint {
        let isRightToLeft = effectiveUserInterfaceLayoutDirection == .rightToLeft
        return CGPoint(x: isRightToLeft ? bounds.minX : bounds.maxX, y: bounds.maxY)
    }
}
