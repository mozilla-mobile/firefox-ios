// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// The main view displaying the settings for address autofill.
struct AddressAutofillSettingsView: View {
    // MARK: - Properties

    /// The parent window UUID.
    let windowUUID: WindowUUID

    /// The environment theme manager
    @Environment(\.themeManager)
    var themeManager

    /// The observed object for managing the toggle state.
    @ObservedObject var toggleModel: ToggleModel

    /// The observed object for managing the address list.
    @ObservedObject var addressListViewModel: AddressListViewModel

    /// The background color of the view.
    @State private var viewBackground: Color = .clear

    // MARK: - Body

    var body: some View {
        ZStack {
            // Clear color to fill the entire safe area
            Color.clear.edgesIgnoringSafeArea(.all)
            VStack {
                // Address autofill toggle component
                AddressAutofillToggle(windowUUID: windowUUID, model: toggleModel)
                    .padding(.top, 25)
                    .frame(maxWidth: .infinity)

                if addressListViewModel.showSection || addressListViewModel.isEditingFeatureEnabled {
                    AddressListView(windowUUID: windowUUID, viewModel: addressListViewModel)
                } else {
                    Spacer()
                }
            }
            .background(viewBackground)
        }
        .onAppear {
            addressListViewModel.fetchAddresses()
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
    }

    // MARK: - Theme Application

    /// Applies the theme to the view.
    /// - Parameter theme: The theme to be applied.
    func applyTheme(theme: Theme) {
        let color = theme.colors
        viewBackground = Color(color.layer1)
    }
}
