// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Common

enum UX {
    enum CardView {
        static let baseWidth: CGFloat = 375
        static let baseHeight: CGFloat = 812
        static let landscapeWidthRatio: CGFloat = 0.75
        static let portraitWidthRatio: CGFloat = 0.7
        static let maxWidth: CGFloat = 508
        static let landscapeHeightRatio: CGFloat = 0.85
        static let portraitHeightRatio: CGFloat = 0.7
        static let maxHeight: CGFloat = 712

        static let cardTopPadding: CGFloat = 32
        static func cardSecondaryContainerPadding(for sizeCategory: ContentSizeCategory) -> CGFloat {
            switch sizeCategory {
            case .accessibilityExtraExtraExtraLarge, .accessibilityExtraExtraLarge, .accessibilityExtraLarge:
                return 0
            default:
                return 32
            }
        }
        static let titleTopPadding: CGFloat = 80
        static let titleAlignmentMinHeightPadding: CGFloat = 80
        static let cardHeightRatio: CGFloat = 0.8
        static let spacing: CGFloat = 24
        static let regularSizeSpacing: CGFloat = 48
        static let tosSpacing: CGFloat = 48
        static let horizontalPadding: CGFloat = 24
        static let verticalPadding: CGFloat = 24
        static let imageHeight: CGFloat = 150
        static let tosImageHeight: CGFloat = 70
        static let cornerRadius: CGFloat = 20
        static let secondaryButtonTopPadding: CGFloat = 8
        static let secondaryButtonBottomPadding: CGFloat = 24
        static let primaryButtonWidthiPad: CGFloat = 313

        // Font sizes for base metrics
        static let titleFontSize: CGFloat = 28
        static let bodyFontSize: CGFloat = 16

        static let titleFont = FXFontStyles.Bold.title1.scaledSwiftUIFont()
        static let bodyFont = FXFontStyles.Regular.subheadline.scaledSwiftUIFont()
        static let primaryActionFont = FXFontStyles.Bold.callout.scaledSwiftUIFont()
        static let secondaryActionFont = FXFontStyles.Bold.callout.scaledSwiftUIFont()
    }

    enum SegmentedControl {
        static let outerVStackSpacing: CGFloat = 20
        static let innerVStackSpacing: CGFloat = 6
        static let imageHeight: CGFloat = 150
        static let verticalPadding: CGFloat = 10
        static let checkmarkFontSize: CGFloat = 20
        static let selectedColorOpacity: CGFloat = 0.8
        static let buttonMinHeight: CGFloat = 140
        static let textAreaMinHeight: CGFloat = 60
        static let containerSpacing: CGFloat = 0

        static let radioButtonSelectedImage = "radioButtonSelected"
        static let radioButtonNotSelectedImage = "radioButtonNotSelected"
    }

    struct Onboarding {
        struct Spacing {
            static let standard: CGFloat = 20
            static let small: CGFloat = 10
            static let contentPadding: CGFloat = 24
            static let buttonHeight: CGFloat = 44
            static let vertical: CGFloat = 16
        }

        struct Layout {
            static let logoSize = CGSize(width: 150, height: 150)
            static let buttonCornerRadius: CGFloat = 12
        }
    }

    struct LaunchScreen {
        struct Logo {
            static let size: CGFloat = 125
            static let rotationDuration: TimeInterval = 2.0
            static let rotationAngle: Double = 360
            static let image = "firefoxLoader"
        }
    }

    enum DragCancellableButton {
        static let verticalPadding: CGFloat = 12
        static let horizontalPadding: CGFloat = 12
        static let cornerRadius: CGFloat = 8
        static let dragThreshold: CGFloat = 5
        static let resetDelay: TimeInterval = 0.1
    }
}
