// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol OnboardingCardInfoModelProtocol: Sendable {
    associatedtype OnboardingType: Sendable
    associatedtype OnboardingPopupActionType: Sendable
    associatedtype OnboardingMultipleChoiceActionType: Hashable & Sendable
    associatedtype OnboardingActionType: RawRepresentable, Sendable where OnboardingActionType.RawValue == String
    var cardType: OnboardingCardType { get }
    var name: String { get }
    var order: Int { get }
    var title: String { get }
    var body: String { get }
    var instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingPopupActionType>? { get }
    var link: OnboardingLinkInfoModel? { get }
    var buttons: OnboardingButtons<OnboardingActionType> { get }
    var multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType>] { get }
    var onboardingType: OnboardingType { get }
    var a11yIdRoot: String { get }
    var imageID: String { get }
    var embededLinkText: [EmbeddedLink] { get }
    var defaultSelectedButton: OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType>? { get }

    var image: UIImage? { get }

    init(
        cardType: OnboardingCardType,
        name: String,
        order: Int,
        title: String,
        body: String,
        link: OnboardingLinkInfoModel?,
        buttons: OnboardingButtons<OnboardingActionType>,
        multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType>],
        onboardingType: OnboardingType,
        a11yIdRoot: String,
        imageID: String,
        instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingPopupActionType>?,
        embededLinkText: [EmbeddedLink]
    )
}
