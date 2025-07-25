// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TermsOfUseState: ScreenState, Equatable {
    let windowUUID: WindowUUID
    var hasAccepted: Bool
    var wasDismissed: Bool
    var lastShownDate: Date?
    var didShowThisLaunch: Bool

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        self.hasAccepted = false
        self.wasDismissed = false
        self.lastShownDate = nil
        self.didShowThisLaunch = false
    }

    static func defaultState(from state: TermsOfUseState) -> TermsOfUseState {
        return TermsOfUseState(windowUUID: state.windowUUID)
    }

    static let reducer: Reducer<TermsOfUseState> = { state, action in
        var newState = state
        guard let action = action as? TermsOfUseAction,
              let type = action.actionType as? TermsOfUseActionType,
              action.windowUUID == state.windowUUID else { return newState }

        switch type {
        case .markAccepted:
            newState.hasAccepted = true
            newState.wasDismissed = false
        case .markDismissed:
            newState.wasDismissed = true
            newState.lastShownDate = Date()
        case .markShownThisLaunch:
            newState.didShowThisLaunch = true
        }
        return newState
    }
}
