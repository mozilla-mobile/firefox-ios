// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

extension LegacyThemeManager {
    // Ecosia: theme changing on a central place
    func themeChanged(from: UITraitCollection?, to: UITraitCollection, forceDark: Bool = false) {
        let colorHasChanged = to.hasDifferentColorAppearance(comparedTo: from)


        // Do not change theme if it was dark before night mode already
        guard colorHasChanged,
              !forceDark,
              systemThemeIsOn else { return }

        let userInterfaceStyle = to.userInterfaceStyle
        current = userInterfaceStyle == .dark ? LegacyDarkTheme() : LegacyNormalTheme()
    }
}
