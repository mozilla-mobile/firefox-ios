// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

public struct AddressToolbarUXConfiguration {
    let toolbarCornerRadius: CGFloat
    let browserActionsAddressBarDividerWidth: CGFloat
    /// Whether navigations actions are included inside the Location container view.
    /// When the actions are included they get the same background and rounding of the Location container view.
    let isNavigationActionsInsideLocationView: Bool
    let isLocationTextCentered: Bool

    public static let experiment = AddressToolbarUXConfiguration(
        toolbarCornerRadius: 12.0,
        browserActionsAddressBarDividerWidth: 0.0,
        isNavigationActionsInsideLocationView: true,
        isLocationTextCentered: true
    )

    public static let `default` = AddressToolbarUXConfiguration(
        toolbarCornerRadius: 8.0,
        browserActionsAddressBarDividerWidth: 4.0,
        isNavigationActionsInsideLocationView: false,
        isLocationTextCentered: false
    )

    func addressToolbarBackgroundColor(theme: any Theme) -> UIColor {
        return isLocationTextCentered ? theme.colors.layer3 : theme.colors.layer1
    }

    func locationContainerBackgroundColor(theme: any Theme) -> UIColor {
        return isLocationTextCentered ? theme.colors.layer2 : theme.colors.layerSearch
    }
}
