// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared

/// The main view displaying the settings for the address bar position menu.
struct AddressBarSettingsView: ThemeableView, UserFeaturePreferenceProvider {
    let windowUUID: WindowUUID
    /// NOTE: To avoid duplication, the old view model is reused in the new address bar setting menu.
    /// TODO(FXIOS-12000): Once the experiment is done, we can remove the old viewmodel and move it to here.
    let viewModel: SearchBarSettingsViewModel

    let themeManager: ThemeManager

    var prefs: Prefs

    @State var theme: Theme

    /// Settings are always shown in the regular theme, even while the user browses in private mode.
    var shouldUsePrivateOverride: Bool { return true }
    var shouldBeInPrivateTheme: Bool { return false }

    init(windowUUID: WindowUUID,
         viewModel: SearchBarSettingsViewModel,
         prefs: Prefs,
         themeManager: ThemeManager = AppContainer.shared.resolve()) {
        self.windowUUID = windowUUID
        self.viewModel = viewModel
        self.prefs = prefs
        self.themeManager = themeManager
        self.theme = themeManager.resolveTheme(for: windowUUID, privateOverride: false)
    }

    var selectedMiddleButtonType: NavigationBarMiddleButtonType {
        if let rawValue = prefs.stringForKey(PrefsKeys.Settings.navigationToolbarMiddleButton),
           let selectedButton = NavigationBarMiddleButtonType(rawValue: rawValue) {
            return selectedButton
        }

        return .newTab
    }

    private var addressBarPosition: SearchBarPosition {
        userPreferences.searchBarPosition
    }

    private var viewBackground: Color {
        return Color(theme.colors.layer1)
    }

    private struct UX {
        static let spacing: CGFloat = 24
        static let cornerRadius: CGFloat = 24
    }

    var body: some View {
        ScrollView {
            VStack {
                GenericSectionView(theme: theme,
                                   title: .Settings.AddressBar.AddressBarSectionTitle,
                                   identifier: AccessibilityIdentifiers.Settings.SearchBar.searchBarSetting) {
                    AddressBarSelectionView(
                        theme: theme,
                        selectedAddressBarPosition: addressBarPosition,
                        onSelected: viewModel.saveSearchBarPosition)
                    .modifier(SectionStyle(theme: theme, cornerRadius: UX.cornerRadius))
                }

                NavigationToolbarSection(theme: theme,
                                         selectedOption: selectedMiddleButtonType,
                                         onChange: updateMiddleNavigationToolbarButton,
                                         cornerRadius: UX.cornerRadius)
                Spacer()
            }
        }
        .modifier(PaddingStyle(theme: theme, spacing: UX.spacing))
        .background(viewBackground)
        .listenToThemeChanges(in: self, theme: $theme)
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
