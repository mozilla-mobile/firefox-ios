// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A scroll view that adds a fade at top or bottom when it scroll
/// to indicate more content is available to user
public class FadeScrollView: UIScrollView, UIScrollViewDelegate {
    private let fadePercentage: Double = 0.1
    private let gradientLayer = CAGradientLayer()
    private let transparentColor = UIColor.clear.cgColor
    private let opaqueColor = UIColor.black.cgColor

    private var needsToScroll: Bool {
        return frame.size.height >= contentSize.height
    }

    private var isAtBottom: Bool {
        return contentOffset.y + frame.size.height >= contentSize.height
    }

    private var isAtTop: Bool {
        return contentOffset.y <= 0
    }

    private var topOpacity: CGColor {
        let alpha: CGFloat = (needsToScroll || isAtTop) ? 1 : 0
        return UIColor(white: 0, alpha: alpha).cgColor
    }

    private var bottomOpacity: CGColor {
        let alpha: CGFloat = (needsToScroll || isAtBottom) ? 1 : 0
        return UIColor(white: 0, alpha: alpha).cgColor
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        self.delegate = self
        let maskLayer = CALayer()
        maskLayer.frame = bounds

        gradientLayer.frame = CGRect(x: bounds.origin.x,
                                     y: 0,
                                     width: bounds.size.width,
                                     height: bounds.size.height)
        gradientLayer.colors = [topOpacity, opaqueColor, opaqueColor, bottomOpacity]
        gradientLayer.locations = [0,
                                   NSNumber(value: fadePercentage),
                                   NSNumber(value: 1 - fadePercentage),
                                   1]
        maskLayer.addSublayer(gradientLayer)

        layer.mask = maskLayer
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        gradientLayer.colors = [topOpacity, opaqueColor, opaqueColor, bottomOpacity]
    }
}
