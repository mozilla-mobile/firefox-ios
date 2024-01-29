// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

/// The main view displaying the settings for address autofill.
struct AddressAutofillSettingsView: View {
    // MARK: - Properties

    /// The environment theme type.
    @Environment(\.themeType)
    var themeVal

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
                AddressAutofillToggle(model: toggleModel)
                    .padding(.top, 25)
                    .frame(maxWidth: .infinity)

                // Address list view
                AddressListView(viewModel: addressListViewModel)
            }
            .background(viewBackground)
            .onAppear {
                // Apply the theme when the view appears
                applyTheme(theme: themeVal.theme)
            }
            .onChange(of: themeVal) { newThemeValue in
                // Apply the theme when the theme value changes
                applyTheme(theme: newThemeValue.theme)
            }
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
