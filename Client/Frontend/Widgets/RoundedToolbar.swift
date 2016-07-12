/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class RoundedToolbar: UIToolbar {

    private var layerBackgroundColor: UIColor?

    override var backgroundColor: UIColor? {
        get { return layerBackgroundColor }

        set {
            layerBackgroundColor = newValue
        }
    }

    var cornerRadius: CGSize = CGSize.zero

    var cornersToRound: UIRectCorner = [.allCorners]

    /**
     * The toolbar on the menu requires rounded corners on the top and bottom so we need a custom
     * view to do this
     */
    override func draw(_ rect: CGRect) {
        addRoundedCorners(cornersToRound: cornersToRound, cornerRadius: cornerRadius, color: layerBackgroundColor ?? UIColor.white())
    }


}
