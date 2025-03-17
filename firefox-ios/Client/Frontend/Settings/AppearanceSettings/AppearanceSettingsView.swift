// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// The main view displaying the settings for the appearance menu.
struct AppearanceSettingsView: View {
    let windowUUID: WindowUUID

    @Environment(\.themeManager)
    var themeManager

    @State private var currentTheme: Theme?

    /// Compute the theme option to display in the ThemeSelectionView.
    /// - Returns: .automatic if system theme or automatic brightness is enabled;
    ///            otherwise, .light or .dark based on the manual theme.
    var themeOption: ThemeSelectionView.ThemeOption {
        if themeManager.systemThemeIsOn || themeManager.automaticBrightnessIsOn {
            return .automatic
        } else {
            return themeManager.getUserManualTheme() == .light ? .light : .dark
        }
    }

    private var viewBackground: Color {
        return Color(currentTheme?.colors.layer1 ?? UIColor.clear)
    }

    private struct UX {
        static let spacing: CGFloat = 24
    }

    var body: some View {
        VStack {
            // Section for selecting the browser theme.
            GenericSectionView(theme: currentTheme, title: String.BrowserThemeSectionHeader) {
                ThemeSelectionView(theme: currentTheme,
                                   selectedThemeOption: themeOption,
                                   onThemeSelected: updateBrowserTheme)
            }
            // Section for toggling website appearance (e.g., dark mode).
            GenericSectionView(theme: currentTheme,
                               title: String.WebsiteAppearanceSectionHeader,
                               description: String.WebsiteDarkModeDescription) {
                DarkModeToggleView(theme: currentTheme,
                                   isEnabled: NightModeHelper.isActivated(),
                                   onChange: setWebsiteDarkMode)
            }
            Spacer()
        }
        .padding(.top, UX.spacing)
        .frame(maxWidth: .infinity)
        .background(viewBackground)
        .onAppear {
            currentTheme = themeManager.getCurrentTheme(for: windowUUID)
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            currentTheme = themeManager.getCurrentTheme(for: windowUUID)
        }
    }

    /// Updates the theme using the ThemeManager based on the user's selection.
    /// - Parameter selectedOption: The selected theme option from ThemeSelectionView.
    private func updateBrowserTheme(to selectedOption: ThemeSelectionView.ThemeOption) {
        let isAutomatic = selectedOption == .automatic
        themeManager.setSystemTheme(isOn: isAutomatic)
        if !isAutomatic {
            themeManager.setManualTheme(to: selectedOption == .light ? .light : .dark)
        }
    }

    /// Toggles the website dark mode.
    /// - Parameter isOn: A Boolean indicating whether dark mode is enabled for websites.
    private func setWebsiteDarkMode(_ isOn: Bool) {
        NightModeHelper.toggle()
        if NightModeHelper.isActivated() {
            // TODO(FXIOS-11584): Add telemetry here
        } else {
            // TODO(FXIOS-11584): Add telemetry here
        }
    }
}
