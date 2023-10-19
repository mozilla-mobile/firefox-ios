// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import UIKit

/// The view model used to configure a `PaddedSwitch`
public struct PaddedSwitchViewModel {
    public let theme: Theme
    public let isEnabled: Bool
    public let isOn: Bool
    public let a11yIdentifier: String
    public var valueChangedClosure: (() -> Void)?

    public init(theme: Theme,
                isEnabled: Bool,
                isOn: Bool,
                a11yIdentifier: String,
                valueChangedClosure: (() -> Void)?) {
        self.theme = theme
        self.isEnabled = isEnabled
        self.isOn = isOn
        self.a11yIdentifier = a11yIdentifier
        self.valueChangedClosure = valueChangedClosure
    }
}
