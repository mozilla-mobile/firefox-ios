// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

class ToUManager: FeatureFlaggable {

    static let shared = ToUManager()

    private let acceptedKey = "termsOfUseAccepted"
    private let dismissedKey = "termsOfUseDismissed"
    private let lastShownDateKey = "termsOfUseLastShownDate"

    private var didShowThisLaunch = false
    
    private var isToUFeatureEnabled: Bool {
            featureFlags.isFeatureEnabled(.touFeature, checking: .buildOnly)
        }

    /// Check if user has accepted
    var hasAccepted: Bool {
        UserDefaults.standard.bool(forKey: acceptedKey)
    }

    /// Check if user dismissed without accepting
    var wasDismissed: Bool {
        UserDefaults.standard.bool(forKey: dismissedKey)
    }

    /// Decide if bottom sheet should show
    func shouldShow() -> Bool {
        let now = Date()
        
        // 🚩 Check Nimbus feature flag first
                if !isToUFeatureEnabled {
                    return false
                }

        // If accepted, never show again
        if hasAccepted {
            return false
        }

        // If last shown over 3 days ago → show again
        if let lastShown = UserDefaults.standard.object(forKey: lastShownDateKey) as? Date {
            let daysSince = Calendar.current.dateComponents([.day], from: lastShown, to: now).day ?? 0
            if daysSince >= 3 {
                UserDefaults.standard.set(now, forKey: lastShownDateKey)
                return true
            }
        }

        // If already shown this launch → skip
        if didShowThisLaunch {
            return false
        }

        // First time this launch → show and record timestamp
        didShowThisLaunch = true
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
