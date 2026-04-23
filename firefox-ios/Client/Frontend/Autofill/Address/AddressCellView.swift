// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import Common

import struct MozillaAppServices.Address

// MARK: - AddressCellView

/// A view representing a cell displaying address information.
struct AddressCellView: View {
    // MARK: - Constants

    private enum UX {
        static let listIconPadding: CGFloat = -8
        static let hStackSpacing: CGFloat = 24
        static let vStackSpacing: CGFloat = 0
        static let dividerHeight: CGFloat = 1
    }

    // MARK: - Properties

    let windowUUID: WindowUUID
    @Environment(\.themeManager)
    var themeManager

    @State private var textColor: Color = .clear
    @State private var customLightGray: Color = .clear
    @State private var iconPrimary: Color = .clear
    @State private var backgroundColor: Color = .clear
    @State private var highlightColor: Color = .clear

    @State private var isHighlighted = false
    @GestureState private var isPressing = false
    @State private var isLandscape = false

    private(set) var address: Address
    private(set) var onTap: () -> Void

    // MARK: - Body

    var body: some View {
        VStack(spacing: UX.vStackSpacing) {
            HStack(alignment: .midIconAndLabel, spacing: UX.hStackSpacing) {
                Image(decorative: StandardImageIdentifiers.Large.location)
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
            .padding()
            Divider().frame(height: UX.dividerHeight)
        }
        .contentShape(Rectangle())
        .onChange(of: isPressing) { pressing in
            if pressing {
                isHighlighted = true
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    isHighlighted = false
                }
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($isPressing) { _, state, _ in state = true }
                .onEnded { value in
                    let isWithinTapBounds = abs(value.translation.width) < 20
                        && abs(value.translation.height) < 20
                    if isWithinTapBounds {
                        onTap()
                    }
                }
        )
        .listRowInsets(EdgeInsets())
        .listRowBackground(
            (isHighlighted ? highlightColor : backgroundColor)
                .edgesIgnoringSafeArea([.leading, .trailing])
        )
        .listRowSeparator(.hidden)
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            isLandscape = UIDevice.current.orientation.isLandscape
        }
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.Address.Addresses.addressCell)
        .accessibilityLabel(address.a11ySettingsRow)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
    }

    // MARK: - Theme Application

    /// Applies the theme to the view.
    /// - Parameter theme: The theme to be applied.
    func applyTheme(theme: Theme) {
        let color = theme.colors
        textColor = Color(color.textPrimary)
        customLightGray = Color(color.textSecondary)
        iconPrimary = Color(color.iconPrimary)
        backgroundColor = Color(color.layer2)
        highlightColor = Color(color.layer5Hover)
    }
}
