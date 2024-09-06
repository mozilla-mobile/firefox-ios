// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

final class MicrosurveyPromptMiddleware {
    private let microsurveyManager: MicrosurveyManager

    init(microsurveyManager: MicrosurveyManager = AppContainer.shared.resolve()) {
        self.microsurveyManager = microsurveyManager
    }

    lazy var microsurveyProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID

        switch action.actionType {
        case MicrosurveyPromptActionType.showPrompt:
            self.checkIfMicrosurveyShouldShow(windowUUID: windowUUID)
        case MicrosurveyPromptActionType.closePrompt:
            self.dismissPrompt()
        case MicrosurveyPromptActionType.continueToSurvey:
            self.openSurvey()
        default:
           break
        }
    }

    private func checkIfMicrosurveyShouldShow(windowUUID: WindowUUID) {
        if let model = self.microsurveyManager.showMicrosurveyPrompt() {
            initializeMicrosurvey(windowUUID: windowUUID, model: model)
        } else {
            return
        }
    }

    private func initializeMicrosurvey(windowUUID: WindowUUID, model: MicrosurveyModel) {
        let newAction = MicrosurveyPromptMiddlewareAction(
            microsurveyModel: model,
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptMiddlewareActionType.initialize
        )
        store.dispatch(newAction)
        microsurveyManager.handleMessageDisplayed()
    }

    private func dismissPrompt() {
        microsurveyManager.handleMessageDismiss()
    }

    private func openSurvey() {
        microsurveyManager.handleMessagePressed()
    }
}
