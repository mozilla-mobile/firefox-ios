// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class OnboardingMultipleChoiceButtonViewModel {
    var presentingCardName: String
    var isSelected: Bool
    let info: OnboardingMultipleChoiceButtonModel
    let a11yIDRoot: String

    init(
        isSelected: Bool,
        info: OnboardingMultipleChoiceButtonModel,
        presentingCardName: String,
        a11yIDRoot: String
    ) {
        self.isSelected = isSelected
        self.info = info
        self.presentingCardName = presentingCardName
        self.a11yIDRoot = a11yIDRoot
    }
}
