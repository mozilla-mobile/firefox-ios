/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension UIView {
    func animateHidden(_ hidden: Bool, duration: TimeInterval, completion: (() -> Void)? = nil) {
        self.isHidden = false
        UIView.transition(with: self, duration: duration, options: .beginFromCurrentState, animations: {
            self.alpha = hidden ? 0 : 1
        }, completion: { finished in
            // Only update the hidden state if the animation finished.
            // Otherwise, a new animation may have started on top of this one, in which case
            // that animation will set the final state.
            if finished {
                self.isHidden = hidden
            }
            completion?()
        })
    }
}
