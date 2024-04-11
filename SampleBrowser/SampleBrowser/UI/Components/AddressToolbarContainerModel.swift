// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit

struct AddressToolbarContainerModel {
    let toolbarPosition: AddressToolbarPosition
    let scrollY: Int
    let isPrivate: Bool
    let url: String?
    let navigationActions: [ToolbarElement]
    let pageActions: [ToolbarElement]
    let browserActions: [ToolbarElement]
    var manager: ToolbarManager = DefaultToolbarManager()

    var state: AddressToolbarState {
        return AddressToolbarState(
            url: url,
            navigationActions: navigationActions,
            pageActions: pageActions,
            browserActions: browserActions,
            shouldDisplayTopBorder: shouldDisplayTopBorder,
            shouldDisplayBottomBorder: shouldDisplayBottomBorder)
    }

    private var shouldDisplayTopBorder: Bool {
        manager.shouldDisplayBorder(
            borderPosition: .top,
            toolbarPosition: toolbarPosition,
            isPrivate: false,
            scrollY: scrollY)
    }

    private var shouldDisplayBottomBorder: Bool {
        manager.shouldDisplayBorder(
           borderPosition: .bottom,
           toolbarPosition: toolbarPosition,
           isPrivate: false,
           scrollY: scrollY)
    }
}
