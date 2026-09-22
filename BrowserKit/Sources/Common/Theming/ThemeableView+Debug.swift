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
    ///
    /// Only takes effect when actually running for previews, so that DEBUG app builds keep updating their
    /// theme from `ThemeManager` through theme change notifications.
    func debugThemeHandler(for base: some View) -> some View {
        base
            .onChange(of: colorScheme) { newScheme in
                guard isRunningForPreviews else { return }

                if let privacyOverride {
                    theme = manager.resolvedTheme(with: privacyOverride)
                } else {
                    theme = newScheme == .dark ? DarkTheme() : LightTheme()
                }
            }
    }

    private var isRunningForPreviews: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
#endif
