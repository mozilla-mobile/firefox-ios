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
    var remindMeLater: Bool

    init(windowUUID: WindowUUID,
         hasAccepted: Bool = false,
         wasDismissed: Bool = false,
         lastShownDate: Date? = nil,
         didShowThisLaunch: Bool = false,
         remindMeLater: Bool = false) {
        self.windowUUID = windowUUID
        self.hasAccepted = hasAccepted
        self.wasDismissed = wasDismissed
        self.lastShownDate = lastShownDate
        self.didShowThisLaunch = didShowThisLaunch
        self.remindMeLater = remindMeLater
    }

    static func defaultState(from state: TermsOfUseState) -> TermsOfUseState {
        return TermsOfUseState(windowUUID: state.windowUUID)
    }

    static let reducer: Reducer<TermsOfUseState> = { state, action in
        guard let action = action as? TermsOfUseAction,
              let type = action.actionType as? TermsOfUseActionType,
              action.windowUUID == state.windowUUID else { return state }

        switch type {
        case .markAccepted:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: true,
                                   wasDismissed: false,
                                   lastShownDate: state.lastShownDate,
                                   didShowThisLaunch: state.didShowThisLaunch,
                                   remindMeLater: state.remindMeLater)
        case .markDismissed:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: state.hasAccepted,
                                   wasDismissed: true,
                                   lastShownDate: Date(),
                                   didShowThisLaunch: state.didShowThisLaunch,
                                   remindMeLater: state.remindMeLater)
        case .markShownThisLaunch:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: state.hasAccepted,
                                   wasDismissed: state.wasDismissed,
                                   lastShownDate: state.lastShownDate,
                                   didShowThisLaunch: true,
                                   remindMeLater: state.remindMeLater)
        case .remindMeLater:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: state.hasAccepted,
                                   wasDismissed: state.wasDismissed,
                                   lastShownDate: state.lastShownDate,
                                   didShowThisLaunch: state.didShowThisLaunch,
                                   remindMeLater: true)
        }
    }
}
