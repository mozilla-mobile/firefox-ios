// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingCardInfoModelProtocol {
    var name: String { get set }
    var order: Int { get set }
    var title: String { get set }
    var body: String { get set }
    var instructionsPopup: OnboardingInstructionsPopupInfoModel? { get set }
    var link: OnboardingLinkInfoModel? { get set }
    var buttons: OnboardingButtons { get set }
    var type: OnboardingType { get set }
    var a11yIdRoot: String { get set }
    var imageID: String { get set }

    var image: UIImage? { get }

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
    )
}
