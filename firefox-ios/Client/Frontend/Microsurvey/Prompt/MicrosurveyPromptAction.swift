// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

final class MicrosurveyPromptAction: Action { }

final class MicrosurveyPromptMiddlewareAction: Action {
    let microsurveyModel: MicrosurveyModel?
    init(microsurveyModel: MicrosurveyModel? = nil, windowUUID: WindowUUID, actionType: any ActionType) {
        self.microsurveyModel = microsurveyModel
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum MicrosurveyPromptActionType: ActionType {
    case showPrompt
    case closePrompt
    case continueToSurvey
}

enum MicrosurveyPromptMiddlewareActionType: ActionType {
    case initialize
}
