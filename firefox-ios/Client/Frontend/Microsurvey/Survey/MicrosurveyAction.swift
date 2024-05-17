// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

class MicrosurveyAction: Action { }

class MicrosurveyMiddlewareAction: Action {
    let microsurveyState: MicrosurveyPromptState?

    init(microsurveyState: MicrosurveyPromptState? = nil,
         windowUUID: UUID,
         actionType: ActionType) {
        self.microsurveyState = microsurveyState
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum MicrosurveyActionType: ActionType {
    case closeSurvey
    case submitSurvey
    case tapPrivacyNotice
}

enum MicrosurveyMiddlewareActionType: ActionType {
    case dismissSurvey
    case navigateToPrivacyNotice
}
