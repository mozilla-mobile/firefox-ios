// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TermsOfUseLinkState: ScreenState {
    let windowUUID: WindowUUID
    var shouldDismiss: Bool
    var isLoading: Bool

    init(windowUUID: WindowUUID,
         shouldDismiss: Bool = false,
         isLoading: Bool = true) {
        self.windowUUID = windowUUID
        self.shouldDismiss = shouldDismiss
        self.isLoading = isLoading
    }

    static func defaultState(from state: TermsOfUseLinkState) -> TermsOfUseLinkState {
        return TermsOfUseLinkState(windowUUID: state.windowUUID,
                                   shouldDismiss: state.shouldDismiss,
                                   isLoading: state.isLoading)
    }

    static let reducer: Reducer<TermsOfUseLinkState> = { state, action in
        guard let action = action as? TermsOfUseLinkAction,
              let type = action.actionType as? TermsOfUseLinkActionType,
              action.windowUUID == state.windowUUID else { return defaultState(from: state) }

        switch type {
        case .linkLoading:
            return TermsOfUseLinkState(windowUUID: state.windowUUID,
                                       shouldDismiss: false,
                                       isLoading: true)
        case .linkDismissed:
            return TermsOfUseLinkState(windowUUID: state.windowUUID,
                                       shouldDismiss: true,
                                       isLoading: state.isLoading)
        }
    }
}
