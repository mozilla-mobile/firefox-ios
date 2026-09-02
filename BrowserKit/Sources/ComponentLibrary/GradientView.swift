// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// A view backed by a `CAGradientLayer`, so the gradient always tracks the view's bounds without the manual
/// frame bookkeeping that an inserted sublayer requires.
///
/// The gradient composites over the view's `backgroundColor`, so a translucent `Gradient` can be layered on top
/// of a solid fill by setting both.
public final class GradientView: UIView {
    override public class var layerClass: AnyClass { CAGradientLayer.self }

    private var gradientLayer: CAGradientLayer {
        // Safe: `layerClass` guarantees the backing layer is a `CAGradientLayer`.
        // swiftlint:disable:next force_cast
        return layer as! CAGradientLayer
    }

    /// - Parameters:
    ///   - gradient: the colour stops to draw. Pass `nil` to clear the gradient and leave only `backgroundColor`
    ///     visible, e.g. for a theme that doesn't define the gradient token.
    ///   - startPoint: where the first stop sits, in unit coordinates.
    ///   - endPoint: where the last stop sits, in unit coordinates.
    ///   - locations: optional stop positions in `0...1`. `nil` spaces the stops evenly.
    public func configure(gradient: Gradient?,
                          startPoint: CGPoint = CGPoint(x: 0, y: 0),
                          endPoint: CGPoint = CGPoint(x: 1, y: 1),
                          locations: [NSNumber]? = nil) {
        gradientLayer.colors = gradient?.cgColors
        gradientLayer.locations = locations
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
    }
}
