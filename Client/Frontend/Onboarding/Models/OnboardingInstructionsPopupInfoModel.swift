// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct OnboardingInstructionsPopupInfoModel: OnboardingDefaultBrowserModelProtocol {
    var title: String
    var instructionSteps: [String]
    var buttonTitle: String
    var buttonAction: OnboardingInstructionsPopupActions
    var a11yIdRoot: String

    func getAttributedStrings(with font: UIFont) -> [NSAttributedString] {
        return instructionSteps.map { MarkupAttributeUtility(baseFont: font).addAttributesTo(text: $0) }
    }
}
