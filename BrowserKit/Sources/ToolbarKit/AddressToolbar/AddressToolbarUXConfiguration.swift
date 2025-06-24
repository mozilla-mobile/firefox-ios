// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public struct AddressToolbarUXConfiguration {
    let toolbarCornerRadius: CGFloat
    let browserActionsAddressBarDividerWidth: CGFloat
    let isLocationTextCentered: Bool
    let locationTextFieldTrailingPadding: CGFloat
    let shouldBlur: Bool
    let backgroundAlpha: CGFloat

    public static func experiment(backgroundAlpha: CGFloat = 1.0,
                                  shouldBlur: Bool = false) -> AddressToolbarUXConfiguration {
        AddressToolbarUXConfiguration(
            toolbarCornerRadius: 12.0,
            browserActionsAddressBarDividerWidth: 0.0,
            isLocationTextCentered: true,
            locationTextFieldTrailingPadding: 0,
            shouldBlur: shouldBlur,
            backgroundAlpha: backgroundAlpha
        )
    }

    public static func `default`(backgroundAlpha: CGFloat = 1.0,
                                 shouldBlur: Bool = false) -> AddressToolbarUXConfiguration {
        AddressToolbarUXConfiguration(
            toolbarCornerRadius: 8.0,
            browserActionsAddressBarDividerWidth: 4.0,
            isLocationTextCentered: false,
            locationTextFieldTrailingPadding: 8.0,
            shouldBlur: shouldBlur,
            backgroundAlpha: backgroundAlpha
        )
    }

    func addressToolbarBackgroundColor(theme: any Theme) -> UIColor {
        var backgroundColor = isLocationTextCentered ? theme.colors.layerSurfaceLow : theme.colors.layer1
        if shouldBlur {
            backgroundColor = backgroundColor.withAlphaComponent(backgroundAlpha)
        }

        return backgroundColor
    }

    func locationContainerBackgroundColor(theme: any Theme) -> UIColor {
        return isLocationTextCentered ? theme.colors.layerSurfaceMedium : theme.colors.layerSearch
    }

    public func locationViewVerticalPaddings(addressBarPosition: AddressToolbarPosition) -> (top: CGFloat, bottom: CGFloat) {
        return switch addressBarPosition {
        case .top:
            (top: 8, bottom: 8)
        case .bottom:
            (top: 8, bottom: 4)
        }
    }
}
