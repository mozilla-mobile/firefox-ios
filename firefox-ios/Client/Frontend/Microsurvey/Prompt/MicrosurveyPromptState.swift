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
        guard action.windowUUID == .unavailable || action.windowUUID == state.windowUUID
        else {
            return defaultState(from: state)
        }

        switch action.actionType {
        case MicrosurveyPromptMiddlewareActionType.initialize:
            return handleInitializeAction(state: state, action: action)
        case MicrosurveyPromptActionType.closePrompt:
            return MicrosurveyPromptState(
                windowUUID: state.windowUUID,
                showPrompt: false,
                showSurvey: false,
                model: state.model
            )
        case MicrosurveyPromptActionType.continueToSurvey:
            return MicrosurveyPromptState(
                windowUUID: state.windowUUID,
                showPrompt: true,
                showSurvey: true,
                model: state.model
            )
        default:
            return defaultState(from: state)
        }
    }

    static func defaultState(from state: MicrosurveyPromptState) -> MicrosurveyPromptState {
        return MicrosurveyPromptState(
            windowUUID: state.windowUUID,
            showPrompt: state.showPrompt,
            showSurvey: false,
            model: state.model
        )
    }

    private static func handleInitializeAction(state: Self, action: Action) -> Self {
        let model = (action as? MicrosurveyPromptMiddlewareAction)?.microsurveyModel
        return MicrosurveyPromptState(
            windowUUID: state.windowUUID,
            showPrompt: true,
            showSurvey: false,
            model: model
        )
    }

    private static func handleClosePromptAction(state: Self) -> Self {
        return MicrosurveyPromptState(
            windowUUID: state.windowUUID,
            showPrompt: false,
            showSurvey: false,
            model: state.model
        )
    }
}
