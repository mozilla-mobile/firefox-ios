/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

struct UX {
    static let doneDialogAnimationDuration: TimeInterval = 0.2
    static let durationToShowDoneDialog: TimeInterval = UX.doneDialogAnimationDuration + 0.8
    static let alphaForFullscreenOverlay: CGFloat = 0.3
    static let dialogCornerRadius: CGFloat = 8
    static let topViewHeight = 364
    static let topViewWidth = 345
    static let viewHeightForDoneState = 170
    static let pageInfoRowHeight = 64
    static let actionRowHeight = 44
    static let actionRowSpacingBetweenIconAndTitle: CGFloat = 16
    static let actionRowIconSize = 24
    static let rowInset: CGFloat = 16
    static let pageInfoRowLeftInset = UX.rowInset + 6
    static let pageInfoLineSpacing: CGFloat = 2
    static let doneLabelBackgroundColor = UIColor.Photon.Blue40
    static let doneLabelFont = UIFont.boldSystemFont(ofSize: 17)
    static let separatorColor = UIColor.Photon.Grey30
    static let baseFont = UIFont.systemFont(ofSize: 15)
    static let actionRowTextAndIconColor = UIColor.Photon.Grey80
}
