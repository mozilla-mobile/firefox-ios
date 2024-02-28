// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared
import Storage

// MARK: - AddressScrollView

/// A view displaying a list of addresses.
struct AddressScrollView: View {
    // MARK: - Properties

    @Environment(\.themeType)
    var themeVal
    @ObservedObject var viewModel: AddressListViewModel
    @State private var customLightGray: Color = .clear
    // Environment variable to access the presentation mode
    @Environment(\.presentationMode)
    var presentationMode

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(viewModel.addresses, id: \.self) { address in
                    AddressCellView(
                        address: address,
                        themeVal: _themeVal,
                        onTap: {
                            viewModel.handleAddressSelection(address)
                            withAnimation {
                                presentationMode.wrappedValue.dismiss()
                            }
                        })
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
