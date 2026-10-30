// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// Applies a visual effect at a fraction of its full strength, which UIKit doesn't expose, by holding a
/// paused animator at the requested fraction.
public final class IntensityVisualEffectView: UIVisualEffectView {
    private var animator: UIViewPropertyAnimator?
    private let targetEffect: UIVisualEffect
    private let intensity: CGFloat

    /// - Parameter intensity: Linear scale, from 0.0 for no effect to 1.0 for the full effect.
    public init(effect: UIVisualEffect, intensity: CGFloat) {
        self.targetEffect = effect
        self.intensity = intensity
        super.init(effect: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// The effect layers are rebuilt from the full `effect` when the view moves to a window, dropping the
    /// paused animation, so the animator is set up again once the view is in a window.
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        animator?.stopAnimation(true)
        animator = nil
        effect = nil
        guard window != nil else { return }
        let animator = UIViewPropertyAnimator(duration: 1.0, curve: .linear) { [weak self] in
            self?.effect = self?.targetEffect
        }
        animator.fractionComplete = intensity
        self.animator = animator
    }
}
