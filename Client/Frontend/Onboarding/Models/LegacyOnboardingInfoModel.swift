// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol LegacyOnboardingModelProtocol {
    var image: UIImage? { get set }
    var title: String { get set }
    var description: String? { get set }
    var linkButtonTitle: String? { get set }
    var stepsArray: [OnboardingBoldableString]? { get set }
    var primaryAction: String { get set }
    var secondaryAction: String? { get set }
    var a11yIdRoot: String { get set }

    init(image: UIImage?, title: String, description: String?, linkButtonTitle: String?, stepsArray: [OnboardingBoldableString]?, primaryAction: String, secondaryAction: String?, a11yIdRoot: String)
}

struct LegacyOnboardingInfoModel: LegacyOnboardingModelProtocol {
    var image: UIImage?
    var title: String
    var description: String?
    var linkButtonTitle: String?
    var stepsArray: [OnboardingBoldableString]?
    var primaryAction: String
    var secondaryAction: String?
    var a11yIdRoot: String

    init(image: UIImage?,
         title: String,
         description: String?,
         linkButtonTitle: String?,
         stepsArray: [OnboardingBoldableString]?,
         primaryAction: String,
         secondaryAction: String?,
         a11yIdRoot: String
    ) {
        self.image = image
        self.title = title
        self.description = description
        self.linkButtonTitle = linkButtonTitle
        self.stepsArray = stepsArray
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.a11yIdRoot = a11yIdRoot
    }
}

struct OnboardingBoldableString {
    var textToBold: String
    var fullString: String

    func bold(_ textToBold: String, in fullString: String, withFontSize size: CGFloat) -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: fullString)
        let range = (fullString as NSString).range(of: textToBold)
        let boldFontAttribute = [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: size)]
        attributedText.addAttributes(boldFontAttribute, range: range)
        return attributedText
    }
}
