// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/// The view model used to configure a `ActionButton`
public struct ActionButtonViewModel {
    public struct UX {
        public static let verticalInset: CGFloat = 0
        public static let horizontalInset: CGFloat = 8
    }

    public let title: String
    public let a11yIdentifier: String?
    public let horizontalInset: CGFloat
    public let verticalInset: CGFloat
    public var touchUpAction: ((UIButton) -> Void)?

    public init(title: String,
                a11yIdentifier: String?,
                horizontalInset: CGFloat = UX.horizontalInset,
                verticalInset: CGFloat = UX.verticalInset,
                touchUpAction: ((UIButton) -> Void)?) {
        self.title = title
        self.a11yIdentifier = a11yIdentifier
        self.horizontalInset = horizontalInset
        self.verticalInset = verticalInset
        self.touchUpAction = touchUpAction
    }
}
