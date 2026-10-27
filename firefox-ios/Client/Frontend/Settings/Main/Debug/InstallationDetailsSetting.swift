// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Shared

#if DEBUG || MOCKABLE_STORE
final class InstallationDetailsSetting: HiddenSetting {
    private let historyStore: InstallationHistoryStoring
    private let acquisition: AppAcquisitionProviding
    private let installationPrefs: Prefs

    init(settings: SettingsTableViewController,
         historyStore: InstallationHistoryStoring = InstallationHistoryStore(),
         acquisition: AppAcquisitionProviding = StoreKitAppAcquisitionProvider(),
         installationPrefs: Prefs = NSUserDefaultsPrefs(prefix: "installationTelemetry", userDefaults: .standard)) {
        self.historyStore = historyStore
        self.acquisition = acquisition
        self.installationPrefs = installationPrefs
        super.init(settings: settings)
    }

    override var title: NSAttributedString? {
        guard let theme else { return nil }
        return NSAttributedString(string: "View installation details",
                                  attributes: [.foregroundColor: theme.colors.textPrimary])
    }

    override func onClick(_ navigationController: UINavigationController?) {
        let alert = UIAlertController(title: "Installation details", message: "Loading…", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        settings.present(alert, animated: true)
        Task { @MainActor [weak alert] in
            alert?.message = await details()
        }
    }

    func details() async -> String {
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

        switch await acquisition.fetch() {
        case .available(let info):
            sections.append("Current StoreKit response\nOriginal purchase date (UTC): " +
                            "\(info.originalPurchaseDate.toISO8601DateString())\nOriginal app version: \(info.originalAppVersion)")
        case .unavailable(let reason):
            let message: String
            switch reason {
            case .unsupportedOS: message = "Requires iOS 16 or later"
            case .unverified: message = "Unverified transaction"
            case .storeKitFailure: message = "StoreKit request failed"
            }
            sections.append("Current StoreKit response: Unavailable (\(message))")
        }
        return sections.joined(separator: "\n\n")
    }
}
#endif
