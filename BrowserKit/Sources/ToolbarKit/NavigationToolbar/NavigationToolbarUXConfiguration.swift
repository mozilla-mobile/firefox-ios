// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public struct NavigationToolbarUXConfiguration {
    let buttonsSize: CGFloat
    let buttonsEqualSpacing: Bool

    public static func `default`() -> Self {
        return Self(buttonsSize: 40.0, buttonsEqualSpacing: true)
    }

    public static func glass() -> Self {
        return Self(buttonsSize: 30.0, buttonsEqualSpacing: false)
    }
}
