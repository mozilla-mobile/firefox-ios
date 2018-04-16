/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct UX {
    static let doneDialogAnimationDuration: TimeInterval = 0.2
    static let durationToShowDoneDialog: TimeInterval = UX.doneDialogAnimationDuration + 0.8
    static let alphaForFullscreenOverlay: CGFloat = 0.3
    static let dialogCornerRadius: CGFloat = 8
    static let topViewHeight = 320
    static let topViewWidth = 345
    static let viewHeightForDoneState = 200
    static let pageInfoRowHeight = 64
    static let actionRowHeight = 44
    static let actionRowSpacingBetweenIconAndTitle: CGFloat = 16
    static let actionRowIconSize = 24
    static let rowInset = 10
    static let pageInfoRowLeftInset = UX.rowInset + 6
    static let pageInfoLineSpacing: CGFloat = 2
    static let doneLabelBackgroundColor = UIColor(red: 76 / 255.0, green: 158 / 255.0, blue: 1.0, alpha: 1.0)
    static let doneLabelFont = UIFont.boldSystemFont(ofSize: 17)
    static let separatorColor = UIColor(white: CGFloat(205.0/255.0), alpha: 1.0)
    static let baseFont = UIFont.systemFont(ofSize: 15)
}
