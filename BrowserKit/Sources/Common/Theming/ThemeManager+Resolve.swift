// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public extension ThemeManager {
    /// Resolves the theme to apply, taking the private theme override into account.
    /// - Parameters:
    ///   - window: The window whose theme is used when there is no override.
    ///   - privateOverride: `nil` follows the window's own private state. Otherwise the private theme is
    ///   forced on or off, regardless of that state.
    func resolveTheme(for window: WindowUUID?, privateOverride: Bool?) -> Theme {
        guard let privateOverride else { return getCurrentTheme(for: window) }
        return resolvedTheme(with: privateOverride)
    }

    /// Resolves the theme to apply from the `shouldUsePrivateOverride` / `shouldBeInPrivateTheme` pair
    /// that `Themeable` and `ThemeableView` expose.
    func resolveTheme(for window: WindowUUID?,
                      shouldUsePrivateOverride: Bool,
                      shouldBeInPrivateTheme: Bool) -> Theme {
        return resolveTheme(for: window,
                            privateOverride: shouldUsePrivateOverride ? shouldBeInPrivateTheme : nil)
    }
}
