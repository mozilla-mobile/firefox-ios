// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Observation
import Shared

@available(iOS 17.0, *)
@MainActor
@Observable
final class VPNSettingsViewModel {
    // TODO: FXIOS-16876 this won't be needed once backend vpn stuff is wired up
    private static let simulatedConnectingDuration: TimeInterval = 2

    private(set) var isVPNEnabled: Bool
    private(set) var isVPNConnecting = false
    private let dataUsage: VPNDataUsage

    @ObservationIgnored private let userPreferences: UserFeaturePreferring

    var usedDataInGB: Double { dataUsage.clampedUsedDataInGB }
    var dataLimitInGB: Double { dataUsage.dataLimitInGB }
    var usageFraction: Double { dataUsage.usageFraction }
    var isLimitReached: Bool { dataUsage.isLimitReached }
    var accessibilityValue: String {
        if isVPNConnecting { return .VPN.Settings.Connecting }
        return isVPNEnabled ? .VPN.Settings.StatusOn : .VPN.Settings.StatusOff
    }

    init(
        userPreferences: UserFeaturePreferring = AppContainer.shared.resolve(),
        dataUsage: VPNDataUsage = .placeholder
    ) {
        self.userPreferences = userPreferences
        self.isVPNEnabled = userPreferences.getPreferenceFor(.vpnFeature)
        self.dataUsage = dataUsage
    }

    // TODO: FXIOS-16876 Replace this with real VPN connection stuff
    func toggleVPN(_ isOn: Bool) {
        guard isOn else {
            isVPNEnabled = false
            userPreferences.setPreferenceFor(.vpnFeature, to: false)
            return
        }
        guard !isVPNConnecting else { return }

        isVPNConnecting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + VPNSettingsViewModel.simulatedConnectingDuration) { [weak self] in
            guard let self else { return }
            isVPNConnecting = false
            isVPNEnabled = true
            userPreferences.setPreferenceFor(.vpnFeature, to: true)
            UIAccessibility.post(notification: .announcement, argument: String.VPN.Settings.Connected)
        }
    }
}
