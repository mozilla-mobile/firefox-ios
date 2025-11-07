// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

#if DEBUG
import SwiftUI

/// Debug-specific theme change handling for SwiftUI previews.
/// This extension provides theme change listening functionality that works in Xcode previews
/// by responding to the color scheme environment changes.
extension ThemeChangeListener {
    /// Handles debug-specific theme changes for SwiftUI previews.
    /// Since NotificationCenter doesn't work in preview environment,
    /// this responds to Xcode's light/dark mode toggle instead.
    var debugThemeHandler: some View {
        content
            .onChange(of: colorScheme) { newScheme in
                let newTheme: any Theme = newScheme == .dark ? DarkTheme() : LightTheme()
                theme = newTheme
            }
    }
}
#endif
