// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

class MicrosurveyPromptMiddleware {
    lazy var microsurveyProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID
        switch action.actionType {
        case MicrosurveyPromptActionType.showPrompt:
            self.initializeMicrosurvey(windowUUID: windowUUID)
        case MicrosurveyPromptActionType.closePrompt:
            self.dismissPrompt(windowUUID: windowUUID)
        case MicrosurveyPromptActionType.continueToSurvey:
            self.openSurvey(windowUUID: windowUUID)
        default:
           break
        }
    }

    private func initializeMicrosurvey(windowUUID: WindowUUID) {
        let newAction = MicrosurveyPromptMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptMiddlewareActionType.initialize(MicrosurveyModel())
        )
        store.dispatch(newAction)
    }

    private func dismissPrompt(windowUUID: WindowUUID) {
        let newAction = MicrosurveyPromptMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptMiddlewareActionType.dismissPrompt
        )
        store.dispatch(newAction)
    }

    private func openSurvey(windowUUID: WindowUUID) {
        let newAction = MicrosurveyPromptMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptMiddlewareActionType.openSurvey
        )
        store.dispatch(newAction)
    }
}

struct MicrosurveyModel: Equatable {
    // TODO: FXIOS-8990 - Mobile Messaging Structure
    let promptTitle = String(
        format: .Microsurvey.Prompt.TitleLabel,
        AppName.shortName.rawValue
    )
    let promptButtonLabel: String = .Microsurvey.Prompt.TakeSurveyButton
    let surveyQuestion = "How satisfied are you with printing in Firefox?"
    let surveyOptions: [String] = [
        .Microsurvey.Survey.Options.LikertScaleOption1,
        .Microsurvey.Survey.Options.LikertScaleOption2,
        .Microsurvey.Survey.Options.LikertScaleOption3,
        .Microsurvey.Survey.Options.LikertScaleOption4,
        .Microsurvey.Survey.Options.LikertScaleOption5
    ]
}
