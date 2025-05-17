// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

public protocol OnboardingCardInfoModelProtocol {
    associatedtype OnboardingType
    associatedtype OnboardingPopupActionType
    associatedtype OnboardingMultipleChoiceActionType: Hashable
    associatedtype OnboardingActionType
    var cardType: OnboardingCardType { get set }
    var name: String { get set }
    var order: Int { get set }
    var title: String { get set }
    var body: String { get set }
    var instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingPopupActionType>? { get set }
    var link: OnboardingLinkInfoModel? { get set }
    var buttons: OnboardingButtons<OnboardingActionType> { get set }
    var multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType>] { get set }
    var onboardingType: OnboardingType { get set }
    var a11yIdRoot: String { get set }
    var imageID: String { get set }

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
        instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingPopupActionType>?
    )
}
