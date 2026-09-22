// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// Child settings pages appearance actions
protocol AppearanceSettingsDelegate: AnyObject {
    @MainActor
    func pressedPageZoom()
}

/// The main view displaying the settings for the appearance menu.
struct AppearanceSettingsView: ThemeableView {
    let windowUUID: WindowUUID
    let themeManager: ThemeManager
    weak var delegate: AppearanceSettingsDelegate?

    @State var theme: Theme

    /// Settings are always shown in the regular theme, even while the user browses in private mode.
    var shouldUsePrivateOverride: Bool { return true }
    var shouldBeInPrivateTheme: Bool { return false }

    init(windowUUID: WindowUUID,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         delegate: AppearanceSettingsDelegate? = nil) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.delegate = delegate
        self.theme = themeManager.resolveTheme(for: windowUUID, privateOverride: false)
    }

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
        return Color(theme.colors.layer1)
    }

    private struct UX {
        static let spacing: CGFloat = 24
        static let cornerRadius: CGFloat = 24
        static var spacingCurrentOS: CGFloat {
            guard #available(iOS 26.0, *) else { return 0 }
            return UX.spacing
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: UX.spacingCurrentOS) {
                // Section for selecting the browser theme.
                BrowserThemeSection(
                    theme: theme,
                    themeOption: themeOption,
                    onThemeSelected: updateBrowserTheme,
                    cornerRadius: UX.cornerRadius
                )

                // Section for toggling website appearance (e.g., dark mode).
                WebsiteAppearanceSection(theme: theme, onChange: setWebsiteDarkMode, cornerRadius: UX.cornerRadius)

                PageZoomSection(theme: theme, cornerRadius: UX.cornerRadius) {
                    delegate?.pressedPageZoom()
                }

                Spacer()
            }
        }
        .modifier(PaddingStyle(theme: theme, spacing: UX.spacing))
        .background(viewBackground)
        .listenToThemeChanges(in: self, theme: $theme)
    }

    // MARK: Subcomponents
    private struct BrowserThemeSection: View {
        let theme: Theme?
        let themeOption: ThemeSelectionView.ThemeOption
        let onThemeSelected: (ThemeSelectionView.ThemeOption) -> Void
        let cornerRadius: CGFloat

        var body: some View {
            GenericSectionView(
                theme: theme,
                title: String.BrowserThemeSectionHeader,
                identifier: AccessibilityIdentifiers.Settings.Appearance.browserThemeSectionTitle
            ) {
                ThemeSelectionView(
                    theme: theme,
                    selectedThemeOption: themeOption,
                    onThemeSelected: onThemeSelected
                )
                .modifier(SectionStyle(theme: theme, cornerRadius: cornerRadius))
            }
        }
    }

    private struct WebsiteAppearanceSection: View {
        let theme: Theme?
        let onChange: (Bool) -> Void
        let cornerRadius: CGFloat

        var body: some View {
            GenericSectionView(
                theme: theme,
                title: String.WebsiteAppearanceSectionHeader,
                description: String.WebsiteDarkModeDescription,
                identifier: AccessibilityIdentifiers.Settings.Appearance.websiteAppearanceSectionTitle
            ) {
                DarkModeToggleView(
                    theme: theme,
                    isEnabled: NightModeHelper.isActivated(),
                    onChange: onChange
                )
                .modifier(SectionStyle(theme: theme, cornerRadius: cornerRadius))
            }
        }
    }

    private struct PageZoomSection: View {
        let theme: Theme?
        let cornerRadius: CGFloat
        let onTap: () -> Void

        var body: some View {
            GenericSectionView(
                theme: theme,
                title: .Settings.Appearance.PageZoom.SectionHeader,
                identifier: AccessibilityIdentifiers.Settings.Appearance.pageZoomTitle
            ) {
                GenericItemCellView(
                    title: .Settings.Appearance.PageZoom.PageZoomTitle,
                    image: .chevronRightLarge,
                    theme: theme
                ) {
                    onTap()
                }
                .modifier(SectionStyle(theme: theme, cornerRadius: cornerRadius))
            }
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
