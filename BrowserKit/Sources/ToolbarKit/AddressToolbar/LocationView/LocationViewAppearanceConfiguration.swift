// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

struct LocationViewAppearanceConfiguration {
    let backgroundColor: UIColor
    let placeholderColor: UIColor
    let etpIconImageColor: UIColor
    let etpIconTintColor: UIColor
    let gradientColors: [CGColor]

    static func getAppearanceForVersion1(theme: Theme) -> Self {
        let colors = theme.colors
        return Self(
            backgroundColor: colors.layer2,
            placeholderColor: colors.textPrimary,
            etpIconImageColor: colors.textSecondary,
            etpIconTintColor: colors.textSecondary,
            gradientColors: Gradient(
                colors: [
                    colors.layer2.withAlphaComponent(1),
                    colors.layer2.withAlphaComponent(0)
                ]
            ).cgColors
        )
    }

    static func getAppearanceForBaseline(theme: Theme) -> Self {
        let colors = theme.colors
        return Self(
            backgroundColor: colors.layerSearch,
            placeholderColor: colors.textSecondary,
            etpIconImageColor: colors.textPrimary,
            etpIconTintColor: colors.textPrimary,
            gradientColors: colors.layerGradientURL.cgColors.reversed()
        )
    }
}
