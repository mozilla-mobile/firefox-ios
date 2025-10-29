// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TermsOfUseState: ScreenState {
    let windowUUID: WindowUUID
    var hasAccepted: Bool
    var wasDismissed: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let termsOfUseState = appState.screenState(
            TermsOfUseState.self,
            for: .termsOfUse,
            window: uuid)
        else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(windowUUID: termsOfUseState.windowUUID,
                  hasAccepted: termsOfUseState.hasAccepted,
                  wasDismissed: termsOfUseState.wasDismissed
        )
    }

    init(windowUUID: WindowUUID) {
        self.windowUUID = windowUUID
        self.hasAccepted = false
        self.wasDismissed = false
    }

    init(
        windowUUID: WindowUUID,
        hasAccepted: Bool,
        wasDismissed: Bool
    ) {
        self.windowUUID = windowUUID
        self.hasAccepted = hasAccepted
        self.wasDismissed = wasDismissed
    }

    static func defaultState(from state: TermsOfUseState) -> TermsOfUseState {
        return TermsOfUseState(windowUUID: state.windowUUID,
                               hasAccepted: state.hasAccepted,
                               wasDismissed: state.wasDismissed)
    }

    static let reducer: Reducer<TermsOfUseState> = { state, action in
        return handleReducer(state: state, action: action)
    }

    private static func handleReducer(state: TermsOfUseState, action: Action) -> TermsOfUseState {
        // Only process actions for the current window
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        if let action = action as? TermsOfUseAction {
            return handleTermsOfUseAction(state: state, action: action)
        } else {
            return defaultState(from: state)
        }
    }

    private static func handleTermsOfUseAction(state: TermsOfUseState, action: Action) -> TermsOfUseState {
        guard let action = action as? TermsOfUseAction,
              let type = action.actionType as? TermsOfUseActionType,
              action.windowUUID == state.windowUUID
        else { return defaultState(from: state) }

        switch type {
        case .termsShown:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: false,
                                   wasDismissed: false)
        case .termsAccepted:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: true,
                                   wasDismissed: false)
        case .gestureDismiss,
             .remindMeLaterTapped:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: state.hasAccepted,
                                   wasDismissed: true)
        case .learnMoreLinkTapped,
             .privacyLinkTapped,
             .termsLinkTapped:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: state.hasAccepted,
                                   wasDismissed: state.wasDismissed)
        }
    }
}
