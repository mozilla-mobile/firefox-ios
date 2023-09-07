// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A label that adds a fade at bottom to indicate more content is available to user
public class FakespotFadeLabel: UILabel {
    private let fadePercentage: Double = 0.5
    private let gradientLayer = CAGradientLayer()
    private let transparentColor = UIColor.clear.cgColor
    private let opaqueColor = UIColor.black.cgColor
    private let maskLayer = CALayer()

    private var bottomOpacity: CGColor {
        if isShowingFade {
            return UIColor.clear.cgColor
        }

        return opaqueColor
    }

    var isShowingFade = true

    override public func layoutSubviews() {
        super.layoutSubviews()

        maskLayer.frame = bounds

        gradientLayer.frame = CGRect(x: bounds.origin.x,
                                     y: 0,
                                     width: bounds.size.width,
                                     height: bounds.size.height)
        gradientLayer.colors = [opaqueColor, opaqueColor, opaqueColor, bottomOpacity]
        gradientLayer.locations = [0,
                                   NSNumber(value: fadePercentage),
                                   NSNumber(value: 1 - fadePercentage),
                                   1]
        maskLayer.addSublayer(gradientLayer)

        layer.mask = maskLayer
    }
}
