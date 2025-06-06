// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared

/// The main view displaying the settings for the address bar position menu.
struct AddressBarSettingsView: View {
    let windowUUID: WindowUUID
    /// NOTE: To avoid duplication, the old view model is reused in the new address bar setting menu.
    /// TODO(FXIOS-12000): Once the experiment is done, we can remove the old viewmodel and move it to here.
    let viewModel: SearchBarSettingsViewModel

    @Environment(\.themeManager)
    var themeManager

    @State private var currentTheme: Theme?

    private var addressBarPosition: SearchBarPosition {
        LegacyFeatureFlagsManager.shared.getCustomState(for: .searchBarPosition) ?? .bottom
    }

    private var viewBackground: Color {
        return Color(currentTheme?.colors.layer1 ?? UIColor.clear)
    }

    private struct UX {
        static let spacing: CGFloat = 24
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
}
