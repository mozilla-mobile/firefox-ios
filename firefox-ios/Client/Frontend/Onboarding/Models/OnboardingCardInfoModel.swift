// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import OnboardingKit

struct OnboardingCardInfoModel: OnboardingCardInfoModelProtocol {
    var cardType: OnboardingKit.OnboardingCardType
    var name: String
    var order: Int
    var title: String
    var body: String
    var instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>?
    var link: OnboardingLinkInfoModel?
    var buttons: OnboardingButtons<OnboardingActions>
    var multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>]
    var onboardingType: OnboardingType
    var a11yIdRoot: String
    var embededLinkText: [OnboardingKit.EmbeddedLink]
    var defaultSelectedButton: OnboardingKit.OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceAction>?

    var imageID: String

    var image: UIImage? {
        return UIImage(named: imageID)
    }

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
        instructionsPopup: OnboardingKit.OnboardingInstructionsPopupInfoModel<OnboardingInstructionsPopupActions>?,
        embededLinkText: [OnboardingKit.EmbeddedLink]
    ) {
        self.cardType = cardType
        self.name = name
        self.order = order
        self.title = title
        self.body = body
        self.link = link
        self.buttons = buttons
        self.multipleChoiceButtons = multipleChoiceButtons
        self.onboardingType = onboardingType
        self.a11yIdRoot = a11yIdRoot
        self.imageID = imageID
        self.instructionsPopup = instructionsPopup
        self.embededLinkText = embededLinkText
    }
}
