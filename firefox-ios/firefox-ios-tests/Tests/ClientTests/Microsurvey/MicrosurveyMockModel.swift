// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MicrosurveyMock {
    static var model: MicrosurveyModel {
        return MicrosurveyModel(
            promptTitle: "prompt title",
            promptButtonLabel: "prompt button label",
            surveyQuestion: "is this a survey question?",
            surveyOptions: [
                "yes",
                "no"
            ]
        )
    }
}
