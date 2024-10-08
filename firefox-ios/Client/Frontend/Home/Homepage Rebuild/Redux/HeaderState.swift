// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

struct HeaderState: StateType, Equatable {
    var windowUUID: WindowUUID
    var showHeader: Bool

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            showHeader: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        showHeader: Bool
    ) {
        self.windowUUID = windowUUID
        self.showHeader = showHeader
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return HeaderState(
                windowUUID: state.windowUUID,
                showHeader: false
            )
        }

        switch action.actionType {
        case HeaderActionType.updateHeader:
            return HeaderState(
                windowUUID: state.windowUUID,
                showHeader: true
            )
        default:
            return HeaderState(
                windowUUID: state.windowUUID,
                showHeader: false
            )
        }
    }
}
