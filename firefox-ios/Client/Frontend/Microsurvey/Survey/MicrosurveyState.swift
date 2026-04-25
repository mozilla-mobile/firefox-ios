// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Common
import CopyWithUpdates

@CopyWithUpdates
struct MicrosurveyState: ScreenState {
    var windowUUID: WindowUUID
    var shouldDismiss: Bool
    var showPrivacy: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let microsurveyState = appState.componentState(
            MicrosurveyState.self,
            for: .microsurvey,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self = microsurveyState.copyWithUpdates()
    }

    init(
        windowUUID: WindowUUID
    ) {
        self.init(
            windowUUID: windowUUID,
            shouldDismiss: false,
            showPrivacy: false
        )
    }

    private init(windowUUID: WindowUUID, shouldDismiss: Bool, showPrivacy: Bool) {
        self.windowUUID = windowUUID
        self.shouldDismiss = shouldDismiss
        self.showPrivacy = showPrivacy
    }

    static let reducer: Reducer<Self> = { state, action in
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case MicrosurveyActionType.closeSurvey:
            return state.copyWithUpdates(
                shouldDismiss: true,
                showPrivacy: false
            )
        case MicrosurveyActionType.tapPrivacyNotice:
            return state.copyWithUpdates(
                shouldDismiss: false,
                showPrivacy: true
            )
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: MicrosurveyState) -> MicrosurveyState {
        return state.copyWithUpdates(
            shouldDismiss: false,
            showPrivacy: false
        )
    }
}
