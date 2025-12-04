// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import OnboardingKit

protocol OnboardingCardInfoModelProtocol {
    var cardType: OnboardingKit.OnboardingCardType { get set }
    var name: String { get set }
    var order: Int { get set }
    var title: String { get set }
    var body: String { get set }
    var instructionsPopup: OnboardingKit.OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>? {
        get set
    }
    var link: OnboardingKit.OnboardingLinkInfoModel? { get set }
    var buttons: OnboardingKit.OnboardingButtons<OnboardingActions> { get set }
    var multipleChoiceButtons: [OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>] {
        get set
    }
    var onboardingType: OnboardingType { get set }
    var a11yIdRoot: String { get set }
    var imageID: String { get set }

    var image: UIImage? { get }

    init(
        cardType: OnboardingKit.OnboardingCardType,
        name: String,
        order: Int,
        title: String,
        body: String,
        link: OnboardingKit.OnboardingLinkInfoModel?,
        buttons: OnboardingKit.OnboardingButtons<OnboardingActions>,
        multipleChoiceButtons: [OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>],
        onboardingType: OnboardingType,
        a11yIdRoot: String,
        imageID: String,
        instructionsPopup: OnboardingKit.OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>?
    )
}
