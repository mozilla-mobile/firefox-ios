// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Foundation

/// The view model used to configure a `LinkButton`
public struct LinkButtonViewModel {
    public let title: String
    public let a11yIdentifier: String
    public let fontSize: CGFloat
    public let textAlignment: NSTextAlignment

    public init(title: String,
                a11yIdentifier: String,
                fontSize: CGFloat = 16,
                textAlignment: NSTextAlignment = .left) {
        self.title = title
        self.a11yIdentifier = a11yIdentifier
        self.fontSize = fontSize
        self.textAlignment = textAlignment
    }
}
