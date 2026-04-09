// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

public struct ChipButtonViewModel {
    public let title: String
    public let a11yIdentifier: String?
    public let isSelected: Bool
    public var tappedAction: (@MainActor (UIButton) -> Void)?

    public init(
        title: String,
        a11yIdentifier: String?,
        isSelected: Bool,
        touchUpAction: (@MainActor (UIButton) -> Void)?
    ) {
        self.title = title
        self.a11yIdentifier = a11yIdentifier
        self.isSelected = isSelected
        self.tappedAction = touchUpAction
    }
}
