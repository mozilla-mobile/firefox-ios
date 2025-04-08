// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

public enum ReaderModeTheme: String {
    case light
    case dark
    case sepia

    public static func preferredTheme(for theme: ReaderModeTheme? = nil, window: WindowUUID?) -> ReaderModeTheme {
        let themeManager: ThemeManager = AppContainer.shared.resolve()

        let appTheme: Theme = {
            guard let uuid = window else { return themeManager.windowNonspecificTheme() }
            return themeManager.getCurrentTheme(for: uuid)
        }()

        guard appTheme.type != .dark else { return .dark }

        return theme ?? ReaderModeTheme.light
    }
}
