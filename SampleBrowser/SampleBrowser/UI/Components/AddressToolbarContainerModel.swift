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
    let locationViewState: LocationViewState
    let navigationActions: [ToolbarElement]
    let pageActions: [ToolbarElement]
    let browserActions: [ToolbarElement]
    var manager: ToolbarManager = DefaultToolbarManager()

    var state: AddressToolbarState {
        return AddressToolbarState(
            locationViewState: locationViewState,
            navigationActions: navigationActions,
            pageActions: pageActions,
            browserActions: browserActions,
            borderPosition: borderPosition)
    }

    private var borderPosition: AddressToolbarBorderPosition? {
        manager.getAddressBorderPosition(for: .top, isPrivate: false, scrollY: scrollY)
    }
}
