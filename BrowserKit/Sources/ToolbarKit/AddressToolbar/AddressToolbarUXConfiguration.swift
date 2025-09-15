// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public struct AddressToolbarUXConfiguration {
    private(set) var toolbarCornerRadius: CGFloat = if #available(iOS 26, *) { 22 } else { 12 }
    let browserActionsAddressBarDividerWidth: CGFloat
    let isLocationTextCentered: Bool
    let locationTextFieldTrailingPadding: CGFloat
    let shouldBlur: Bool
    let backgroundAlpha: CGFloat
    /// Alpha value that controls element visibility during scroll-based address bar transitions.
    /// Changes between 0 (hidden) and 1 (visible) based on scroll direction.
    let scrollAlpha: CGFloat

    public static func experiment(backgroundAlpha: CGFloat = 1.0,
                                  scrollAlpha: CGFloat = 1.0,
                                  shouldBlur: Bool = false) -> AddressToolbarUXConfiguration {
        AddressToolbarUXConfiguration(
            browserActionsAddressBarDividerWidth: 0.0,
            isLocationTextCentered: true,
            locationTextFieldTrailingPadding: 0,
            shouldBlur: shouldBlur,
            backgroundAlpha: backgroundAlpha,
            scrollAlpha: scrollAlpha
        )
    }

    public static func `default`(backgroundAlpha: CGFloat = 1.0,
                                 scrollAlpha: CGFloat = 1.0,
                                 shouldBlur: Bool = false) -> AddressToolbarUXConfiguration {
        AddressToolbarUXConfiguration(
            toolbarCornerRadius: 8.0,
            browserActionsAddressBarDividerWidth: 4.0,
            isLocationTextCentered: false,
            locationTextFieldTrailingPadding: 8.0,
            shouldBlur: shouldBlur,
            backgroundAlpha: backgroundAlpha,
            scrollAlpha: scrollAlpha
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
        guard !scrollAlpha.isZero else { return .clear }
        let backgroundColor = isLocationTextCentered ? theme.colors.layerSurfaceMedium : theme.colors.layerEmphasis
        return backgroundColor
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
