// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct AddressToolbarUXConfiguration {
    let addressBarCornerRadius: CGFloat
    let browserActionsAddressBarDividerWidth: CGFloat
    let shouldIncludeNavigationActionsInAddressBar: Bool
    let shouldCenterLocationText: Bool

    public static let experiment = AddressToolbarUXConfiguration(
        addressBarCornerRadius: 12.0,
        browserActionsAddressBarDividerWidth: 0.0,
        shouldIncludeNavigationActionsInAddressBar: true,
        shouldCenterLocationText: true
    )

    public static let `default` = AddressToolbarUXConfiguration(
        addressBarCornerRadius: 8.0,
        browserActionsAddressBarDividerWidth: 4.0,
        shouldIncludeNavigationActionsInAddressBar: false,
        shouldCenterLocationText: false
    )
}
