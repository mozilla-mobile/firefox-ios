// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared
import Storage

// MARK: - AddressListView

/// A view displaying a list of addresses.
struct AddressListView: View {
    // MARK: - Properties

    @Environment(\.themeType)
    var themeVal
    @ObservedObject var viewModel: AddressListViewModel
    @State private var customLightGray: Color = .clear

    // MARK: - Body

    var body: some View {
        List {
            if viewModel.showSection {
                Section(header: Text(String.Addresses.Settings.SavedAddressesSectionTitle)) {
                    ForEach(viewModel.addresses, id: \.self) { address in
                        AddressCellView(
                            address: address,
                            themeVal: _themeVal,
                            onTap: {
                                // TODO: PHASE - 2: FXIOS-7653 Handle action when address cell is tapped.
                            }
                        )
                    }
                }
                .font(.caption)
                .foregroundColor(customLightGray)
            }
        }
        .listStyle(.plain)
        .listRowInsets(EdgeInsets())
        .onAppear {
            viewModel.fetchAddresses()
            applyTheme(theme: themeVal.theme)
        }
        .onChange(of: themeVal) { newThemeValue in
            applyTheme(theme: newThemeValue.theme)
        }
    }

    // MARK: - Theme Application

    /// Applies the theme to the view.
    /// - Parameter theme: The theme to be applied.
    func applyTheme(theme: Theme) {
        let color = theme.colors
        customLightGray = Color(color.textSecondary)
    }
}
