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
    // Title + button text can come from mobile messaging; but has a hardcoded string as fallback
    let title = String(
        format: .Microsurvey.Prompt.TitleLabel,
        AppName.shortName.rawValue
    )
    let button: String = .Microsurvey.Prompt.TakeSurveyButton
    let a11yLabel: String = .Microsurvey.Prompt.CloseButtonAccessibilityLabel
}
