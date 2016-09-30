/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension UIView {
    func animateHidden(_ hidden: Bool, duration: TimeInterval) {
        self.isHidden = false
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.transition(with: self, duration: duration, options: UIViewAnimationOptions.curveLinear, animations: {
            self.alpha = hidden ? 0 : 1
        }, completion: { _ in
            self.isHidden = hidden
        })
    }
}
