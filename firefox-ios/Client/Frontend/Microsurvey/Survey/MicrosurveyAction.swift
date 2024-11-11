// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux
import Common

final class MicrosurveyAction: Action {
    let userSelection: String?
    let surveyId: String

    init(surveyId: String, userSelection: String? = nil, windowUUID: WindowUUID, actionType: any ActionType) {
        self.surveyId = surveyId
        self.userSelection = userSelection
        super.init(windowUUID: windowUUID, actionType: actionType)
    }
}

enum MicrosurveyActionType: ActionType {
    case closeSurvey
    case submitSurvey
    case tapPrivacyNotice
    case surveyDidAppear
    case confirmationViewed
}
