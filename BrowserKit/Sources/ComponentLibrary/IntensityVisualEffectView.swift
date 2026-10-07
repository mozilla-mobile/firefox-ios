// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Applies a visual effect at a fraction of its full strength, which UIKit doesn't expose, by holding a
/// paused animator at the requested fraction.
public final class IntensityVisualEffectView: UIVisualEffectView {
    private var animator: UIViewPropertyAnimator?

    /// - Parameter intensity: Linear scale, from 0.0 for no effect to 1.0 for the full effect.
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
