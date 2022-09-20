/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

extension UICollectionView {
    var ecosiaHomeMaxWidth: CGFloat {
        let insets = max(max(safeAreaInsets.left, safeAreaInsets.right), 16) * 2
        let maxWidth = bounds.width - insets
        
        if traitCollection.userInterfaceIdiom == .pad {
            return min(maxWidth, 544)
        } else if traitCollection.verticalSizeClass == .compact {
            return min(maxWidth, 375)
        } else {
            return maxWidth
        }
    }
}
