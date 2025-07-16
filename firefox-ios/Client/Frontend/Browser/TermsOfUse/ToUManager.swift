// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

class ToUManager {

    static let shared = ToUManager()

    private let acceptedKey = "termsOfUseAcceptedVersion"
    private let dismissedKey = "termsOfUseDismissed"
    private let currentVersion = "2025-07-01"

    private var didShowThisLaunch = false

    private init() {}

    /// Check if user already accepted the latest ToU
    var hasAcceptedCurrentVersion: Bool {
        let accepted = UserDefaults.standard.string(forKey: acceptedKey)
        return accepted == currentVersion
    }

    /// Check if user dismissed without accepting
    var wasDismissed: Bool {
        UserDefaults.standard.bool(forKey: dismissedKey)
    }

    /// Decide if bottom sheet should show (only once per app launch)
    func shouldShow() -> Bool {
        if didShowThisLaunch {
            return false
        }
        if hasAcceptedCurrentVersion {
            return false
        }
        didShowThisLaunch = true // mark as shown for this launch
        return true
    }

    func markAccepted() {
        UserDefaults.standard.set(currentVersion, forKey: acceptedKey)
        UserDefaults.standard.set(false, forKey: dismissedKey)
    }

    func markDismissed() {
        UserDefaults.standard.set(true, forKey: dismissedKey)
    }

    func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: acceptedKey)
        UserDefaults.standard.removeObject(forKey: dismissedKey)
        didShowThisLaunch = false
    }
}
