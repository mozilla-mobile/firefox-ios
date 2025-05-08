// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public struct AddressToolbarUXConfiguration {
    let toolbarCornerRadius: CGFloat
    let browserActionsAddressBarDividerWidth: CGFloat
    let isLocationTextCentered: Bool
    let shouldBlur: Bool
    let backgroundAlpha: CGFloat

    public static func experiment(backgroundAlpha: CGFloat = 1.0) -> AddressToolbarUXConfiguration {
        AddressToolbarUXConfiguration(
            toolbarCornerRadius: 12.0,
            browserActionsAddressBarDividerWidth: 0.0,
            isLocationTextCentered: true,
            shouldBlur: true,
            backgroundAlpha: backgroundAlpha
        )
    }

    public static func `default`(backgroundAlpha: CGFloat = 1.0) -> AddressToolbarUXConfiguration {
        AddressToolbarUXConfiguration(
            toolbarCornerRadius: 8.0,
            browserActionsAddressBarDividerWidth: 4.0,
            isLocationTextCentered: false,
            shouldBlur: false,
            backgroundAlpha: backgroundAlpha
        )
    }

    func addressToolbarBackgroundColor(theme: any Theme) -> UIColor {
        let blurBackgroundColor = theme.colors.layer3.withAlphaComponent(backgroundAlpha)
        let centerBackgroundColor = shouldBlur ? blurBackgroundColor : theme.colors.layer3

        return isLocationTextCentered ? centerBackgroundColor : theme.colors.layer1
    }

    func locationContainerBackgroundColor(theme: any Theme) -> UIColor {
        return isLocationTextCentered ? theme.colors.layer2 : theme.colors.layerSearch
    }
}
