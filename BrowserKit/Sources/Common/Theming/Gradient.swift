// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import SwiftUI

public struct Gradient {
    public var colors: [UIColor]

    public var cgColors: [CGColor] {
        return colors.map { $0.cgColor }
    }

    public var swiftUI: SwiftUI.Gradient {
        return .init(colors: colors.map { Color($0) })
    }

    public init(colors: [UIColor]) {
        self.colors = colors
    }
}
