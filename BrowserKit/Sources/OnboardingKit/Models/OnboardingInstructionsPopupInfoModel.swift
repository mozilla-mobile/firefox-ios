// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingDefaultBrowserModelProtocol: Sendable {
    associatedtype OnboardingPopupActionType
    var title: String { get }
    var instructionSteps: [String] { get }
    var buttonTitle: String { get }
    var buttonAction: OnboardingPopupActionType { get }
    var a11yIdRoot: String { get }
}

public struct OnboardingInstructionsPopupInfoModel
<OnboardingPopupActionType: Sendable>: OnboardingDefaultBrowserModelProtocol {
    public let title: String
    public let instructionSteps: [String]
    public let buttonTitle: String
    public let buttonAction: OnboardingPopupActionType
    public let a11yIdRoot: String

    public init(
        title: String,
        instructionSteps: [String],
        buttonTitle: String,
        buttonAction: OnboardingPopupActionType,
        a11yIdRoot: String
    ) {
        self.title = title
        self.instructionSteps = instructionSteps
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.a11yIdRoot = a11yIdRoot
    }
}
