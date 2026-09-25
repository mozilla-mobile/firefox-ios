// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public extension ThemeManager {
    /// `privateOverride: nil` follows the window's own private state; otherwise the private theme is
    /// forced on or off, regardless of that state.
    func resolveTheme(for window: WindowUUID?, privateOverride: Bool?) -> Theme {
        guard let privateOverride else { return getCurrentTheme(for: window) }
        return resolvedTheme(with: privateOverride)
    }

    func resolveTheme(for window: WindowUUID?,
                      shouldUsePrivateOverride: Bool,
                      shouldBeInPrivateTheme: Bool) -> Theme {
        return resolveTheme(for: window,
                            privateOverride: shouldUsePrivateOverride ? shouldBeInPrivateTheme : nil)
    }
}
