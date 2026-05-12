// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Redux
import SwiftUI

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
        static let gridMinTileWidth: CGFloat = 70
        static let gridSpacing: CGFloat = 6
        static let gridRowSpacing: CGFloat = 16
        static let flagSize = CGSize(width: 60, height: 40)
        static let flagCornerRadius: CGFloat = 7
        static let flagToLabelSpacing: CGFloat = 10
        static let selectedBorderOutset: CGFloat = 2
        static let selectedBorderWidth: CGFloat = 2
        static let selectedBadgeSize: CGFloat = 20
        static let selectedBadgeBorderWidth: CGFloat = 2
        static let selectedBadgeOffset: CGFloat = 10
        static let selectedCheckmarkSize: CGFloat = 12
    }

    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    @State var theme: Theme
    @Environment(\.dismiss) private var dismissAction

    @State var selectedTeam: String?
    private let regions = WorldCupCountryData.regions
    private var gridColumns: [GridItem] {
        [GridItem(.adaptive(minimum: UX.gridMinTileWidth), spacing: UX.gridSpacing)]
    }

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        selectedTeam: String? = nil
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
        self._selectedTeam = State(initialValue: selectedTeam)
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
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismissAction()
                    }
                    label: {
                        Image(StandardImageIdentifiers.Large.cross)
                            .renderingMode(.template)
                    }
                    .foregroundStyle(theme.colors.iconPrimary.color)
                    .accessibilityLabel(Text(String.WorldCup.CountryPicker.CloseButtonAccessibilityLabel))
                }
            }
        }
        .navigationViewStyle(.stack)
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
        let isSelected = selectedTeam == country.id
        return Button {
            dispatchSelectTeam(country)
        } label: {
            VStack(spacing: UX.flagToLabelSpacing) {
                flagImage(for: country, shadow: shadow, isSelected: isSelected)

                Text(country.name)
                    .font(FXFontStyles.Bold.caption1.scaledSwiftUIFont())
                    .foregroundColor(Color(theme.colors.textPrimary))
                    .lineLimit(nil)
                    .multilineTextAlignment(.center)
            }
            .frame(maxHeight: .infinity, alignment: .top)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(country.name))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func flagImage(
        for country: WorldCupCountry,
        shadow: FxShadow,
        isSelected: Bool
    ) -> some View {
        Image(country.id.lowercased())
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: UX.flagSize.width, height: UX.flagSize.height)
            .clipShape(RoundedRectangle(cornerRadius: UX.flagCornerRadius, style: .continuous))
            .shadow(
                color: shadow.colorProvider(theme).color,
                radius: shadow.blurRadius,
                x: shadow.offset.width,
                y: shadow.offset.height
            )
            .accessibilityHidden(true)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: UX.flagCornerRadius, style: .continuous)
                        .inset(by: -UX.selectedBorderOutset)
                        .stroke(
                            theme.colors.borderAccent.color,
                            lineWidth: UX.selectedBorderWidth
                        )
                }
            }
            .overlay(alignment: .bottomTrailing) {
                if isSelected {
                    selectedBadge
                        .offset(x: UX.selectedBadgeOffset, y: UX.selectedBadgeOffset)
                }
            }
    }

    private var selectedBadge: some View {
        ZStack {
            Circle()
                .fill(theme.colors.iconAccent.color)
                .overlay(
                    Circle()
                        .stroke(theme.colors.layer5.color, lineWidth: UX.selectedBadgeBorderWidth)
                )

            Image(StandardImageIdentifiers.Large.checkmark)
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: UX.selectedCheckmarkSize, height: UX.selectedCheckmarkSize)
                .foregroundStyle(theme.colors.layer5.color)
        }
        .frame(width: UX.selectedBadgeSize, height: UX.selectedBadgeSize)
    }

    // MARK: - Action Dispatch

    private func dispatchSelectTeam(_ country: WorldCupCountry) {
        store.dispatch(
            WorldCupAction(
                windowUUID: windowUUID,
                actionType: WorldCupActionType.selectTeam,
                selectedCountryId: country.id
            )
        )
        dismissAction()
    }
}
