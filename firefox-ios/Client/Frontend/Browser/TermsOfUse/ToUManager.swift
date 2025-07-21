// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

class ToUManager: FeatureFlaggable {
    static let shared = ToUManager()

    private let acceptedKey = "termsOfUseAccepted"
    private let dismissedKey = "termsOfUseDismissed"
    private let lastShownDateKey = "termsOfUseLastShownDate"

    private var isToUFeatureEnabled: Bool {
        featureFlags.isFeatureEnabled(.touFeature, checking: .buildOnly)
    }
    
    var didShowThisLaunch = false

    var hasAccepted: Bool {
        UserDefaults.standard.bool(forKey: acceptedKey)
    }

    var wasDismissed: Bool {
        UserDefaults.standard.bool(forKey: dismissedKey)
    }

    func shouldShow() -> Bool {
        guard isToUFeatureEnabled else { return false }
        guard !hasAccepted else { return false }

        let now = Date()
        if let lastShown = UserDefaults.standard.object(forKey: lastShownDateKey) as? Date,
           Calendar.current.dateComponents([.day], from: lastShown, to: now).day ?? 0 >= 3 {
            UserDefaults.standard.set(now, forKey: lastShownDateKey)
            return true
        }

        if didShowThisLaunch { return false }

        UserDefaults.standard.set(now, forKey: lastShownDateKey)
        return true
    }

    func markAccepted() {
        UserDefaults.standard.set(true, forKey: acceptedKey)
        UserDefaults.standard.set(false, forKey: dismissedKey)
    }

    func markDismissed() {
        UserDefaults.standard.set(true, forKey: dismissedKey)
        UserDefaults.standard.set(Date(), forKey: lastShownDateKey)
    }

}
