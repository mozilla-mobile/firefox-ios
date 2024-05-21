// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Shared
import Common

struct MicrosurveyPromptState: StateType, Equatable {
    var windowUUID: WindowUUID
    var showPrompt: Bool
    var showSurvey: Bool
    var model: MicrosurveyModel?

    init(windowUUID: WindowUUID) {
        self.init(windowUUID: windowUUID,
                  showPrompt: false,
                  showSurvey: false,
                  model: nil)
    }

    init(windowUUID: WindowUUID,
         showPrompt: Bool,
         showSurvey: Bool,
         model: MicrosurveyModel?) {
        self.windowUUID = windowUUID
        self.showPrompt = showPrompt
        self.showSurvey = showSurvey
        self.model = model
    }

    static let reducer: Reducer<Self> = { state, action in
        // TODO: FXIOS-9068 Need to test this experience with multiwindow
        switch action.actionType {
        case MicrosurveyPromptMiddlewareActionType.initialize(let model):
            return MicrosurveyPromptState(
                windowUUID: state.windowUUID,
                showPrompt: true,
                showSurvey: false,
                model: model
            )
        case MicrosurveyPromptMiddlewareActionType.dismissPrompt:
            return MicrosurveyPromptState(
                windowUUID: state.windowUUID,
                showPrompt: false,
                showSurvey: false,
                model: state.model
            )
        case MicrosurveyPromptMiddlewareActionType.openSurvey:
            return MicrosurveyPromptState(
                windowUUID: state.windowUUID,
                showPrompt: true,
                showSurvey: true,
                model: state.model
            )
        default:
            return MicrosurveyPromptState(
                windowUUID: state.windowUUID,
                showPrompt: state.showPrompt,
                showSurvey: false,
                model: state.model
            )
        }
    }
}
