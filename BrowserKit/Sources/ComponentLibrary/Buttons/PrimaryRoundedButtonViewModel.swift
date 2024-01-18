// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import UIKit

/// The view model used to configure a `PrimaryRoundedButton`
public struct PrimaryRoundedButtonViewModel {
    public let title: String
    public let a11yIdentifier: String
    public let imageTitlePadding: Double?
    public let backgroundColor: ((Theme) -> UIColor)?
    public let titleColor: ((Theme) -> UIColor)?

    public init(title: String, a11yIdentifier: String,
                imageTitlePadding: Double? = nil,
                backgroundColor: ((Theme) -> UIColor)? = nil,
                titleColor: ((Theme) -> UIColor)? = nil) {
        self.title = title
        self.a11yIdentifier = a11yIdentifier
        self.imageTitlePadding = imageTitlePadding
        self.backgroundColor = backgroundColor
        self.titleColor = titleColor
    }
}
