// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Redux

/// State for the header cell that is used in the homepage header section
struct HeaderState: StateType, Equatable {
    var windowUUID: WindowUUID
    var isPrivate: Bool
    var showPrivateModeToggle: Bool

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            isPrivate: false,
            showPrivateModeToggle: true
        )
    }

    private init(
        windowUUID: WindowUUID,
        isPrivate: Bool,
        showPrivateModeToggle: Bool
    ) {
        self.windowUUID = windowUUID
        self.isPrivate = isPrivate
        self.showPrivateModeToggle = showPrivateModeToggle
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultActionState(from: state)
        }

        switch action.actionType {
        case HomepageActionType.initialize:
            // TODO: FXIOS-10259 - Update with felt privacy feature flags 
            // or confirm we can remove the showPrivateModeToggle check
            return HeaderState(
                windowUUID: state.windowUUID,
                isPrivate: false,
                showPrivateModeToggle: true
            )
        default:
            return defaultActionState(from: state)
        }
    }

    static func defaultActionState(from state: HeaderState) -> HeaderState {
        return HeaderState(
            windowUUID: state.windowUUID,
            isPrivate: state.isPrivate,
            showPrivateModeToggle: state.showPrivateModeToggle
        )
    }
}
