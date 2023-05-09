// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol OnboardingCardInfoModelProtocol {
    var name: String { get set }
    var title: String { get set }
    var body: String { get set }
    var link: OnboardingLinkInfoModel? { get set }
    var buttons: OnboardingButtons { get set }
    var type: OnboardingType { get set }
    var a11yIdRoot: String { get set }
    var imageID: String { get set }

    var image: UIImage? { get }

    init(
        name: String,
        title: String,
        body: String,
        link: OnboardingLinkInfoModel?,
        buttons: OnboardingButtons,
        type: OnboardingType,
        a11yIdRoot: String,
        imageID: String
    )
}

struct OnboardingCardInfoModel: OnboardingCardInfoModelProtocol {
    var name: String
    var title: String
    var body: String
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
        title: String,
        body: String,
        link: OnboardingLinkInfoModel?,
        buttons: OnboardingButtons,
        type: OnboardingType,
        a11yIdRoot: String,
        imageID: String
    ) {
        self.name = name
        self.title = title
        self.body = body
        self.imageID = imageID
        self.link = link
        self.buttons = buttons
        self.type = type
        self.a11yIdRoot = a11yIdRoot
    }
}
