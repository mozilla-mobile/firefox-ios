// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Observation
import Shared
// import UIKit

@available(iOS 17.0, *)
@MainActor
@Observable
final class VPNSettingsViewModel {
    // TODO: FXIOS-16876 this won't be needed once backend vpn stuff is wired up
    private static let simulatedConnectingDuration: TimeInterval = 2

    private(set) var isVPNEnabled: Bool
    private(set) var isVPNConnecting = false
    private let dataUsage: VPNDataUsage

    @ObservationIgnored private let prefs: Prefs

    var usedDataInGB: Double { dataUsage.clampedUsedDataInGB }
    var dataLimitInGB: Double { dataUsage.dataLimitInGB }
    var usageFraction: Double { dataUsage.usageFraction }
    var isLimitReached: Bool { dataUsage.isLimitReached }

    init(prefs: Prefs, dataUsage: VPNDataUsage = .placeholder) {
        self.prefs = prefs
        self.isVPNEnabled = prefs.boolForKey(PrefsKeys.VPNSettings.isEnabled) ?? false
        self.dataUsage = dataUsage
    }

    // TODO: FXIOS-16876 Replace this with real VPN connection stuff
    func toggleVPN(_ isOn: Bool) {
        guard isOn else {
            isVPNEnabled = false
            prefs.setBool(false, forKey: PrefsKeys.VPNSettings.isEnabled)
            return
        }
        guard !isVPNConnecting else { return }

        isVPNConnecting = true
        DispatchQueue.main.asyncAfter(deadline: .now() + VPNSettingsViewModel.simulatedConnectingDuration) { [weak self] in
            guard let self else { return }
            isVPNConnecting = false
            isVPNEnabled = true
            prefs.setBool(true, forKey: PrefsKeys.VPNSettings.isEnabled)
            UIAccessibility.post(notification: .announcement, argument: String.VPN.Settings.Connected)
        }
    }
}
