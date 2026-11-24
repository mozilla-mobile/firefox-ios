// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

#if MOZ_CHANNEL_beta || MOZ_CHANNEL_developer
final class InstallationDetailsSetting: HiddenSetting {
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
        return NSAttributedString(string: "View installation details",
                                  attributes: [.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(title: "Installation details", message: details(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        settings.present(alert, animated: true)
    }

    func details() -> String {
        let processingState: String
        switch installationPrefs.boolForKey(PrefsKeys.installationProcessedKey) {
        case true: processingState = "Complete"
        case false: processingState = "Pending"
        case nil: processingState = "Not initialized"
        }
        var sections = ["Processing: \(processingState)"]

        do {
            switch try historyStore.load() {
            case .missing:
                sections.append("Retained history: Missing")
            case .corrupt:
                sections.append("Retained history: Corrupt")
            case .valid(let history):
                let date = ISO8601DateFormatter().string(from: history.lastSeenDate)
                sections.append("Retained history\nInstall count: \(history.installCounter)\nLast seen (UTC): \(date)")
            }
        } catch {
            sections.append("Retained history: Unavailable (\(error.localizedDescription))")
        }

        return sections.joined(separator: "\n\n")
    }
}
#endif
