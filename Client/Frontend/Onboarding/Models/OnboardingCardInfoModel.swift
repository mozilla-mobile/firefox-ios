// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

struct OnboardingCardInfoModel: OnboardingCardInfoModelProtocol {
    var name: String
    var order: Int
    var title: String
    var body: String
    var instructionsPopup: OnboardingInstructionsPopupInfoModel?
    var link: OnboardingLinkInfoModel?
    var buttons: OnboardingButtons
    var type: OnboardingType
    var a11yIdRoot: String

    var imageID: String

    var image: UIImage? {
        return UIImage(named: imageID)
    }

    init(
        name: String,
        order: Int,
        title: String,
        body: String,
        link: OnboardingLinkInfoModel?,
        buttons: OnboardingButtons,
        type: OnboardingType,
        a11yIdRoot: String,
        imageID: String,
        instructionsPopup: OnboardingInstructionsPopupInfoModel?
    ) {
        self.name = name
        self.order = order
        self.title = title
        self.body = body
        self.imageID = imageID
        self.link = link
        self.buttons = buttons
        self.type = type
        self.a11yIdRoot = a11yIdRoot
        self.instructionsPopup = instructionsPopup
    }
}
