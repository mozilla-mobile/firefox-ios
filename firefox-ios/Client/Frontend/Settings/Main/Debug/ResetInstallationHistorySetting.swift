// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

#if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
final class ResetInstallationHistorySetting: HiddenSetting {
    enum Flow {
        case newInstallation
        case reinstall
    }

    private let historyStore: InstallationHistoryStoring
    private let installationPrefs: Prefs

    init(settings: SettingsTableViewController,
         historyStore: InstallationHistoryStoring = InstallationHistoryStore(),
         installationPrefs: Prefs = NSUserDefaultsPrefs(prefix: "installationTelemetry", userDefaults: .standard)) {
        self.historyStore = historyStore
        self.installationPrefs = installationPrefs
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(string: "Test installation flow",
                                  attributes: [.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(
            title: "Test installation flow",
            message: "New installation clears saved installation history. Reinstall keeps it and checks the next install." +
                "\n\nEnable Check for Reinstalls and technical data collection before testing.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "New installation", style: .destructive) { [weak self] _ in
            self?.settings.dismiss(animated: true) { self?.prepare(.newInstallation) }
        })
        alert.addAction(UIAlertAction(title: "Reinstall", style: .default) { [weak self] _ in
            self?.settings.dismiss(animated: true) { self?.prepare(.reinstall) }
        })
        alert.addAction(UIAlertAction(title: .CancelString, style: .cancel))
        present(alert)
    }

    func prepare(_ flow: Flow) {
        do {
            switch flow {
            case .newInstallation:
                try historyStore.resetForTesting()
            case .reinstall:
                guard case .valid = try historyStore.load() else {
                    showResult(title: "Installation history needed",
                               message: "Run the new installation flow first to create history, then test a reinstall.")
                    return
                }
            }
            installationPrefs.setBool(false, forKey: PrefsKeys.installationProcessedKey)
            showResult(title: flow == .newInstallation ? "New installation ready" : "Reinstall ready",
                       message: "Fully close and reopen Firefox to run the selected flow. " +
                           "Your account, onboarding and privacy settings are unchanged.")
        } catch {
            showResult(title: "Could not prepare installation flow", message: error.localizedDescription)
        }
    }

    private func showResult(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert)
    }

    private func present(_ alert: UIAlertController) {
        if let theme {
            alert.applyNovaActionTint(theme)
        }
        settings.present(alert, animated: true)
    }
}
#endif
