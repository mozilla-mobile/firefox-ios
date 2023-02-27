// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Shared
import Common

extension EnvironmentValues {
    public var themeType: SwiftUITheme {
        let themeManager: ThemeManager = AppContainer.shared.resolve()

        guard themeManager.currentTheme.type != .dark else {
            let swiftUITheme = SwiftUITheme(theme: DarkTheme())
            return swiftUITheme
        }

        let swiftUITheme = SwiftUITheme(theme: themeManager.currentTheme)
        return swiftUITheme
    }
}
