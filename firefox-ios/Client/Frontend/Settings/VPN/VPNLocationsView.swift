// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SwiftUI

struct VPNLocationsView: ThemeableView {
    private struct UX {
        static let outerPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 16
        static let rowTextSpacing: CGFloat = 4
        static let loadingSpacing: CGFloat = 8
        static let simulatedLoadingNanoseconds: UInt64 = 2_000_000_000
        static let sampleRegionCodes = ["CA", "DE", "FR", "GB", "JP", "NL", "SE", "US"]
    }

    @State var theme: Theme
    @State private var regionCodes: [String] = []
    @State private var isLoadingLocations = true
    @State private var selectedRegionCode: String
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    let onLocationSelected: (String) -> Void
    private let localeProvider: LocaleProvider

    init(
        windowUUID: WindowUUID,
        themeManager: ThemeManager,
        selectedRegionCode: String = VPNServerManager.recommendedCountryCode,
        localeProvider: LocaleProvider = SystemLocaleProvider(),
        onLocationSelected: @escaping (String) -> Void = { _ in }
    ) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self._selectedRegionCode = State(initialValue: selectedRegionCode)
        self.localeProvider = localeProvider
        self.onLocationSelected = onLocationSelected
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UX.sectionSpacing) {
                VPNHelpers.card(theme: theme) {
                    locationButton(
                        regionCode: VPNServerManager.recommendedCountryCode,
                        title: .VPN.LocationPicker.RecommendedMainText,
                        subtitle: String(format: .VPN.LocationPicker.RecommendedSubText, AppName.shortName.rawValue)
                    )
                    ForEach(regionCodes, id: \.self) { regionCode in
                        VPNHelpers.divider()
                        locationButton(regionCode: regionCode, title: localeProvider.localizedRegionName(for: regionCode))
                    }
                }
                if isLoadingLocations {
                    loadingIndicator
                }
            }
            .padding(UX.outerPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.layer1.color)
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
        .task { await loadLocations() }
    }

    // MARK: - Rows

    private func locationButton(regionCode: String, title: String, subtitle: String? = nil) -> some View {
        let isSelected = selectedRegionCode == regionCode
        let a11yIdentifier = regionCode == VPNServerManager.recommendedCountryCode
            ? AccessibilityIdentifiers.Settings.VPN.Locations.recommendedLocation
            : "\(AccessibilityIdentifiers.Settings.VPN.Locations.location).\(regionCode)"
        return Button {
            selectLocation(regionCode)
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: UX.rowTextSpacing) {
                    Text(title)
                        .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                        .foregroundStyle(theme.colors.textPrimary.color)
                    if let subtitle {
                        Text(subtitle)
                            .font(FXFontStyles.Regular.caption1.scaledSwiftUIFont())
                            .foregroundStyle(theme.colors.textSecondary.color)
                    }
                }
                Spacer()
                Image(StandardImageIdentifiers.Large.checkmark)
                    .renderingMode(.template)
                    .foregroundStyle(theme.colors.iconAccent.color)
                    .opacity(isSelected ? 1 : 0)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
            .padding(.vertical, VPNHelpers.UX.rowVerticalPadding)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(a11yIdentifier)
    }

    private var loadingIndicator: some View {
        HStack(spacing: UX.loadingSpacing) {
            ProgressView()
                .accessibilityHidden(true)
            Text(String.VPN.LocationPicker.FindingLocationsText)
                .font(FXFontStyles.Regular.body.scaledSwiftUIFont())
                .foregroundStyle(theme.colors.textSecondary.color)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
        .padding(.vertical, VPNHelpers.UX.rowVerticalPadding)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.Locations.loadingIndicator)
    }

    // MARK: - Actions

    private func selectLocation(_ regionCode: String) {
        guard regionCode != selectedRegionCode else { return }
        selectedRegionCode = regionCode
        onLocationSelected(regionCode)
    }

    // TODO: Replace the simulated delay and sample list with `VPNServerManager.listCountries()`
    private func loadLocations() async {
        guard isLoadingLocations else { return }
        do {
            try await Task.sleep(nanoseconds: UX.simulatedLoadingNanoseconds)
        } catch {
            return
        }
        withAnimation {
            regionCodes = UX.sampleRegionCodes.sorted {
                localeProvider.localizedRegionName(for: $0)
                    .localizedCompare(localeProvider.localizedRegionName(for: $1)) == .orderedAscending
            }
            isLoadingLocations = false
        }
    }
}
