// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common

struct TabWebViewPreviewAppearanceConfiguration {
    private struct UX {
        static let baselineAddressBarCornerRadius: CGFloat = 8
        static let versionAddressBarCornerRadius: CGFloat = 12
    }
    let containerStackViewBackgroundColor: UIColor
    let addressBarBackgroundColor: UIColor

    /// A static computed property that returns the corner radius for the address bar
    /// based on the current layout style.
    ///
    /// - Returns: A `CGFloat` value representing the corner radius.
    static var addressBarCornerRadius: CGFloat {
        UX.versionAddressBarCornerRadius
    }

    /// Generates an appearance configuration based on the provided theme.
    ///
    /// - Parameter theme: The theme object containing color definitions.
    /// - Returns: A `TabWebViewPreviewAppearanceConfiguration`
    /// instance configured with colors based on the theme and layout style.
    static func getAppearance(basedOn theme: Theme) -> Self {
        let colors = theme.colors
        return Self(
            containerStackViewBackgroundColor: colors.layer3,
            addressBarBackgroundColor: colors.layer2
        )
    }
}
