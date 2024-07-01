// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

final class MicrosurveyMiddleware {
    private let microsurveyTelemetry = MicrosurveyTelemetry()

    lazy var microsurveyProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case MicrosurveyActionType.closeSurvey:
            self.dismissSurvey(windowUUID: windowUUID)
        case MicrosurveyActionType.tapPrivacyNotice:
            self.navigateToPrivacyNotice(windowUUID: windowUUID)
        case MicrosurveyActionType.submitSurvey:
            self.sendTelemetryAndClosePrompt(windowUUID: windowUUID, action: action)
        case MicrosurveyActionType.surveyDidAppear:
            self.microsurveyTelemetry.surveyViewed()
        case MicrosurveyActionType.confirmationViewed:
            self.microsurveyTelemetry.confirmationShown()
        default:
           break
        }
    }

    private func dismissSurvey(windowUUID: WindowUUID) {
        let newAction = MicrosurveyMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyMiddlewareActionType.dismissSurvey
        )
        store.dispatch(newAction)
        microsurveyTelemetry.dismissButtonTapped()
        closeMicrosurveyPrompt(windowUUID: windowUUID)
    }

    private func navigateToPrivacyNotice(windowUUID: WindowUUID) {
        let newAction = MicrosurveyMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyMiddlewareActionType.navigateToPrivacyNotice
        )
        store.dispatch(newAction)
        microsurveyTelemetry.privacyNoticeTapped()
    }

    private func sendTelemetryAndClosePrompt(windowUUID: WindowUUID, action: Action) {
        closeMicrosurveyPrompt(windowUUID: windowUUID)
        guard let userSelection = (action as? MicrosurveyAction)?.userSelection else { return }
        microsurveyTelemetry.userResponseSubmitted(userSelection: userSelection)
    }

    private func closeMicrosurveyPrompt(windowUUID: WindowUUID) {
        store.dispatch(
            MicrosurveyPromptAction(
                windowUUID: windowUUID,
                actionType: MicrosurveyPromptActionType.closePrompt
            )
        )
    }
}
