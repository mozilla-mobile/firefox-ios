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
        guard let surveyId = (action as? MicrosurveyAction)?.surveyId else { return }
        switch action.actionType {
        case MicrosurveyActionType.closeSurvey:
            self.dismissSurvey(windowUUID: windowUUID, surveyId: surveyId)
        case MicrosurveyActionType.tapPrivacyNotice:
            self.sendTelemtryForNavigatingToPrivacyNotice(surveyId: surveyId)
        case MicrosurveyActionType.submitSurvey:
            self.sendTelemetryAndClosePrompt(windowUUID: windowUUID, action: action, surveyId: surveyId)
        case MicrosurveyActionType.surveyDidAppear:
            self.microsurveyTelemetry.surveyViewed(surveyId: surveyId)
        case MicrosurveyActionType.confirmationViewed:
            self.microsurveyTelemetry.confirmationShown(surveyId: surveyId)
        default:
           break
        }
    }

    private func dismissSurvey(windowUUID: WindowUUID, surveyId: String) {
        microsurveyTelemetry.dismissButtonTapped(surveyId: surveyId)
        closeMicrosurveyPrompt(windowUUID: windowUUID)
    }

    private func sendTelemtryForNavigatingToPrivacyNotice(surveyId: String) {
        microsurveyTelemetry.privacyNoticeTapped(surveyId: surveyId)
    }

    private func sendTelemetryAndClosePrompt(windowUUID: WindowUUID, action: Action, surveyId: String) {
        closeMicrosurveyPrompt(windowUUID: windowUUID)
        guard let userSelection = (action as? MicrosurveyAction)?.userSelection else { return }
        microsurveyTelemetry.userResponseSubmitted(surveyId: surveyId, userSelection: userSelection)
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
