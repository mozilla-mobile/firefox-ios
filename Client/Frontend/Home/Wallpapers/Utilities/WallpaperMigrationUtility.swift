// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

class WallpaperMigrationUtility {

    private let migrationKey = PrefsKeys.LegacyFeatureFlags.WallpaperDirectoryMigrationCheck
    private let profile: Profile

    // For ease of legibility, we're performing an inverse check here. If a migration
    // has already been performed, then we should not perform it again.
    private var shouldPerformMigration: Bool {
        guard let migrationPerformed = profile.prefs.boolForKey(migrationKey),
              migrationPerformed
        else { return true }

        return false
    }

    init(with profile: Profile) {
        self.profile = profile
    }

    func attemptMigration() {
        guard shouldPerformMigration else { return }

        let storageUtility = WallpaperStorageUtility()
        storageUtility.migrateResources { result in
            self.profile.prefs.setBool(result, forKey: self.migrationKey)
        }
    }
}
