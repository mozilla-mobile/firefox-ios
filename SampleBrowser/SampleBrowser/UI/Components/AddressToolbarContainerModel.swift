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
            shouldDisplayTopBorder: shouldDisplayTopBorder,
            shouldDisplayBottomBorder: shouldDisplayBottomBorder)
    }

    private var shouldDisplayTopBorder: Bool {
        manager.shouldDisplayAddressBorder(
            borderPosition: .top,
            toolbarPosition: toolbarPosition,
            isPrivate: false,
            scrollY: scrollY)
    }

    private var shouldDisplayBottomBorder: Bool {
        manager.shouldDisplayAddressBorder(
           borderPosition: .bottom,
           toolbarPosition: toolbarPosition,
           isPrivate: false,
           scrollY: scrollY)
    }
}
