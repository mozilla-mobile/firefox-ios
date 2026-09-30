// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SwiftUI

struct VPNSettingsView: View, ThemeApplicable {
    @ObservedObject var model: VPNSettingsModel

    /// Pushing the location picker is the coordinator's job — this screen is hosted inside the
    /// settings `UINavigationController`, so it has no SwiftUI navigation stack of its own.
    let onTapLocation: () -> Void

    // MARK: - Theming
    // FIXME FXIOS-11472 Improve our SwiftUI theming
    @Environment(\.themeManager)
    var themeManager
    @State private var themeColors: ThemeColourPalette = LightTheme().colors

    private struct UX {
        static let cornerRadius: CGFloat = 32
        static let cardSpacing: CGFloat = 24
        static let padding: CGFloat = 16
        static let rowSpacing: CGFloat = 4
        static let iconSpacing: CGFloat = 12
        static let iconSize: CGFloat = 24
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text(model.description)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(themeColors.textPrimary.color)
                    .padding(.horizontal, UX.padding)
                Spacer(minLength: UX.cardSpacing)
                vpnToggleCard
                Spacer(minLength: UX.cardSpacing)
                locationSection
            }
            .padding(.horizontal, UX.padding)
        }
        .background(themeColors.layer1.color)
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: model.windowUUID))
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == model.windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: model.windowUUID))
        }
    }

    private var vpnToggleCard: some View {
        RoundedCard(
            background: themeColors.layer5.color,
            cornerRadius: UX.cornerRadius,
            padding: UX.padding
        ) {
            Toggle(isOn: Binding(
                get: { model.isVPNOn },
                set: { newValue in
                    Task { await model.toggleVPN(to: newValue) }
                }
            )) {
                HStack(spacing: UX.iconSpacing) {
                    icon(named: StandardImageIdentifiers.Large.globe)
                    Text(verbatim: .Settings.VPN.ToggleTitle)
                        .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                        .foregroundStyle(themeColors.textPrimary.color)
                }
            }
            .tint(themeColors.actionPrimary.color)
            .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.toggle)
        }
    }

    @ViewBuilder
    private var locationSection: some View {
        Text(verbatim: .Settings.VPN.LocationSection.Title)
            .font(FXFontStyles.Regular.caption1.scaledSwiftUIFont())
            .foregroundStyle(themeColors.textSecondary.color)
            .padding(.leading, UX.padding)
        RoundedCard(
            background: themeColors.layer5.color,
            cornerRadius: UX.cornerRadius,
            padding: UX.padding
        ) {
            Button(action: onTapLocation) {
                HStack {
                    VStack(alignment: .leading, spacing: UX.rowSpacing) {
                        Text(model.selectedLocationName)
                            .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                            .foregroundStyle(themeColors.textPrimary.color)
                        if model.isRecommendedSelected {
                            Text(model.recommendedDescription)
                                .font(FXFontStyles.Regular.footnote.scaledSwiftUIFont())
                                .foregroundStyle(themeColors.textSecondary.color)
                        }
                    }
                    Spacer()
                    icon(named: StandardImageIdentifiers.Large.chevronRight)
                }
                .contentShape(Rectangle())
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.locationRow)
        }
    }

    private func icon(named name: String) -> some View {
        Image(decorative: name)
            .renderingMode(.template)
            .resizable()
            .frame(width: UX.iconSize, height: UX.iconSize)
            .foregroundStyle(themeColors.iconPrimary.color)
    }

    func applyTheme(theme: any Common.Theme) {
        self.themeColors = theme.colors
    }
}

#Preview {
    VPNSettingsView(
        model: VPNSettingsModel(
            prefs: MockProfilePrefs(),
            windowUUID: WindowUUID.DefaultUITestingUUID,
            locationProvider: nil
        ),
        onTapLocation: {}
    )
}
