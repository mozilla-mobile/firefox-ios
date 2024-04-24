// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct ToolbarState: ScreenState, Equatable {
    var windowUUID: WindowUUID

    init(_ appState: BrowserViewControllerState) {
        self.init(
            windowUUID: appState.windowUUID,
        )
    }

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
        )
    }

    static let reducer: Reducer<Self> = { state, action in
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action {
        default:
            return state
        }
    }
}
