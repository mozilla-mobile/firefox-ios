// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared

/// The main view displaying the settings for the address bar position menu.
struct AddressBarSettingsView: View, FeatureFlaggable {
    let windowUUID: WindowUUID
    /// NOTE: To avoid duplication, the old view model is reused in the new address bar setting menu.
    /// TODO(FXIOS-12000): Once the experiment is done, we can remove the old viewmodel and move it to here.
    let viewModel: SearchBarSettingsViewModel

    @Environment(\.themeManager)
    var themeManager

    var prefs: Prefs

    @State private var currentTheme: Theme?

    var shouldShowNavigationBarConfig: Bool {
        return featureFlags.isFeatureEnabled(.toolbarMiddleButtonCustomization, checking: .buildOnly)
    }

    var selectedMiddleButtonType: NavigationBarMiddleButtonType {
        if let rawValue = prefs.stringForKey(PrefsKeys.Settings.navigationToolbarMiddleButton),
           let selectedButton = NavigationBarMiddleButtonType(rawValue: rawValue) {
            return selectedButton
        }

        return .newTab
    }

    private var addressBarPosition: SearchBarPosition {
        LegacyFeatureFlagsManager.shared.getCustomState(for: .searchBarPosition) ?? .bottom
    }

    private var viewBackground: Color {
        return Color(currentTheme?.colors.layer1 ?? UIColor.clear)
    }

    private struct UX {
        static let spacing: CGFloat = 24
        static let cornerRadius: CGFloat = 24
    }

    var body: some View {
        VStack {
            GenericSectionView(theme: currentTheme,
                               title: .Settings.AddressBar.AddressBarSectionTitle,
                               identifier: AccessibilityIdentifiers.Settings.SearchBar.searchBarSetting) {
                AddressBarSelectionView(
                    theme: currentTheme,
                    selectedAddressBarPosition: addressBarPosition,
                    onSelected: viewModel.saveSearchBarPosition)
                .modifier(SectionStyle(theme: currentTheme, cornerRadius: UX.cornerRadius))
            }

            if shouldShowNavigationBarConfig {
                NavigationToolbarSection(theme: currentTheme,
                                         selectedOption: selectedMiddleButtonType,
                                         onChange: updateMiddleNavigationToolbarButton,
                                         cornerRadius: UX.cornerRadius)
            }
            Spacer()
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
    }

    // MARK: NavigationToolbarSection

    private struct NavigationToolbarSection: View {
        let theme: Theme?
        let selectedOption: NavigationBarMiddleButtonType
        let onChange: @MainActor (NavigationBarMiddleButtonType) -> Void
        let cornerRadius: CGFloat

        var body: some View {
            GenericSectionView(
                theme: theme,
                title: .Settings.Appearance.NavigationToolbar.SectionHeader,
                description: .Settings.Appearance.NavigationToolbar.SectionDescription,
                identifier: AccessibilityIdentifiers.Settings.Appearance.navigationToolbarSectionTitle
            ) {
                NavigationBarMiddleButtonSelectionView(
                    theme: theme,
                    selectedMiddleButton: selectedOption,
                    onSelected: onChange)
                .modifier(SectionStyle(theme: theme, cornerRadius: cornerRadius))
            }
        }
    }

    /// Updates the middle button in navigation toolbar based on the user's selection.
    /// - Parameter selectedOption: The selected theme option from ThemeSelectionView.
    private func updateMiddleNavigationToolbarButton(to selectedOption: NavigationBarMiddleButtonType) {
        prefs.setString(selectedOption.rawValue, forKey: PrefsKeys.Settings.navigationToolbarMiddleButton)

        let action = ToolbarAction(middleButton: selectedOption,
                                   windowUUID: windowUUID,
                                   actionType: ToolbarActionType.navigationMiddleButtonDidChange)
        store.dispatch(action)
    }
}
