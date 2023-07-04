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

<<<<<<< HEAD
    init(title: String = String.Onboarding.DefaultBrowserPopup.Title,
         instructionSteps: [String] = [String.Onboarding.DefaultBrowserPopup.FirstInstruction,
              String.Onboarding.DefaultBrowserPopup.SecondInstruction,
              String(format: String.Onboarding.DefaultBrowserPopup.ThirdInstruction, AppName.shortName.rawValue)],
         buttonTitle: String = String.Onboarding.DefaultBrowserPopup.ButtonTitle,
         a11yIdRoot: String) {
        self.title = title
        self.instructionSteps = instructionSteps
        self.buttonTitle = buttonTitle
        self.a11yIdRoot = a11yIdRoot
    }

=======
>>>>>>> 4b02822e6 (Bugfix [v116] Fix swiftlint warnings (#15290))
    func getAttributedStrings(with font: UIFont) -> [NSAttributedString] {
        return instructionSteps.map { MarkupAttributeUtility(baseFont: font).addAttributesTo(text: $0) }
    }
}
