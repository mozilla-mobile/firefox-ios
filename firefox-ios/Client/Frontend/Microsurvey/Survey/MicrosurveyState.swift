// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Redux
import Shared

struct MicrosurveyState: ScreenState, Equatable {
    var windowUUID: WindowUUID
    var model: MicrosurveyModel?
    var shouldDismiss: Bool
    var showPrivacy: Bool

    init(appState: AppState, uuid: WindowUUID) {
        // CYN: Why do we need appState for?
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
            model: microsurveyState.model,
            shouldDismiss: microsurveyState.shouldDismiss,
            showPrivacy: microsurveyState.showPrivacy
        )
    }

    init(
        windowUUID: WindowUUID
    ) {
        self.init(
            windowUUID: windowUUID,
            model: nil,
            shouldDismiss: false,
            showPrivacy: false
        )
    }

    private init(windowUUID: WindowUUID, model: MicrosurveyModel?, shouldDismiss: Bool, showPrivacy: Bool) {
        self.windowUUID = windowUUID
        self.model = model
        self.shouldDismiss = shouldDismiss
        self.showPrivacy = showPrivacy
    }

    static let reducer: Reducer<Self> = { state, action in
        // TODO: FXIOS-9068 Need to test this experience with multiwindow
        switch action.actionType {
        case MicrosurveyMiddlewareActionType.dismissSurvey:
            return MicrosurveyState(
                windowUUID: state.windowUUID,
                model: state.model,
                shouldDismiss: true,
                showPrivacy: false
            )
        case MicrosurveyMiddlewareActionType.navigateToPrivacyNotice:
            return MicrosurveyState(
                windowUUID: state.windowUUID,
                model: state.model,
                shouldDismiss: false,
                showPrivacy: true
            )
        default:
            return MicrosurveyState(
                windowUUID: state.windowUUID,
                model: state.model,
                shouldDismiss: false,
                showPrivacy: false
            )
        }
    }
}
