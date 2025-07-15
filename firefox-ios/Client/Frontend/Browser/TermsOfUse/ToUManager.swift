// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

class ToUManager {

    static let shared = ToUManager()

    private var didShowInThisSession = false

    private let acceptedKey = "termsOfUseAcceptedVersion"
    private let dismissedKey = "termsOfUseDismissed"
    private let lastDismissedDateKey = "termsOfUseLastDismissedDate"

    let currentVersion = "2025-07-01"

    private init() {}

    var hasAcceptedCurrentVersion: Bool {
        let accepted = UserDefaults.standard.string(forKey: acceptedKey)
        return accepted == currentVersion
    }

    var wasDismissedWithoutAcceptance: Bool {
        UserDefaults.standard.bool(forKey: dismissedKey)
    }

    private var shouldShowAgainAfterDismiss: Bool {
        guard let lastDismissed = UserDefaults.standard.object(forKey: lastDismissedDateKey) as? Date else {
            return true
        }
        //TO DO: Change the time interval depending on product decision
        return Date().timeIntervalSince(lastDismissed) > 1 * 60 // 1 minute
    }

    func shouldShow() -> Bool {
        if didShowInThisSession {
            return false
        }
        if hasAcceptedCurrentVersion {
            return false
        }
        if wasDismissedWithoutAcceptance && !shouldShowAgainAfterDismiss {
            return false
        }
        return true
    }

    func markAccepted() {
        UserDefaults.standard.set(currentVersion, forKey: acceptedKey)
        UserDefaults.standard.removeObject(forKey: dismissedKey)
        UserDefaults.standard.removeObject(forKey: lastDismissedDateKey)
    }

    func markDismissed() {
        UserDefaults.standard.set(true, forKey: dismissedKey)
        UserDefaults.standard.set(Date(), forKey: lastDismissedDateKey)
    }

    func markShownInSession() {
        didShowInThisSession = true
    }

    func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: acceptedKey)
        UserDefaults.standard.removeObject(forKey: dismissedKey)
        UserDefaults.standard.removeObject(forKey: lastDismissedDateKey)
        didShowInThisSession = false
    }
}
