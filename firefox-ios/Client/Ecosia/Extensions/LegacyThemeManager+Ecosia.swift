// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Common

extension LegacyThemeManager {
    /// Updates the theme based on the changes in the trait collection.
    ///
    /// - Parameters:
    ///   - from: The previous trait collection. This is optional as it may be nil when there's no previous state to compare to.
    ///   - to: The new trait collection after the change. This is used to determine the current theme settings.
    ///   - forceDark: A boolean indicating whether the dark theme should be forced on regardless of the system theme. The default value is `false`.
    func themeChanged(from: UITraitCollection?, to: UITraitCollection, forceDark: Bool = false) {
        // Determine if the color appearance has changed between the previous and new trait collections.
        let colorHasChanged = to.hasDifferentColorAppearance(comparedTo: from)

        // Return early and do not change the theme if the color hasn't changed, dark mode is forced,
        // or the system theme is already in effect.
        guard colorHasChanged,
              !forceDark,
              systemThemeIsOn else { return }

        // Update the current theme based on the new user interface style.
        let userInterfaceStyle = to.userInterfaceStyle
        current = userInterfaceStyle == .dark ? LegacyDarkTheme() : LegacyNormalTheme()
    }
}

/* TODO Ecosia Upgrade: Re-add if LegacyThemeManager is kept [MOB-3152]
extension LegacyThemeManager {

    /// Updates the current theme based on the system theme type provided by the `EcosiaThemeManager`.
    ///
    /// This method retrieves the `EcosiaThemeManager` from the shared `AppContainer` and updates
    /// the theme accordingly. It checks whether the system theme type is dark and sets the
    /// `current` theme to `LegacyDarkTheme` or `LegacyNormalTheme` based on that.
    static func updateBasedOnCurrentSystemThemeType() {
        // Update the current theme based on the system theme type.
        LegacyThemeManager.instance.current = EcosiaThemeManager.getSystemThemeType() == .dark ? LegacyDarkTheme() : LegacyNormalTheme()
    }
}
*/
