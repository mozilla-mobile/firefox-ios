// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

// This enum was moved here from `FlaggableFeatureOptions` as it can be removed once
// the migration utility gets removed.
enum UserFeaturePreference: String, FlaggableFeatureOptions {
    case enabled
    case disabled
}

final class FeatureFlagUserPrefsMigrationUtility {

    // MARK: - Properties
    private var userDefaults: UserDefaults
    private var profile: Profile
    private let migrationKey = PrefsKeys.LegacyFeatureFlags.MigrationCheck

    // For ease of legibility, we're performing an inverse check here. If a migration
    // has already been performed, then we should not perform it again.
    private var shouldPerformMigration: Bool {
        guard let migrationPerformed = profile.prefs.boolForKey(migrationKey),
              migrationPerformed
        else { return true }

        return false
    }

    // MARK: - Initializers
    init(with profile: Profile, and userDefaults: UserDefaults = .standard) {
        self.profile = profile
        self.userDefaults = userDefaults
    }

    // MARK: - Methods
    public func attemptMigration() {
        guard shouldPerformMigration else { return }

        migratePreferences()
        markMigrationAsComplete()
    }

    private func migratePreferences() {
        let keys = buildKeyDictionary()

        keys.forEach { oldKey, newKey in
            let oldKey = oldKey + "UserPreferences"
            let newKey = newKey
            migrateExistingPreference(from: oldKey, to: newKey)
        }
    }

    private func buildKeyDictionary() -> [String: String] {
        typealias legacy = PrefsKeys.LegacyFeatureFlags
        typealias new = PrefsKeys.FeatureFlags

        return [legacy.ASPocketStories: new.ASPocketStories,
                legacy.CustomWallpaper: new.CustomWallpaper,
                legacy.HistoryHighlightsSection: new.HistoryHighlightsSection,
                legacy.HistoryGroups: new.HistoryGroups,
                legacy.InactiveTabs: new.InactiveTabs,
                legacy.JumpBackInSection: new.JumpBackInSection,
                legacy.PullToRefresh: new.PullToRefresh,
                legacy.RecentlySavedSection: new.RecentlySavedSection,
                legacy.SponsoredShortcuts: new.SponsoredShortcuts,
                legacy.StartAtHome: new.StartAtHome,
                legacy.TabTrayGroups: new.TabTrayGroups,
                legacy.TopSiteSection: new.TopSiteSection]
    }

    private func migrateExistingPreference(from oldKey: String, to newKey: String) {
        guard let existingPreference = profile.prefs.stringForKey(oldKey) else { return }

        if existingPreference == UserFeaturePreference.enabled.rawValue {
            profile.prefs.setBool(true, forKey: newKey)

        } else if existingPreference == UserFeaturePreference.disabled.rawValue {
            profile.prefs.setBool(false, forKey: newKey)

        } else if existingPreference == StartAtHomeSetting.afterFourHours.rawValue
                    || existingPreference == StartAtHomeSetting.always.rawValue
                    || existingPreference == StartAtHomeSetting.disabled.rawValue {
            profile.prefs.setString(existingPreference, forKey: newKey)
        }
    }

    private func markMigrationAsComplete() {
        profile.prefs.setBool(true, forKey: migrationKey)
    }
}
