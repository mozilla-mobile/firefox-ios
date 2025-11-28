// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public struct OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType: Hashable & Sendable>:
    Equatable, Sendable {
    public let title: String
    public let action: OnboardingMultipleChoiceActionType
    public var imageID: String

    func image(isSelected: Bool) -> UIImage? {
        let finalImageID = isSelected ? "\(imageID)Selected" : imageID

        // Load from package's bundle if available
        if let image = UIImage(named: finalImageID, in: Bundle.module, compatibleWith: nil) {
            return image
        }
        // Fallback to the main bundle
        if let image = UIImage(named: finalImageID, in: Bundle.main, compatibleWith: nil) {
            return image
        }

        // If selected version not found, fallback to non-selected version
        if isSelected {
            return image(isSelected: false)
        }

        return nil
    }

    public init(title: String, action: OnboardingMultipleChoiceActionType, imageID: String) {
        self.title = title
        self.action = action
        self.imageID = imageID
    }
}
