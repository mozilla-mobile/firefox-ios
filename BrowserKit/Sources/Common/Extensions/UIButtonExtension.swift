// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UIButton {
    public func setInsets(
        forContentPadding contentPadding: UIEdgeInsets,
        imageTitlePadding: CGFloat) {
        let isLTR = effectiveUserInterfaceLayoutDirection == .leftToRight

        contentEdgeInsets = UIEdgeInsets(
            top: contentPadding.top,
            left: isLTR ? contentPadding.left : contentPadding.right + imageTitlePadding,
            bottom: contentPadding.bottom,
            right: isLTR ? contentPadding.right + imageTitlePadding : contentPadding.left
        )

        titleEdgeInsets = UIEdgeInsets(
            top: 0,
            left: isLTR ? imageTitlePadding : -imageTitlePadding,
            bottom: 0,
            right: isLTR ? -imageTitlePadding: imageTitlePadding
        )
    }
}
