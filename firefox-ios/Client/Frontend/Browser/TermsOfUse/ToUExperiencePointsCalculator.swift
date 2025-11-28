// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared

// Calculates ToU experience points (0-2) based on privacy settings
// Used for Nimbus targeting: +1 for ETP Strict, +1 for disabling sponsored content
struct ToUExperiencePointsCalculator {
    private let userDefaults: UserDefaultsInterface
    private let region: String?

    // Countries that support sponsored content (determined by geolocation)
    // Source: https://mozilla-hub.atlassian.net/browse/FXIOS-13934
    private static let sponsoredContentSupportedCountries: Set<String> = [
        "AT", "BE", "BG", "CA", "CH", "CY", "CZ", "DE", "DK", "EE",
        "ES", "FI", "FR", "GB", "GR", "HR", "HU", "IE", "IS", "JP",
        "LT", "LV", "MT", "NL", "NO", "NZ", "PL", "PT", "RO", "SE",
        "SG", "SK", "US"
    ]

    init(userDefaults: UserDefaultsInterface, region: String?) {
        self.userDefaults = userDefaults
        self.region = region
    }

    func calculatePoints() -> Int32 {
        var points: Int32 = 0
        if hasEnabledStrictTracking() {
            points += 1
        }
        if hasDisabledSponsoredContent() {
            points += 1
        }
        return points
    }

    private func hasEnabledStrictTracking() -> Bool {
        let enabledKey = ProfilePrefsReader.prefix + ContentBlockingConfig.Prefs.EnabledKey
        let strengthKey = ProfilePrefsReader.prefix + ContentBlockingConfig.Prefs.StrengthKey

        if let storedEnabledKey = userDefaults.object(forKey: enabledKey) as? Bool,
           storedEnabledKey == false {
            // Checking if the EnabledKey is false,
            // meaning that user explicitly disabled tracking protection
            return false
        }
        return userDefaults.string(forKey: strengthKey) == BlockingStrength.strict.rawValue
    }

    private func hasDisabledSponsoredContent() -> Bool {
        // Only award points in countries where sponsored content is available
        guard let region = region,
              Self.sponsoredContentSupportedCountries.contains(region) else {
            return false
        }

        let allShortcutsKey = ProfilePrefsReader.prefix + PrefsKeys.UserFeatureFlagPrefs.TopSiteSection
        let sponsoredKey = ProfilePrefsReader.prefix + PrefsKeys.FeatureFlags.SponsoredShortcuts

        let allShortcutsEnabled = userDefaults.object(forKey: allShortcutsKey) as? Bool ?? true
        let sponsoredEnabled = userDefaults.object(forKey: sponsoredKey) as? Bool ?? true

        // Award point if user disabled sponsored shortcuts specifically
        // OR if they disabled all shortcuts
        return !sponsoredEnabled || !allShortcutsEnabled
    }
}
