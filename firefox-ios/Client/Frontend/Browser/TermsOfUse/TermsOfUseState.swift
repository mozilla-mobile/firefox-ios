// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TermsOfUseState: ScreenState, Equatable {
    let windowUUID: WindowUUID
    var hasAccepted: Bool
    var wasDismissed: Bool

    init(windowUUID: WindowUUID,
         hasAccepted: Bool = false,
         wasDismissed: Bool = false) {
        self.windowUUID = windowUUID
        self.hasAccepted = hasAccepted
        self.wasDismissed = wasDismissed
    }

    static func defaultState(from state: TermsOfUseState) -> TermsOfUseState {
        return TermsOfUseState(windowUUID: state.windowUUID)
    }

    static let reducer: Reducer<TermsOfUseState> = { state, action in
        guard let action = action as? TermsOfUseAction,
              let type = action.actionType as? TermsOfUseActionType,
              action.windowUUID == state.windowUUID else { return defaultState(from: state) }

        switch type {
        case .markAccepted:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: true,
                                   wasDismissed: false)
        case .markDismissed:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: state.hasAccepted,
                                   wasDismissed: true)
        case .markShown:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: false,
                                   wasDismissed: false)
        }
    }
}
