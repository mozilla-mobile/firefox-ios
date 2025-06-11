// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// A view that represents a selectable theme option.
struct ThemeOptionView: View {
    let theme: ThemeSelectionView.ThemeOption
    /// A flag indicating whether this option is currently selected.
    let isSelected: Bool
    /// Callback executed when a new theme option is selected.
    let onSelected: (() -> Void)?

    var body: some View {
        GenericImageOption(
            isSelected: isSelected,
            onSelected: onSelected,
            label: theme.rawValue,
            imageName: imageName(for: theme),
            a11yIdentifier: identifierName(for: theme)
        )
    }

    func imageName(for themeOption: ThemeSelectionView.ThemeOption) -> String {
        switch themeOption {
        case .automatic:
            return ImageIdentifiers.Appearance.automaticBrowserThemeGradient
        case .light:
            return ImageIdentifiers.Appearance.lightBrowserThemeGradient
        case .dark:
            return ImageIdentifiers.Appearance.darkBrowserThemeGradient
        }
    }

    func identifierName(for themeOption: ThemeSelectionView.ThemeOption) -> String {
        switch themeOption {
        case .automatic:
            return AccessibilityIdentifiers.Settings.Appearance.automaticThemeView
        case .light:
            return AccessibilityIdentifiers.Settings.Appearance.lightThemeView
        case .dark:
            return AccessibilityIdentifiers.Settings.Appearance.darkThemeView
        }
    }
}
