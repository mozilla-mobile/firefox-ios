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
struct AppearanceSettingsView: View, FeatureFlaggable {
    let windowUUID: WindowUUID
    weak var delegate: AppearanceSettingsDelegate?

    @Environment(\.themeManager)
    var themeManager

    @State private var currentTheme: Theme?

    var shouldShowPageZoom: Bool {
        return featureFlags.isFeatureEnabled(.defaultZoomFeature, checking: .buildOnly)
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
        return Color(currentTheme?.colors.layer1 ?? UIColor.clear)
    }

    private struct UX {
        static let spacing: CGFloat = 24
        static let cornerRadius: CGFloat = 24
    }

    private var shouldUseNewStyle: Bool {
        if #available(iOS 26.0, *) {
            return true
        } else {
            return false
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: shouldUseNewStyle ? UX.spacing : 0) {
                // Section for selecting the browser theme.
                browserThemeSection()

                // Section for toggling website appearance (e.g., dark mode).
                websiteAppearanceSection()

                if shouldShowPageZoom {
                    pageZoomSection()
                }
                Spacer()
            }
            .applyPaddingForSectionIfAvailable(spacing: UX.spacing, shouldUseNewStyle)
        }
        .applyPaddingForViewIfAvailable(spacing: UX.spacing, shouldUseNewStyle)
        .background(viewBackground)
        .onAppear {
            currentTheme = themeManager.getCurrentTheme(for: windowUUID)
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            currentTheme = themeManager.getCurrentTheme(for: windowUUID)
        }
    }

    private func browserThemeSection() -> some View {
        GenericSectionView(theme: currentTheme,
                           title: String.BrowserThemeSectionHeader,
                           identifier: AccessibilityIdentifiers.Settings.Appearance.browserThemeSectionTitle,
                           shouldUseDivider: !shouldUseNewStyle) {
            ThemeSelectionView(theme: currentTheme,
                               selectedThemeOption: themeOption,
                               onThemeSelected: updateBrowserTheme)
            .applyNewStyleForSectionIfAvailable(theme: currentTheme,
                                                cornerRadius: UX.cornerRadius,
                                                shouldUseNewStyle)
        }
    }

    private func websiteAppearanceSection() -> some View {
        GenericSectionView(theme: currentTheme,
                           title: String.WebsiteAppearanceSectionHeader,
                           description: String.WebsiteDarkModeDescription,
                           identifier: AccessibilityIdentifiers.Settings.Appearance.websiteAppearanceSectionTitle,
                           shouldUseDivider: !shouldUseNewStyle) {
            DarkModeToggleView(theme: currentTheme,
                               isEnabled: NightModeHelper.isActivated(),
                               onChange: setWebsiteDarkMode)
            .applyNewStyleForSectionIfAvailable(theme: currentTheme,
                                                cornerRadius: UX.cornerRadius,
                                                shouldUseNewStyle)
        }
    }

    private func pageZoomSection() -> some View {
        GenericSectionView(theme: currentTheme,
                           title: .Settings.Appearance.PageZoom.SectionHeader,
                           identifier: .Settings.Appearance.PageZoom.SectionHeader,
                           shouldUseDivider: !shouldUseNewStyle) {
            GenericItemCellView(title: .Settings.Appearance.PageZoom.PageZoomTitle,
                                image: .chevronRightLarge,
                                theme: currentTheme) {
                delegate?.pressedPageZoom()
            }
            .applyNewStyleForSectionIfAvailable(theme: currentTheme,
                                                cornerRadius: UX.cornerRadius,
                                                shouldUseNewStyle)
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

extension View {
    @ViewBuilder
    func applyNewStyleForSectionIfAvailable(theme: Theme?, cornerRadius: CGFloat, _ shouldUseNewStyle: Bool) -> some View {
        if shouldUseNewStyle {
            self
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(theme?.colors.layer2 ?? UIColor.clear))
                )
        } else {
            self
        }
    }

    @ViewBuilder
    func applyPaddingForSectionIfAvailable(spacing: CGFloat, _ shouldUseNewStyle: Bool) -> some View {
        if shouldUseNewStyle {
            self
                .padding(.top, spacing)
                .padding(.horizontal, spacing / 2)
        } else {
            self
        }
    }

    @ViewBuilder
    func applyPaddingForViewIfAvailable(spacing: CGFloat, _ shouldUseNewStyle: Bool) -> some View {
        if shouldUseNewStyle {
            self
        } else {
            self
                .padding(.top, spacing)
                .frame(maxWidth: .infinity)
        }
    }
}
