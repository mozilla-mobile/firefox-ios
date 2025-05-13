// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingDefaultBrowserModelProtocol {
    associatedtype OnboardingPopupActionType
    var title: String { get set }
    var instructionSteps: [String] { get set }
    var buttonTitle: String { get set }
    var buttonAction: OnboardingPopupActionType { get set }
    var a11yIdRoot: String { get set }
}

public struct OnboardingInstructionsPopupInfoModel<OnboardingPopupActionType>: OnboardingDefaultBrowserModelProtocol {
    var title: String
    var instructionSteps: [String]
    var buttonTitle: String
    var buttonAction: OnboardingPopupActionType
    var a11yIdRoot: String
}
