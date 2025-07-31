// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public struct OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType: Sendable>: Sendable {
    public let title: String
    public let action: OnboardingMultipleChoiceActionType
    public var imageID: String

    func image(isSelected: Bool) -> UIImage? {
        let finalImageID = isSelected ? "\(imageID)Selected" : imageID

        // Load from package's bundle bundle if available
        if let image = UIImage(named: finalImageID, in: Bundle.module, compatibleWith: nil) {
            return image
        }
        // Fallback to the main bundle
        return UIImage(named: finalImageID, in: Bundle.main, compatibleWith: nil)
    }

    public init(title: String, action: OnboardingMultipleChoiceActionType, imageID: String) {
        self.title = title
        self.action = action
        self.imageID = imageID
    }
}
