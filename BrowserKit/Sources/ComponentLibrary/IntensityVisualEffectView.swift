// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// A visual effect view that applies its effect at a fraction of its full strength, which UIKit doesn't
/// expose. The effect is driven by a paused animator held at the requested fraction.
public final class IntensityVisualEffectView: UIVisualEffectView {
    private var animator: UIViewPropertyAnimator?

    /// - Parameter intensity: The strength of the effect on a linear scale, from 0.0 for none to 1.0
    ///   for the full effect.
    public init(effect: UIVisualEffect, intensity: CGFloat) {
        super.init(effect: nil)
        animator = UIViewPropertyAnimator(duration: 1.0, curve: .linear) { [weak self] in
            self?.effect = effect
        }
        animator?.fractionComplete = intensity
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
