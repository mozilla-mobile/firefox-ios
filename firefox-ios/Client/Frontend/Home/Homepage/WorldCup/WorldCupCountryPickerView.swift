// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

private extension View {
    @ViewBuilder
    func skipButtonStyle(theme: Theme) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent)
                .tint(theme.colors.actionPrimary.color)
                .foregroundStyle(theme.colors.textInverted.color)
        } else {
            self.buttonStyle(.borderless)
                .foregroundStyle(theme.colors.actionPrimary.color)
        }
    }
}

struct WorldCupCountryPickerView: View, ThemeableView {
    private struct UX {
        static let contentHorizontalPadding: CGFloat = 22
        static let contentTopPadding: CGFloat = 8.0
        static let contentBottomPadding: CGFloat = 24
        static let sectionSpacing: CGFloat = 16
        static let sectionCornerRadius: CGFloat = 12
        static let sectionInnerPadding: CGFloat = 16
        static let sectionHeaderLeadingPadding: CGFloat = 16
        static let sectionHeaderBottomPadding: CGFloat = 8
        static let gridColumns = 4
        static let gridSpacing: CGFloat = 6
        static let gridRowSpacing: CGFloat = 16
        static let flagSize = CGSize(width: 60, height: 40)
        static let flagToLabelSpacing: CGFloat = 10
    }

    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    @State var theme: Theme

    private let regions = WorldCupCountryData.regions

    init(windowUUID: WindowUUID, themeManager: ThemeManager) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: UX.gridSpacing), count: UX.gridColumns)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: UX.sectionSpacing) {
                    ForEach(regions) { region in
                        regionSection(region)
                    }
                }
                .padding(.horizontal, UX.contentHorizontalPadding)
                .padding(.bottom, UX.contentBottomPadding)
                .padding(.top, UX.contentTopPadding)
            }
            .navigationTitle(Text(String.WorldCup.CountryPicker.Title))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {}
                    label: {
                        Image(StandardImageIdentifiers.Large.cross)
                            .renderingMode(.template)
                    }
                    .foregroundStyle(theme.colors.iconPrimary.color)
                    .accessibilityLabel(Text(String.WorldCup.CountryPicker.CloseButtonAccessibilityLabel))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") {}
                    .skipButtonStyle(theme: theme)
                }
            }
        }
        .background(Color(theme.colors.layer3))
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    // MARK: - Region Section

    private func regionSection(_ region: WorldCupRegion) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(region.name.uppercased())
                .font(FXFontStyles.Bold.subheadline.scaledSwiftUIFont())
                .foregroundColor(Color(theme.colors.textSecondary))
                .padding(.bottom, UX.sectionHeaderBottomPadding)
                .padding(.leading, UX.sectionHeaderLeadingPadding)
                .lineLimit(nil)
            
            LazyVGrid(columns: gridColumns, spacing: UX.gridRowSpacing) {
                ForEach(region.countries) { country in
                    countryTile(country)
                }
            }
            .padding(UX.sectionInnerPadding)
            .background(
                RoundedRectangle(cornerRadius: UX.sectionCornerRadius, style: .continuous)
                    .fill(Color(theme.colors.layer1))
            )
        }
    }

    // MARK: - Country Tile

    private func countryTile(_ country: WorldCupCountry) -> some View {
        let shadow = FxShadow.shadow200
        return VStack(spacing: UX.flagToLabelSpacing) {
            Image(country.id.lowercased())
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: UX.flagSize.width, height: UX.flagSize.height)
                .shadow(
                    color: shadow.colorProvider(theme).color,
                    radius: shadow.blurRadius,
                    x: shadow.offset.width,
                    y: shadow.offset.height
                )
                .accessibilityHidden(true)

            Text(country.name)
                .font(FXFontStyles.Bold.caption1.scaledSwiftUIFont())
                .foregroundColor(Color(theme.colors.textPrimary))
                .lineLimit(nil)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}
