// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum ThemeType: String {
    case light = "normal" // This needs to match the string used in the legacy system
    case dark

    func getInterfaceStyle() -> UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func getBarStyle() -> UIBarStyle {
        switch self {
        case .light:
            return .default
        case .dark:
            return .black
        }
    }

    func getThemedImageName(name: String) -> String {
        switch self {
        case .light:
            return name
        case .dark:
            return "\(name)_dark"
        }
    }

    /// If App Theme is Dark it will return  .dark reader mode theme,
    /// if not we return the selected ReaderModeTheme defaulting to .light if value is nil
    /// - Parameter reader mode theme: ReaderModeTheme
    /// - Returns: ReaderModeTheme based on reader mode theme and App Theme
    func getReaderMode(for theme: ReaderModeTheme? = nil) -> ReaderModeTheme {
        guard self != .dark else { return .dark }

        return theme ?? .light
    }
}
