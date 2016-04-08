/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

class JumpAndSpinAnimator: Animatable {
    private let AnimationDuration: Double = 0.5
    private let AnimationOffset: CGFloat = -80

    static func animateFromView(view: UIView, offset: CGFloat, completion: ((Bool) -> Void)?) {
        let animator = JumpAndSpinAnimator()
        animator.animateFromView(view, offset: offset, completion: completion)
    }

    func animateFromView(viewToAnimate: UIView, offset: CGFloat? = nil, completion: ((Bool) -> Void)?) {
        let offset  = offset ?? AnimationOffset
        let offToolbar = CGAffineTransformMakeTranslation(0, offset)

        UIView.animateWithDuration(AnimationDuration, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 2.0, options: [], animations: { () -> Void in
            viewToAnimate.transform = offToolbar
            let rotation = CABasicAnimation(keyPath: "transform.rotation")
            rotation.toValue = CGFloat(M_PI * 2.0)
            rotation.cumulative = true
            rotation.duration = self.AnimationDuration + 0.075
            rotation.repeatCount = 1.0
            rotation.timingFunction = CAMediaTimingFunction(controlPoints: 0.32, 0.70 ,0.18 ,1.00)
            viewToAnimate.layer.addAnimation(rotation, forKey: "rotateStar")
            }, completion: { finished in
                UIView.animateWithDuration(self.AnimationDuration, delay: 0.15, usingSpringWithDamping: 0.7, initialSpringVelocity: 0, options: [], animations: { () -> Void in
                    viewToAnimate.transform = CGAffineTransformIdentity
                    }, completion: completion)
        })
    }
}
