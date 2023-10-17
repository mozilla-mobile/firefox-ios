// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/// The view model used to configure a `ContextualHintView`
public struct ContextualHintViewModel {
    public var isActionType: Bool
    public var actionButtonTitle: String
    public var description: String
    public var arrowDirection: UIPopoverArrowDirection
    public var closeButtonA11yLabel: String

    public var closeButtonAction: ((UIButton) -> Void)?
    public var actionButtonAction: ((UIButton) -> Void)?

    public init(isActionType: Bool,
                actionButtonTitle: String,
                description: String,
                arrowDirection: UIPopoverArrowDirection,
                closeButtonA11yLabel: String) {
        self.isActionType = isActionType
        self.actionButtonTitle = actionButtonTitle
        self.description = description
        self.arrowDirection = arrowDirection
        self.closeButtonA11yLabel = closeButtonA11yLabel
    }
}
