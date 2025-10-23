// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

struct UX {
    static let doneDialogAnimationDuration: TimeInterval = 0.2
    static let durationToShowDoneDialog: TimeInterval = UX.doneDialogAnimationDuration + 0.8
    static let alphaForFullscreenOverlay: CGFloat = 0.3
    static let dialogCornerRadius: CGFloat = 8
    static let topViewHeight = 364
    static let topViewHeightForSearchMode = 160
    static let topViewWidth = 345
    static let viewHeightForDoneState = 170
    static let pageInfoRowHeight = 64
    static let actionRowHeight = 44
    static let actionRowSpacingBetweenIconAndTitle: CGFloat = 16
    static let actionRowIconSize = 24
    static let rowInset: CGFloat = 16
    static let pageInfoRowLeftInset = UX.rowInset + 6
    static let pageInfoLineSpacing: CGFloat = 2
    static let doneLabelFont = UIFont.boldSystemFont(ofSize: 17)
    static let baseFont = UIFont.systemFont(ofSize: 15)

    static let navBarLandscapeShrinkage = 10 // iOS automatically shrinks nav bar in compact landscape
    static let numberOfActionRows = 5 // One more row than this for the page info row.

    // Small iPhone screens in landscape can only fit 4 rows without resizing the screen. We can fit one more row
    // by shrinking rows, so this shrinkage code is here if needed.
    static let enableResizeRowsForSmallScreens = UX.numberOfActionRows > 4
    static let perRowShrinkageForLandscape = UX.enableResizeRowsForSmallScreens ? 8 : 0
}
