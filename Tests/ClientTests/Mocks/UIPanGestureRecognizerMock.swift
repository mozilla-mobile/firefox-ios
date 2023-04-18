// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class UIPanGestureRecognizerMock: UIPanGestureRecognizer {
    var gestureTranslation: CGPoint?
    var gestureVelocity: CGPoint?

    override func translation(in view: UIView?) -> CGPoint {
        if let gestureTranslation = gestureTranslation {
            return gestureTranslation
        }
        return super.translation(in: view)
    }

    override func velocity(in view: UIView?) -> CGPoint {
        if let gestureVelocity = gestureVelocity {
            return gestureVelocity
        }
        return super.velocity(in: view)
    }
}
