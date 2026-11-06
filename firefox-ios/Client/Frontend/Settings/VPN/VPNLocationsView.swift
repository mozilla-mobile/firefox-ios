// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import SwiftUI

@available(iOS 17.0, *)
struct VPNLocationsView: ThemeableView {
    private enum UX {
        static let outerPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 16
        static let rowTextSpacing: CGFloat = 4
        // TODO: FXIOS-16876 Replace the simulated delay and sample list
        static let simulatedLoadingNanoseconds: UInt64 = 2_000_000_000
        static let sampleCountryCodes = ["CA", "DE", "FR", "GB", "JP", "NL", "SE", "US"]
    }

    @State var theme: Theme
    @State private var countryCodes: [String] = []
    @State private var isLoadingCountries = true
    let windowUUID: WindowUUID
    var themeManager: ThemeManager
    let viewModel: VPNSettingsViewModel

    init(windowUUID: WindowUUID, themeManager: ThemeManager, viewModel: VPNSettingsViewModel) {
        self.windowUUID = windowUUID
        self.themeManager = themeManager
        self.viewModel = viewModel
        self.theme = themeManager.getCurrentTheme(for: windowUUID)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UX.sectionSpacing) {
                VPNHelpers.card(theme: theme) {
                    locationButton(
                        countryCode: VPNServerManager.recommendedCountryCode,
                        title: .VPN.LocationPicker.RecommendedMainText,
                        subtitle: String(format: .VPN.LocationPicker.RecommendedSubText, AppName.shortName.rawValue)
                    )
                    ForEach(countryCodes, id: \.self) { countryCode in
                        VPNHelpers.divider()
                        locationButton(countryCode: countryCode, title: viewModel.countryName(for: countryCode))
                    }
                }
                if isLoadingCountries {
                    loadingIndicator
                }
            }
            .padding(UX.outerPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(theme.colors.layer1.color)
        .navigationTitle(String.VPN.Settings.LocationTitle)
        .listenToThemeChanges(theme: $theme, manager: themeManager, windowUUID: windowUUID)
        .task { await loadLocations() }
    }

    private var loadingIndicator: some View {
        VPNHelpers.loadingIndicator(text: .VPN.LocationPicker.FindingLocationsText, theme: theme)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, VPNHelpers.UX.horizontalPadding)
            .padding(.vertical, VPNHelpers.UX.rowVerticalPadding)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier(AccessibilityIdentifiers.Settings.VPN.Locations.loadingIndicator)
    }

    // MARK: - Rows

    private func locationButton(countryCode: String, title: String, subtitle: String? = nil) -> some View {
        let isSelected = viewModel.selectedCountryCode == countryCode
        let a11yIdentifier = countryCode == VPNServerManager.recommendedCountryCode
            ? AccessibilityIdentifiers.Settings.VPN.Locations.recommendedLocation
            : "\(AccessibilityIdentifiers.Settings.VPN.Locations.location).\(countryCode)"

        return Button {
            viewModel.selectLocation(countryCode)
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

    // MARK: - Actions

    private func loadLocations() async {
        guard isLoadingCountries else { return }
        do {
            try await Task.sleep(nanoseconds: UX.simulatedLoadingNanoseconds)
        } catch {
            return
        }
        withAnimation {
            countryCodes = viewModel.sortedByName(UX.sampleCountryCodes)
            isLoadingCountries = false
        }
    }
}
