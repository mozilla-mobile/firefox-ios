// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux

struct TermsOfUseLinkState: ScreenState {
    let windowUUID: WindowUUID
    var shouldDismiss: Bool
    var isLoading: Bool
    var hasError: Bool

    init(windowUUID: WindowUUID,
         shouldDismiss: Bool = false,
         isLoading: Bool = true,
         hasError: Bool = false) {
        self.windowUUID = windowUUID
        self.shouldDismiss = shouldDismiss
        self.isLoading = isLoading
        self.hasError = hasError
    }

    static func defaultState(from state: TermsOfUseLinkState) -> TermsOfUseLinkState {
        return TermsOfUseLinkState(windowUUID: state.windowUUID,
                                   shouldDismiss: state.shouldDismiss,
                                   isLoading: state.isLoading,
                                   hasError: state.hasError)
    }

    static let reducer: Reducer<TermsOfUseLinkState> = { state, action in
        guard let action = action as? TermsOfUseLinkAction,
              let type = action.actionType as? TermsOfUseLinkActionType,
              action.windowUUID == state.windowUUID else { return defaultState(from: state) }

        switch type {
        case .linkLoading:
            return TermsOfUseLinkState(windowUUID: state.windowUUID,
                                       shouldDismiss: false,
                                       isLoading: true,
                                       hasError: false)
        case .linkShown:
            return TermsOfUseLinkState(windowUUID: state.windowUUID,
                                       shouldDismiss: state.shouldDismiss,
                                       isLoading: false,
                                       hasError: state.hasError)
        case .linkError:
            return TermsOfUseLinkState(windowUUID: state.windowUUID,
                                       shouldDismiss: state.shouldDismiss,
                                       isLoading: false,
                                       hasError: true)
        case .linkDismissed:
            return TermsOfUseLinkState(windowUUID: state.windowUUID,
                                       shouldDismiss: true,
                                       isLoading: state.isLoading,
                                       hasError: state.hasError)
        }
    }
}
