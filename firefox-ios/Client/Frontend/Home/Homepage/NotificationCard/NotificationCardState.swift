// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import ModifiedCopy
import Redux

/// State for the homepage enable notifications card, shown under the shortcuts section after the
/// user declines notifications during onboarding
@Copyable
struct NotificationCardState: StateType, Equatable {
    var windowUUID: WindowUUID

    let shouldShowCard: Bool

    init(windowUUID: WindowUUID) {
        self.init(
            windowUUID: windowUUID,
            shouldShowCard: false
        )
    }

    private init(
        windowUUID: WindowUUID,
        shouldShowCard: Bool
    ) {
        self.windowUUID = windowUUID
        self.shouldShowCard = shouldShowCard
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
        case HomepageMiddlewareActionType.configuredNotificationCard:
            return state.copy(shouldShowCard: true)
        case HomepageActionType.notificationCardCloseButtonTapped,
             HomepageActionType.notificationCardEnableButtonTapped:
            return state.copy(shouldShowCard: false)
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: NotificationCardState) -> NotificationCardState {
        return NotificationCardState(
            windowUUID: state.windowUUID,
            shouldShowCard: state.shouldShowCard
        )
    }
}
