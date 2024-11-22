// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

/// The view model used to configure a `BottomSheetViewController`
public struct BottomSheetViewModel {
    public struct UX {
        public static let cornerRadius: CGFloat = 8
        public static let animationTransitionDuration: CGFloat = 0.3
        public static let shadowOpacity: Float = 0.3
    }

    public var cornerRadius: CGFloat
    public var animationTransitionDuration: TimeInterval
    public var backgroundColor: UIColor
    public var shouldDismissForTapOutside: Bool
    public var shadowOpacity: Float
    public var closeButtonA11yLabel: String
    public var closeButtonA11yIdentifier: String

    public init(
        cornerRadius: CGFloat = BottomSheetViewModel.UX.cornerRadius,
        animationTransitionDuration: TimeInterval = BottomSheetViewModel.UX.animationTransitionDuration,
        backgroundColor: UIColor = .clear,
        shouldDismissForTapOutside: Bool = true,
        shadowOpacity: Float = BottomSheetViewModel.UX.shadowOpacity,
        closeButtonA11yLabel: String,
        closeButtonA11yIdentifier: String
    ) {
        self.cornerRadius = cornerRadius
        self.animationTransitionDuration = animationTransitionDuration
        self.backgroundColor = backgroundColor
        self.shouldDismissForTapOutside = shouldDismissForTapOutside
        self.shadowOpacity = shadowOpacity
        self.closeButtonA11yLabel = closeButtonA11yLabel
        self.closeButtonA11yIdentifier = closeButtonA11yIdentifier
    }
}
