/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

extension UIView {
    func animateHidden(hidden: Bool, duration: NSTimeInterval) {
        self.hidden = false
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.transitionWithView(self, duration: duration, options: UIViewAnimationOptions.CurveLinear, animations: {
            self.alpha = hidden ? 0 : 1
        }, completion: { _ in
            self.hidden = hidden
        })
    }
}