// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

class MicrosurveyPromptMiddleware {
    private let microsurveySurfaceManager: MicrosurveySurfaceManager

    init(microsurveySurfaceManager: MicrosurveySurfaceManager = AppContainer.shared.resolve()) {
        self.microsurveySurfaceManager = microsurveySurfaceManager
    }

    lazy var microsurveyProvider: Middleware<AppState> = { state, action in
        let windowUUID = action.windowUUID

        switch action.actionType {
        case MicrosurveyPromptActionType.showPrompt:
            self.checkIfMicrosurveyShouldShow(windowUUID: windowUUID)
        case MicrosurveyPromptActionType.closePrompt:
            self.dismissPrompt(windowUUID: windowUUID)
        case MicrosurveyPromptActionType.continueToSurvey:
            self.openSurvey(windowUUID: windowUUID)
        default:
           break
        }
    }

    private func checkIfMicrosurveyShouldShow(windowUUID: WindowUUID) {
        if let model = self.microsurveySurfaceManager.showMicrosurveyPrompt() {
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
        microsurveySurfaceManager.handleMessageDisplayed()
    }

    private func dismissPrompt(windowUUID: WindowUUID) {
        let newAction = MicrosurveyPromptMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptMiddlewareActionType.dismissPrompt
        )
        store.dispatch(newAction)
        microsurveySurfaceManager.handleMessageDismiss()
    }

    private func openSurvey(windowUUID: WindowUUID) {
        let newAction = MicrosurveyPromptMiddlewareAction(
            windowUUID: windowUUID,
            actionType: MicrosurveyPromptMiddlewareActionType.openSurvey
        )
        store.dispatch(newAction)
    }
}
