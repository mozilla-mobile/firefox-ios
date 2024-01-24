// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common
import Shared
import Storage

// MARK: - AddressCellView

/// A view representing a cell displaying address information.
struct AddressCellView: View {
    // MARK: - Properties

    @State private var textColor: Color = .clear
    @State private var customLightGray: Color = .clear
    var address: Address
    @Environment(\.themeType)
    var themeVal
    var onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 24) {
                    Image(ImageIdentifiers.location)
                        .padding(.leading, 16)
                        .foregroundColor(.primary)
                        .offset(y: -14)
                    VStack(alignment: .leading) {
                        Text(address.givenName + " " + address.familyName)
                            .preferredBodyFont(size: 17)
                            .foregroundColor(textColor)
                        Text(address.streetAddress)
                            .preferredBodyFont(size: 15)
                            .foregroundColor(customLightGray)
                        Text(address.addressLevel2 + ", " + address.addressLevel1 + " " + address.postalCode)
                            .preferredBodyFont(size: 15)
                            .foregroundColor(customLightGray)
                    }
                    Spacer()
                }
            }
            .padding()
            Spacer().frame(height: 0)
            Divider().frame(height: 1)
        }
        .listRowInsets(EdgeInsets())
        .buttonStyle(AddressButtonStyle(theme: themeVal.theme))
        .listRowSeparator(.hidden)
        .onAppear {
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
        textColor = Color(color.textPrimary)
        customLightGray = Color(color.textSecondary)
    }
}

// MARK: - CustomButtonStyle

/// A address button style with a specific theme.
struct AddressButtonStyle: ButtonStyle {
    let theme: Theme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color(theme.colors.layer1) : Color(theme.colors.layer2))
            .foregroundColor(.white)
    }
}
