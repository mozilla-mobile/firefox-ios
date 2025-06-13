// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public struct OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType> {
    let title: String
    let action: OnboardingMultipleChoiceActionType
    var imageID: String

    var image: UIImage? {
        if let image = UIImage(named: imageID, in: Bundle.main, compatibleWith: nil) {
            return image // Load from main bundle if available
        }
        // Fallback to the package's bundle
        return UIImage(named: imageID, in: Bundle.module, compatibleWith: nil)
    }

    public init(title: String, action: OnboardingMultipleChoiceActionType, imageID: String) {
        self.title = title
        self.action = action
        self.imageID = imageID
    }
}
