/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

// MARK: - Protocol
protocol Themeable { }

extension Themeable {
    var themeManager: ThemeManager { return ThemeManager.shared }
}

class ThemeManager {

    static let shared = ThemeManager()

    // If needed, we can easily check the system theme here.
    var systemTheme: UIUserInterfaceStyle {
        return UIScreen.main.traitCollection.userInterfaceStyle
    }

    var currentTheme: Theme {
        return FxDefaultTheme()
    }
}
