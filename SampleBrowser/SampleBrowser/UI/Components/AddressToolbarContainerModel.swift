// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import ToolbarKit

struct AddressToolbarContainerModel {
    let toolbarPosition: AddressToolbarPosition
    let scrollY: CGFloat
    let isPrivate: Bool
    let locationViewConfiguration: LocationViewConfiguration
    let navigationActions: [ToolbarElement]
    let leadingPageActions: [ToolbarElement]
    let trailingPageActions: [ToolbarElement]
    let browserActions: [ToolbarElement]
    var manager: ToolbarManager = DefaultToolbarManager()

    var state: AddressToolbarConfiguration {
        return AddressToolbarConfiguration(
            locationViewConfiguration: locationViewConfiguration,
            navigationActions: navigationActions,
            leadingPageActions: leadingPageActions,
            trailingPageActions: trailingPageActions,
            browserActions: browserActions,
            borderPosition: borderPosition,
            uxConfiguration: AddressToolbarUXConfiguration.default(),
            shouldAnimate: false)
    }

    private var borderPosition: AddressToolbarBorderPosition? {
        manager.getAddressBorderPosition(for: .top, isPrivate: false, scrollY: scrollY)
    }
}
