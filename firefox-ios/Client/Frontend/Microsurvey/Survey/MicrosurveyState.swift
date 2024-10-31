// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared
import Common

struct MicrosurveyState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var shouldDismiss: Bool
    var showPrivacy: Bool

    init(appState: AppState, uuid: WindowUUID) {
        guard let microsurveyState = store.state.screenState(
            MicrosurveyState.self,
            for: .microsurvey,
            window: uuid
        ) else {
            self.init(windowUUID: uuid)
            return
        }

        self.init(
            windowUUID: microsurveyState.windowUUID,
            shouldDismiss: microsurveyState.shouldDismiss,
            showPrivacy: microsurveyState.showPrivacy
        )
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
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID else { return state }

        switch action.actionType {
        case MicrosurveyActionType.closeSurvey:
            return MicrosurveyState(
                windowUUID: state.windowUUID,
                shouldDismiss: true,
                showPrivacy: false
            )
        case MicrosurveyActionType.tapPrivacyNotice:
            return MicrosurveyState(
                windowUUID: state.windowUUID,
                shouldDismiss: false,
                showPrivacy: true
            )
        default:
            return defaultActionState(from: state, action: action)
        }
    }

    static func defaultActionState(from state: MicrosurveyState, action: Action) -> MicrosurveyState {
        return MicrosurveyState(
            windowUUID: state.windowUUID,
            shouldDismiss: false,
            showPrivacy: false
        )
    }
}
