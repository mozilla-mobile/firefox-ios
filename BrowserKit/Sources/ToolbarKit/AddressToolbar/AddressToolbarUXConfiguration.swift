// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public struct AddressToolbarUXConfiguration {
    private(set) var toolbarCornerRadius: CGFloat = if #available(iOS 26, *) { 22 } else { 12 }
    let browserActionsAddressBarDividerWidth: CGFloat
    let isLocationTextCentered: Bool
    let hasAlternativeLocationColor: Bool
    let locationTextFieldTrailingPadding: CGFloat
    let shouldBlur: Bool
    let backgroundAlpha: CGFloat
    let isAddressBarMinimized: Bool

    public static func experiment(backgroundAlpha: CGFloat = 1.0,
                                  isAddressBarMinimized: Bool = false,
                                  shouldBlur: Bool = false,
                                  hasAlternativeLocationColor: Bool = false) -> AddressToolbarUXConfiguration {
        AddressToolbarUXConfiguration(
            browserActionsAddressBarDividerWidth: 0.0,
            isLocationTextCentered: true,
            hasAlternativeLocationColor: hasAlternativeLocationColor,
            locationTextFieldTrailingPadding: 0,
            shouldBlur: shouldBlur,
            backgroundAlpha: backgroundAlpha,
            isAddressBarMinimized: isAddressBarMinimized
        )
    }

    public static func `default`(backgroundAlpha: CGFloat = 1.0,
                                 isAddressBarMinimized: Bool = false,
                                 shouldBlur: Bool = false,
                                 hasAlternativeLocationColor: Bool = false) -> AddressToolbarUXConfiguration {
        AddressToolbarUXConfiguration(
            toolbarCornerRadius: 8.0,
            browserActionsAddressBarDividerWidth: 4.0,
            isLocationTextCentered: false,
            hasAlternativeLocationColor: hasAlternativeLocationColor,
            locationTextFieldTrailingPadding: 8.0,
            shouldBlur: shouldBlur,
            backgroundAlpha: backgroundAlpha,
            isAddressBarMinimized: isAddressBarMinimized
        )
    }

    func addressToolbarBackgroundColor(theme: some Theme) -> UIColor {
        let backgroundColor = isLocationTextCentered ? theme.colors.layerSurfaceLow : theme.colors.layer1
        if shouldBlur {
            return backgroundColor.withAlphaComponent(backgroundAlpha)
        }

        return backgroundColor
    }

    func locationContainerBackgroundColor(theme: some Theme) -> UIColor {
        guard !isAddressBarMinimized else { return .clear }

        if hasAlternativeLocationColor {
            return isLocationTextCentered ? theme.colors.layerSurfaceMediumAlt : theme.colors.layerEmphasis
        } else {
            return isLocationTextCentered ? theme.colors.layerSurfaceMedium : theme.colors.layerEmphasis
        }
    }

    public func locationViewVerticalPaddings(addressBarPosition: AddressToolbarPosition) -> (top: CGFloat, bottom: CGFloat) {
        return switch addressBarPosition {
        case .top:
            (top: 8, bottom: 8)
        case .bottom:
            (top: 8, bottom: 8)
        }
    }
}
