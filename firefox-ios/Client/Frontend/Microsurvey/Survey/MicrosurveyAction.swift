// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Redux

final class MicrosurveyAction: Action { }
final class MicrosurveyMiddlewareAction: Action { }

enum MicrosurveyActionType: ActionType {
    case closeSurvey
    case submitSurvey
    case tapPrivacyNotice
}

enum MicrosurveyMiddlewareActionType: ActionType {
    case dismissSurvey
    case navigateToPrivacyNotice
}
