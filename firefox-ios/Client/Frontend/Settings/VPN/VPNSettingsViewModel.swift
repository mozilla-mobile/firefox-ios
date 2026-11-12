// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Observation
import Redux
import Shared

@available(iOS 17.0, *)
@MainActor
@Observable
final class VPNSettingsViewModel {
    @ObservationIgnored private let vpnManager: VPNRunnable
    @ObservationIgnored private let windowUUID: WindowUUID
    @ObservationIgnored private let localeProvider: LocaleProvider

    var isVPNEnabled: Bool { vpnManager.isRunning }
    var isVPNConnecting: Bool { vpnManager.isConnecting }
    var usedDataInGB: Double { vpnManager.usedDataInGB }
    var dataLimitInGB: Double { vpnManager.dataLimitInGB }
    var usageFraction: Double { vpnManager.usageFraction }
    var isLimitReached: Bool { vpnManager.isLimitReached }
    var selectedCountryCode: String { vpnManager.selectedCountryCode }
    var accessibilityValue: String {
        if isVPNConnecting { return .VPN.Settings.Connecting }
        return isVPNEnabled ? .VPN.Settings.StatusOn : .VPN.Settings.StatusOff
    }

    var locationName: String {
        selectedCountryCode == VPNServerManager.recommendedCountryCode
            ? .VPN.Settings.LocationRecommended
            : countryName(for: selectedCountryCode)
    }

    func countryName(for countryCode: String) -> String {
        localeProvider.localizedRegionName(for: countryCode)
    }

    func sortedByName(_ countryCodes: [String]) -> [String] {
        countryCodes.sorted {
            countryName(for: $0).localizedCompare(countryName(for: $1)) == .orderedAscending
        }
    }

    func loadCountryCodes() async -> [String] {
        let countryCodes = await vpnManager.listCountries().map(\.code)
        return sortedByName(countryCodes.filter { $0 != VPNServerManager.recommendedCountryCode })
    }

    init(
        vpnManager: VPNRunnable,
        windowUUID: WindowUUID,
        localeProvider: LocaleProvider = SystemLocaleProvider()
    ) {
        self.vpnManager = vpnManager
        self.windowUUID = windowUUID
        self.localeProvider = localeProvider
    }

    func selectLocation(_ countryCode: String) {
        store.dispatch(VPNModernAction.selectLocation(countryCode: countryCode), forWindowUUID: windowUUID)
    }

    func toggleVPN(_ isOn: Bool) {
        guard !isVPNConnecting else { return }
        store.dispatch(isOn ? VPNModernAction.start : VPNModernAction.stop, forWindowUUID: windowUUID)
    }
}
