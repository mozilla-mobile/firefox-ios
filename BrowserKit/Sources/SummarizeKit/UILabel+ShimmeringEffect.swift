// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

extension UILabel {
    /// Add a shimmer endless animation with the provided colors and locations
    ///
    /// - Parameters:
    ///   - light: The color to apply to the label when the light is spreading on the label
    ///   - dark: The color to apply to portion of the label not affected by light.
    func startShimmering(light: UIColor, dark: UIColor) {
        stopShimmering()
        let light = light.cgColor
        let dark = dark.cgColor

        let gradient = CAGradientLayer()
        gradient.colors = [dark, light, dark]
        gradient.frame = CGRect(
            x: -bounds.size.width,
            y: 0,
            width: 3 * bounds.size.width,
            height: bounds.size.height
        )
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.locations = [0.4, 0.5, 0.6]
        layer.mask = gradient

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0.0, 0.1, 0.2]
        animation.toValue = [0.8, 0.9, 1.0]

        animation.duration = 1.5
        animation.repeatCount = HUGE
        animation.isRemovedOnCompletion = false
        gradient.add(animation, forKey: "shimmer")
    }

    func stopShimmering() {
        (layer.mask as? CAGradientLayer)?.removeAnimation(forKey: "shimmer")
        layer.mask = nil
    }
}
