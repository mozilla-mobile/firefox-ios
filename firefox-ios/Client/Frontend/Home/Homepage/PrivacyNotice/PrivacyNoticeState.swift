// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Redux

@Copyable
struct PrivacyNoticeState: StateType, Equatable {
    var windowUUID: WindowUUID

    /// `shouldShowPrivacyNotice` is true when the homepage should display the privacy notice card. This is the case when a
    /// new privacy notice is available after a user has already accepted the ToS/ToU
    let shouldShowPrivacyNotice: Bool

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            shouldShowPrivacyNotice: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        shouldShowPrivacyNotice: Bool
    ) {
        self.windowUUID = windowUUID
        self.shouldShowPrivacyNotice = shouldShowPrivacyNotice
    }

    static let reducer: Reducer<Self> = (legacyReducer, modernReducer)

    static let modernReducer: ReducerMethod<Self> = { state, action, actionWindowUUID in
        // Does not handle any modern actions
        return defaultState(from: state)
    }

    static let legacyReducer: LegacyReducerMethod<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case HomepageMiddlewareActionType.configuredPrivacyNotice:
            return state.copy(shouldShowPrivacyNotice: true)
        case HomepageActionType.privacyNoticeCloseButtonTapped:
            return state.copy(shouldShowPrivacyNotice: false)
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: PrivacyNoticeState) -> PrivacyNoticeState {
        return PrivacyNoticeState(
            windowUUID: state.windowUUID,
            shouldShowPrivacyNotice: state.shouldShowPrivacyNotice
        )
    }
}
