// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SwiftUI

struct VPNLocationSelectionView: View, ThemeApplicable {
    @ObservedObject var model: VPNSettingsModel

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
                recommendedCard
                Spacer(minLength: UX.cardSpacing)
                if !model.locations.isEmpty {
                    locationsList
                }
            }
            .padding(.horizontal, UX.padding)
        }
        .background(themeColors.layer1.color)
        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.locationSelection)
        .onAppear {
            applyTheme(theme: themeManager.getCurrentTheme(for: model.windowUUID))
        }
        .task {
            await model.loadLocations()
        }
        .onReceive(NotificationCenter.default.publisher(for: .ThemeDidChange)) { notification in
            guard let uuid = notification.windowUUID, uuid == model.windowUUID else { return }
            applyTheme(theme: themeManager.getCurrentTheme(for: model.windowUUID))
        }
    }

    private var recommendedCard: some View {
        RoundedCard(
            background: themeColors.layer5.color,
            cornerRadius: UX.cornerRadius,
            padding: UX.padding
        ) {
            Button {
                model.selectLocation(code: VPNServerlist.recommendedCountryCode)
            } label: {
                HStack(spacing: UX.iconSpacing) {
                    icon(named: StandardImageIdentifiers.Large.globe)
                    VStack(alignment: .leading, spacing: UX.rowSpacing) {
                        Text(verbatim: .Settings.VPN.LocationSection.RecommendedTitle)
                            .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                            .foregroundStyle(themeColors.textPrimary.color)
                        Text(model.recommendedDescription)
                            .font(FXFontStyles.Regular.footnote.scaledSwiftUIFont())
                            .foregroundStyle(themeColors.textSecondary.color)
                    }
                    Spacer()
                    checkmark(isSelected: model.isRecommendedSelected)
                }
                .contentShape(Rectangle())
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.recommendedLocationRow)
        }
    }

    @ViewBuilder
    private var locationsList: some View {
        Text(verbatim: .Settings.VPN.LocationSection.ListTitle)
            .font(FXFontStyles.Regular.caption1.scaledSwiftUIFont())
            .foregroundStyle(themeColors.textSecondary.color)
            .padding(.leading, UX.padding)
        RoundedCard(
            background: themeColors.layer5.color,
            cornerRadius: UX.cornerRadius,
            padding: UX.padding
        ) {
            VStack(alignment: .leading) {
                ForEach(Array(model.locations.enumerated()), id: \.element.id) { index, location in
                    if index > 0 {
                        Divider().foregroundStyle(themeColors.textSecondary.color)
                    }
                    locationRow(for: location)
                }
            }
        }
    }

    private func locationRow(for location: VPNSettingsModel.Location) -> some View {
        Button {
            model.selectLocation(code: location.code)
        } label: {
            HStack {
                Text(location.name)
                    .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                    .foregroundStyle(themeColors.textPrimary.color)
                Spacer()
                checkmark(isSelected: model.selectedLocationCode == location.code)
            }
            .contentShape(Rectangle())
        }
    }

    @ViewBuilder
    private func checkmark(isSelected: Bool) -> some View {
        if isSelected {
            Image(StandardImageIdentifiers.Large.checkmark)
                .renderingMode(.template)
                .resizable()
                .frame(width: UX.iconSize, height: UX.iconSize)
                .foregroundStyle(themeColors.actionPrimary.color)
                .accessibilityLabel(String.Settings.VPN.LocationSection.SelectedAccessibilityLabel)
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
    VPNLocationSelectionView(
        model: VPNSettingsModel(
            prefs: MockProfilePrefs(),
            windowUUID: WindowUUID.DefaultUITestingUUID,
            locationProvider: nil
        )
    )
}
