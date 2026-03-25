// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

import struct MozillaAppServices.Address

// MARK: - AddressCellView

/// A view representing a cell displaying address information.
struct AddressSettingsCellView: View {
    // MARK: - Constants

    private enum UX {
        static let listIconPadding: CGFloat = -8
        static let hStackSpacing: CGFloat = 24
        static let vStackSpacing: CGFloat = 0
        static let spacerHeight: CGFloat = 0
        static let dividerHeight: CGFloat = 1
    }

    // MARK: - Properties

    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager
    let isLandscape: Bool

    @State private var textColor: Color = .clear
    @State private var customLightGray: Color = .clear
    @State private var iconPrimary: Color = .clear

    private(set) var address: Address
    private(set) var onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: UX.vStackSpacing) {
                HStack(alignment: .midIconAndLabel, spacing: UX.hStackSpacing) {
                    Image(StandardImageIdentifiers.Large.location)
                        .renderingMode(.template)
                        .modifier(ListItemIconPadding(isLandscape: isLandscape,
                                                      paddingSize: UX.listIconPadding))
                        .foregroundColor(iconPrimary)
                        .alignmentGuide(.midIconAndLabel) { $0[VerticalAlignment.center] }
                    VStack(alignment: .leading) {
                        if !address.name.isEmpty {
                            Text(address.name)
                                .font(.body)
                                .foregroundColor(textColor)
                                .alignmentGuide(.midIconAndLabel) { $0[VerticalAlignment.center] }
                        }
                        if !address.streetAddress.isEmpty {
                            Text(address.streetAddress)
                                .font(.subheadline)
                                .foregroundColor(customLightGray)
                        }
                        if !address.addressCityStateZipcode.isEmpty {
                            Text(address.addressCityStateZipcode)
                                .font(.subheadline)
                                .foregroundColor(customLightGray)
                        }
                    }
                    Spacer()
                }
            }
            .padding()
            Spacer().frame(height: UX.spacerHeight)
            Divider().frame(height: UX.dividerHeight)
        }
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color(themeManager.getCurrentTheme(for: windowUUID).colors.layer2))
        .listRowSeparator(.hidden)
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .accessibilityLabel(address.a11ySettingsRow)
    }

    // MARK: - Theme Application

    /// Applies the theme to the view.
    /// - Parameter theme: The theme to be applied.
    func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        customLightGray = Color(color.textSecondary)
        iconPrimary = Color(color.iconPrimary)
    }
}
