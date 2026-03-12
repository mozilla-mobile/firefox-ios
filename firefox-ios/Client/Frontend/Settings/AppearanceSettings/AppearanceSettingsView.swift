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
    @State private var showColorPicker = false
    @State private var showBackgroundTintPicker = false
    @State private var showToolbarTintPicker = false

    var shouldShowPageZoom: Bool {
        return featureFlags.isFeatureEnabled(.defaultZoomFeature, checking: .buildOnly)
    }

    private var shouldShowCustomTheming: Bool {
        themeManager.isCustomThemingEnabled
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
        static var spacingCurrentOS: CGFloat {
            guard #available(iOS 26.0, *) else { return 0 }
            return UX.spacing
        }
        // Debug flag: show free-pick color pickers (accent/background/toolbar).
        // When false, only curated JSON themes are shown.
        static let showCustomColorPickers = false
        // Debug flag: show the curated JSON theme picker section.
        static let showCuratedThemes = true
    }

    var body: some View {
        ScrollView {
            settingsContent
        }
        .modifier(PaddingStyle(theme: currentTheme, spacing: UX.spacing))
        .background(viewBackground)
        .onAppear {
            currentTheme = themeManager.getCurrentTheme(for: windowUUID)
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            currentTheme = themeManager.getCurrentTheme(for: windowUUID)
        }
        .sheet(isPresented: $showColorPicker) {
            ColorPickerSheet(themeManager: themeManager)
        }
        .sheet(isPresented: $showBackgroundTintPicker) {
            BackgroundTintColorPickerSheet(themeManager: themeManager)
        }
        .sheet(isPresented: $showToolbarTintPicker) {
            ToolbarTintColorPickerSheet(themeManager: themeManager)
        }
    }

    // MARK: - Settings Content

    @ViewBuilder
    private var settingsContent: some View {
        VStack(spacing: UX.spacingCurrentOS) {
            themeSections
            customizationSections
            Spacer()
        }
    }

    @ViewBuilder
    private var themeSections: some View {
        BrowserThemeSection(
            theme: currentTheme,
            themeOption: themeOption,
            onThemeSelected: updateBrowserTheme,
            cornerRadius: UX.cornerRadius
        )

        if shouldShowCustomTheming && UX.showCustomColorPickers {
            AccentColorSectionView(
                theme: currentTheme,
                themeManager: themeManager,
                cornerRadius: UX.cornerRadius,
                showColorPicker: $showColorPicker
            )
        }

        if shouldShowCustomTheming && UX.showCustomColorPickers {
            BackgroundTintSectionView(
                theme: currentTheme,
                themeManager: themeManager,
                cornerRadius: UX.cornerRadius,
                showColorPicker: $showBackgroundTintPicker
            )
        }

        if shouldShowCustomTheming && UX.showCustomColorPickers {
            ToolbarTintSectionView(
                theme: currentTheme,
                themeManager: themeManager,
                cornerRadius: UX.cornerRadius,
                showColorPicker: $showToolbarTintPicker
            )
        }

        if shouldShowCustomTheming && UX.showCuratedThemes {
            CuratedThemesSectionView(
                theme: currentTheme,
                themeManager: themeManager,
                cornerRadius: UX.cornerRadius
            )
        }
    }

    @ViewBuilder
    private var customizationSections: some View {
        if shouldShowCustomTheming {
            UnsplashWallpaperSectionView(
                theme: currentTheme,
                cornerRadius: UX.cornerRadius
            )
        }

        WebsiteAppearanceSection(
            theme: currentTheme,
            onChange: setWebsiteDarkMode,
            cornerRadius: UX.cornerRadius
        )

        if shouldShowPageZoom {
            PageZoomSection(theme: currentTheme, cornerRadius: UX.cornerRadius) {
                delegate?.pressedPageZoom()
            }
        }
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
