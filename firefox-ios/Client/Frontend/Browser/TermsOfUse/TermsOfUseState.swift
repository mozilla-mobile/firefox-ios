// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TermsOfUseState: ScreenState {
    let windowUUID: WindowUUID
    var hasAccepted: Bool
    var wasDismissed: Bool
    var linkState: TermsOfUseLinkState

    init(windowUUID: WindowUUID,
         hasAccepted: Bool = false,
         wasDismissed: Bool = false,
         linkState: TermsOfUseLinkState? = nil) {
        self.windowUUID = windowUUID
        self.hasAccepted = hasAccepted
        self.wasDismissed = wasDismissed
        self.linkState = linkState ?? TermsOfUseLinkState(windowUUID: windowUUID)
    }

    static func defaultState(from state: TermsOfUseState) -> TermsOfUseState {
        return TermsOfUseState(windowUUID: state.windowUUID,
                               hasAccepted: state.hasAccepted,
                               wasDismissed: state.wasDismissed,
                               linkState: state.linkState)
    }

    static let reducer: Reducer<TermsOfUseState> = { state, action in
        if let linkAction = action as? TermsOfUseLinkAction,
           let linkType = linkAction.actionType as? TermsOfUseLinkActionType,
           linkAction.windowUUID == state.windowUUID {
            let updatedLinkState = TermsOfUseLinkState.reducer(state.linkState, linkAction)
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: state.hasAccepted,
                                   wasDismissed: state.wasDismissed,
                                   linkState: updatedLinkState)
        }
        return handleTermsOfUseAction(state: state, action: action)
    }

    private static func handleTermsOfUseAction(state: TermsOfUseState, action: Action) -> TermsOfUseState {
        guard let action = action as? TermsOfUseAction,
              let type = action.actionType as? TermsOfUseActionType,
              action.windowUUID == state.windowUUID else { return defaultState(from: state) }

        switch type {
        case .termsShown:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: false,
                                   wasDismissed: false,
                                   linkState: state.linkState)
        case .termsAccepted:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: true,
                                   wasDismissed: false,
                                   linkState: state.linkState)
        case .gestureDismiss,
             .remindMeLaterTapped:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: state.hasAccepted,
                                   wasDismissed: true,
                                   linkState: state.linkState)
        case .learnMoreLinkTapped,
             .privacyLinkTapped,
             .termsLinkTapped:
            return TermsOfUseState(windowUUID: state.windowUUID,
                                   hasAccepted: state.hasAccepted,
                                   wasDismissed: state.wasDismissed,
                                   linkState: state.linkState)
        }
    }
}
