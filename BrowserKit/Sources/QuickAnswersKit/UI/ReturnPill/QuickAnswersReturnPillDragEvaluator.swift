// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import CoreGraphics

enum QuickAnswersReturnPillDragEvaluator {
    static let removeDistance: CGFloat = 100
    static let removeVelocity: CGFloat = 800

    static func shouldRemove(translation: CGPoint, velocity: CGPoint) -> Bool {
        return hypot(translation.x, translation.y) >= removeDistance
            || hypot(velocity.x, velocity.y) >= removeVelocity
    }
}
