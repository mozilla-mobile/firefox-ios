// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// SwiftUITheme protocol embeds theme so that we can use Theme in SwiftUI.
/// EnvironmentValues in SwiftUI requires an Equatable type but changing
/// Theme directly to Equatable isn't a viable solution for the rest of the app
/// that is built using UIKit
public struct SwiftUITheme: Equatable {
    public var theme: Theme

    public init(theme: Theme) {
        self.theme = theme
    }

    public static func == (lhs: SwiftUITheme, rhs: SwiftUITheme) -> Bool {
        return lhs.theme.type == rhs.theme.type
    }
}
