// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct OnboardingDefaultBrowserModelProtocol {
    var title: String
    var descriptionSteps: [String]
    var buttonTitle: String

    init(title: String,
         descriptionSteps: [String],
         buttonTitle: String) {
        self.title = title
        self.descriptionSteps = descriptionSteps
        self.buttonTitle = buttonTitle
    }
}
