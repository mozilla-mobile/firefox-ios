// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

/// State for the jump back in section that is used in the homepage view
struct JumpBackInSectionState: StateType, Equatable, Hashable {
    var windowUUID: WindowUUID
    var jumpBackInTabs: [JumpBackInTabState]

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            jumpBackInTabs: []
        )
    }

    private init(
        windowUUID: WindowUUID,
        jumpBackInTabs: [JumpBackInTabState]
    ) {
        self.windowUUID = windowUUID
        self.jumpBackInTabs = jumpBackInTabs
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case HomepageActionType.initialize:
            return handleInitializeAction(for: state, with: action)
        default:
            return defaultState(from: state)
        }
    }

    private static func handleInitializeAction(
        for state: JumpBackInSectionState,
        with action: Action
    ) -> JumpBackInSectionState {
        // TODO: FXIOS-11225 Update state from middleware
        return JumpBackInSectionState(
            windowUUID: state.windowUUID,
            jumpBackInTabs: [JumpBackInTabState(
                titleText: "JumpBack In Title",
                descriptionText: "JumpBack In Description",
                siteURL: "www.mozilla.com"
            )]
        )
    }

    static func defaultState(from state: JumpBackInSectionState) -> JumpBackInSectionState {
        return JumpBackInSectionState(
            windowUUID: state.windowUUID,
            jumpBackInTabs: state.jumpBackInTabs
        )
    }
}
