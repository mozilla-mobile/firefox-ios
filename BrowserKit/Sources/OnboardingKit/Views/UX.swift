// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import SwiftUI
import Common

enum UX {
    enum CardView {
        // Base metrics for a standard device (e.g., iPhone 11)
        static let baseWidth: CGFloat = 375
        static let baseHeight: CGFloat = 812

        static let cardHeightRatio: CGFloat = 0.7
        static let spacing: CGFloat = 24
        static let horizontalPadding: CGFloat = 24
        static let verticalPadding: CGFloat = 24
        static let imageHeight: CGFloat = 150
        static let tosImageHeight: CGFloat = 70
        static let cornerRadius: CGFloat = 20
        static let secondaryButtonTopPadding: CGFloat = 8
        static let secondaryButtonBottomPadding: CGFloat = 24

        // Font sizes for base metrics
        static let titleFontSize: CGFloat = 28
        static let bodyFontSize: CGFloat = 16

        static let titleFont = Font(FXFontStyles.Regular.title1.scaledFont())
        static let bodyFont = Font(FXFontStyles.Regular.subheadline.scaledFont())
        static let primaryActionFont = Font(FXFontStyles.Bold.callout.scaledFont())
        static let secondaryActionFont = Font(FXFontStyles.Bold.callout.scaledFont())
    }

    enum SegmentedControl {
        static let outerVStackSpacing: CGFloat = 24
        static let innerVStackSpacing: CGFloat = 6
        static let imageHeight: CGFloat = 150
        static let verticalPadding: CGFloat = 10
        static let checkmarkFontSize: CGFloat = 20

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
}
