// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI

struct WorldCupCountryPickerView: View, ThemeableView {
    private struct UX {
        static let horizontalPadding: CGFloat = 22
        static let sectionSpacing: CGFloat = 16
        static let gridSpacing: CGFloat = 6
        static let sectionCornerRadius: CGFloat = 12
        static let sectionInnerPadding: CGFloat = 12
        static let headerFontSize: CGFloat = 13
        static let columns = 4
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
        Array(repeating: GridItem(.flexible(), spacing: UX.gridSpacing), count: UX.columns)
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
                .padding(.horizontal, UX.horizontalPadding)
                .padding(.bottom, 24)
            }
        }
        .background(Color(theme.colors.layer1))
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
    }

    // MARK: - Header Bar

    private var headerBar: some View {
        HStack {
            Button(action: {}) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(theme.colors.textPrimary))
            }
            .frame(width: 44, height: 44)

            Spacer()

            Text("Follow Your Team")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color(theme.colors.textPrimary))

            Spacer()

            Button(action: {}) {
                Text("Done")
                    .font(.system(size: 17))
                    .foregroundColor(Color(theme.colors.textSecondary))
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 12)
        .frame(height: 56)
    }

    // MARK: - Region Section

    private func regionSection(_ region: WorldCupRegion) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(region.name)
                .font(.system(size: UX.headerFontSize, weight: .bold))
                .foregroundColor(Color(theme.colors.textPrimary))
                .padding(.bottom, 8)

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
