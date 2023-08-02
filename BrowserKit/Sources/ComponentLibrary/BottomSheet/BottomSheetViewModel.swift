// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public struct BottomSheetViewModel {
    private struct UX {
        static let cornerRadius: CGFloat = 8
        static let animationTransitionDuration: CGFloat = 0.3
        static let shadowOpacity: Float = 0.3
    }

    public var cornerRadius: CGFloat
    public var contentHeight: CGFloat
    public var animationTransitionDuration: TimeInterval
    public var backgroundColor: UIColor
    public var shouldDismissForTapOutside: Bool
    public var isPanningUpEnabled: Bool
    public var shadowOpacity: Float
    public var closeButtonA11yLabel: String

    public init(closeButtonA11yLabel: String,
                isPanningUpEnabled: Bool = false,
                contentHeight: CGFloat = UIScreen.main.bounds.height * 0.5) {
        cornerRadius = BottomSheetViewModel.UX.cornerRadius
        animationTransitionDuration = BottomSheetViewModel.UX.animationTransitionDuration
        backgroundColor = .clear
        shouldDismissForTapOutside = true
        shadowOpacity = BottomSheetViewModel.UX.shadowOpacity
        self.closeButtonA11yLabel = closeButtonA11yLabel
        self.isPanningUpEnabled = isPanningUpEnabled
        self.contentHeight = contentHeight
    }

    public init(cornerRadius: CGFloat,
                contentHeight: CGFloat,
                animationTransitionDuration: TimeInterval,
                backgroundColor: UIColor,
                shouldDismissForTapOutside: Bool,
                isPanningUpEnabled: Bool,
                shadowOpacity: Float,
                closeButtonA11yLabel: String) {
        self.cornerRadius = cornerRadius
        self.contentHeight = contentHeight
        self.animationTransitionDuration = animationTransitionDuration
        self.backgroundColor = backgroundColor
        self.shouldDismissForTapOutside = shouldDismissForTapOutside
        self.isPanningUpEnabled = isPanningUpEnabled
        self.shadowOpacity = shadowOpacity
        self.closeButtonA11yLabel = closeButtonA11yLabel
    }
}
