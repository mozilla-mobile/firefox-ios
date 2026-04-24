// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

struct WorldCupCountryPickerView: View, ThemeableView {
    private struct UX {
        // Header
        static let headerHeight: CGFloat = 56
        static let headerHorizontalPadding: CGFloat = 16
        static let titleFontSize: CGFloat = 17
        static let closeButtonSize: CGFloat = 30
        static let closeIconSize: CGFloat = 16
        static let doneButtonFontSize: CGFloat = 15
        static let doneButtonVerticalPadding: CGFloat = 8
        static let doneButtonHorizontalPadding: CGFloat = 16
        static let doneButtonCornerRadius: CGFloat = 18

        // Content
        static let contentHorizontalPadding: CGFloat = 22
        static let contentBottomPadding: CGFloat = 24

        // Sections
        static let sectionSpacing: CGFloat = 16
        static let sectionCornerRadius: CGFloat = 12
        static let sectionInnerPadding: CGFloat = 12
        static let sectionHeaderFontSize: CGFloat = 13
        static let sectionHeaderBottomPadding: CGFloat = 8

        // Grid
        static let gridColumns = 4
        static let gridSpacing: CGFloat = 6
    }

    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    @State var theme: Theme

    @State private var selectedCountryIDs: Set<String> = []

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
        VStack(spacing: 0) {
            headerBar
            ScrollView {
                VStack(alignment: .leading, spacing: UX.sectionSpacing) {
                    ForEach(regions) { region in
                        regionSection(region)
                    }
                }
                .padding(.horizontal, UX.contentHorizontalPadding)
                .padding(.bottom, UX.contentBottomPadding)
            }
        }
        .background(Color(theme.colors.layer1))
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            closeButton

            Spacer()

            Text(String.WorldCup.CountryPicker.Title)
                .font(FXFontStyles.Bold.headline.systemSwiftUIFont())
                .foregroundColor(Color(theme.colors.textPrimary))

            Spacer()

            doneButton
        }
        .padding(.horizontal, UX.headerHorizontalPadding)
        .frame(height: UX.headerHeight)
    }

    private var closeButton: some View {
        Button(action: {}) {
            Image(systemName: "xmark")
                .font(.system(size: UX.closeIconSize, weight: .medium))
                .foregroundColor(Color(theme.colors.iconSecondary))
        }
        .frame(width: UX.closeButtonSize, height: UX.closeButtonSize)
        .background(Color(theme.colors.layer2))
        .clipShape(Circle())
        .accessibilityLabel(String.WorldCup.CountryPicker.CloseButtonAccessibilityLabel)
    }

    private var doneButton: some View {
        Button(action: {}) {
            Text(String.WorldCup.CountryPicker.DoneButtonTitle)
                .font(.system(size: UX.doneButtonFontSize, weight: .semibold))
                .foregroundColor(Color(theme.colors.textInverted))
                .padding(.vertical, UX.doneButtonVerticalPadding)
                .padding(.horizontal, UX.doneButtonHorizontalPadding)
                .background(Color(theme.colors.actionPrimary))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Region Section

    private func regionSection(_ region: WorldCupRegion) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(region.name)
                .font(.system(size: UX.sectionHeaderFontSize, weight: .bold))
                .foregroundColor(Color(theme.colors.textPrimary))
                .padding(.bottom, UX.sectionHeaderBottomPadding)

            LazyVGrid(columns: gridColumns, spacing: UX.gridSpacing) {
                ForEach(region.countries) { country in
                    WorldCupCountryTileView(
                        country: country,
                        isSelected: selectedCountryIDs.contains(country.id),
                        theme: theme
                    )
                    .onTapGesture {
                        toggleSelection(country.id)
                    }
                }
            }
            .padding(UX.sectionInnerPadding)
            .background(
                RoundedRectangle(cornerRadius: UX.sectionCornerRadius, style: .continuous)
                    .fill(Color(theme.colors.layer5))
            )
        }
    }

    // MARK: - Helpers

    private func toggleSelection(_ countryID: String) {
        if selectedCountryIDs.contains(countryID) {
            selectedCountryIDs.remove(countryID)
        } else {
            selectedCountryIDs.insert(countryID)
        }
    }
}
