// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// We need a subclass so we can setup the shadows correctly
// This subclass creates a strong shadow on the URLBar
class TabLocationContainerView: UIView {

    private struct LocationContainerUX {
        static let CornerRadius: CGFloat = 8
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        let layer = self.layer
        layer.cornerRadius = LocationContainerUX.CornerRadius
        layer.masksToBounds = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
