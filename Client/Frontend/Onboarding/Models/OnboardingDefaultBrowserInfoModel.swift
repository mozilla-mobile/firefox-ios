// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct OnboardingDefaultBrowserInfoModel: OnboardingDefaultBrowserModelProtocol {
    var title: String
    var instructionSteps: [String]
    var buttonTitle: String
    var a11yIdRoot: String

    init(title: String,
         instructionSteps: [String],
         buttonTitle: String,
         a11yIdRoot: String) {
        self.title = title
        self.instructionSteps = instructionSteps
        self.buttonTitle = buttonTitle
        self.a11yIdRoot = a11yIdRoot
    }

    func getAttributedStrings(with font: UIFont) -> [NSAttributedString] {
        return instructionSteps.map { MarkupAttributeUtility(baseFont: font).addAttributesTo(text: $0) }
    }
}
