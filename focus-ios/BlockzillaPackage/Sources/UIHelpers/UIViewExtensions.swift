/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

public extension UIView {
    /// Animate the opacity of the view, updating its hidden state on completion.
    func animateHidden(_ hidden: Bool, duration: TimeInterval, completion: (() -> Void)? = nil) {
        self.isHidden = false

        UIView.transition(
            with: self,
            duration: duration,
            options: .beginFromCurrentState,
            animations: {
                self.alpha = hidden ? 0 : 1
            },
            completion: { finished in
                // Only update the hidden state if the animation finished.
                // Otherwise, a new animation may have started on top of this one, in which case
                // that animation will set the final state.
                if finished {
                    self.isHidden = hidden
                }
                completion?()
            }
        )
    }

    func applyGradient(colors: [UIColor]) {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0)
        gradientLayer.frame = self.bounds
        self.layer.insertSublayer(gradientLayer, at: 0)
    }

    func removeGradient() {
        if let  buttonSublayers = self.layer.sublayers {
            for layer in buttonSublayers where layer is CAGradientLayer {
                layer.removeFromSuperlayer()
            }
        }
    }
}
