// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ToolbarKit

struct NavigationToolbarContainerModel {
    let toolbarPosition: AddressToolbarPosition
    let actions: [ToolbarElement]
    var manager: ToolbarManager = DefaultToolbarManager()

    var state: NavigationToolbarState {
        return NavigationToolbarState(actions: actions, shouldDisplayBorder: shouldDisplayBorder)
    }

    private var shouldDisplayBorder: Bool {
        manager.shouldDisplayNavigationBorder(toolbarPosition: toolbarPosition)
    }
}
