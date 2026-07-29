// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Starts and stops the VPN proxy at runtime, so the proxy code can be exercised without
/// shipping any user facing entry point for it yet.
class ToggleVPNProxySetting: HiddenSetting {
    private let vpnManager: VPNManaging
    private var isToggling = false

    override var accessibilityIdentifier: String? {
        return AccessibilityIdentifiers.Settings.Debug.toggleVPNProxy
    }

    init(settings: SettingsTableViewController, vpnManager: VPNManaging) {
        self.vpnManager = vpnManager
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(
            string: "Toggle VPN proxy",
            attributes: [NSAttributedString.Key.foregroundColor: theme.colors.textPrimary]
        )
    }

    override var status: NSAttributedString? {
        let state: String
        if isToggling {
            state = vpnManager.isRunning ? "Turning off…" : "Turning on…"
        } else {
            state = vpnManager.isRunning ? "On" : "Off"
        }
        return NSAttributedString(string: state)
    }

    override func onClick(_ navigationController: UINavigationController?) {
        guard !isToggling else { return }
        isToggling = true
        settings.tableView.reloadData()

        Task { @MainActor in
            if vpnManager.isRunning {
                await vpnManager.stop()
            } else {
                await vpnManager.start(privateOnly: false)
            }
            isToggling = false
            settings.tableView.reloadData()
        }
    }
}
