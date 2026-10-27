// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

#if DEBUG || MOCKABLE_STORE
final class ResetInstallationHistorySetting: HiddenSetting {
    private let historyStore: InstallationHistoryStoring

    init(settings: SettingsTableViewController,
         historyStore: InstallationHistoryStoring = InstallationHistoryStore()) {
        self.historyStore = historyStore
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(string: "Reset installation history",
                                  attributes: [.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let message: String
        do {
            try historyStore.resetForTesting()
            message = "Installation history deleted. The processing flag and telemetry are unchanged."
        } catch {
            message = "Could not reset installation history: \(error.localizedDescription)"
        }
        let alert = UIAlertController(title: "Installation history", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        settings.present(alert, animated: true)
    }
}
#endif
