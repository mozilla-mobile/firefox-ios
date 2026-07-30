// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A view backed by a `CAGradientLayer` so the gradient always tracks the view's bounds without manual frame
/// management. Used both for the sheet background and for the category progress-bar fills.
final class TrackerBlockerGradientView: UIView {
    override class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer {
        // Safe: `layerClass` guarantees the backing layer is a `CAGradientLayer`.
        // swiftlint:disable:next force_cast
        return layer as! CAGradientLayer
    }

    func configure(colors: [UIColor],
                   startPoint: CGPoint = CGPoint(x: 0, y: 0),
                   endPoint: CGPoint = CGPoint(x: 1, y: 1)) {
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
    }
}
