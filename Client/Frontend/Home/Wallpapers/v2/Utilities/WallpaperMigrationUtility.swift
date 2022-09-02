// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct WallpaperMigrationUtility: Loggable {

    private let migrationKey = PrefsKeys.Wallpapers.v1MigrationCheck
    private let userDefaults: UserDefaultsInterface

    // For ease of legibility, we're performing an inverse check here. If a migration
    // has already been performed, then we should not perform it again.
    private var shouldPerformMigration: Bool {
        guard userDefaults.bool(forKey: migrationKey) else { return true }

        return false
    }

    init(with userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    func attemptMigration() {
        guard shouldPerformMigration else { return }
        let legacyStorageUtility = LegacyWallpaperStorageUtility()
        let storageUtility = WallpaperStorageUtility()

        do {
            guard let legacyWallpaperObject = legacyStorageUtility.getCurrentWallpaperObject() else {
                userDefaults.set(true, forKey: migrationKey)
                return
            }

            guard let legacyImagePortrait = legacyStorageUtility.getPortraitImage(),
                  let legacyImageLandscape = legacyStorageUtility.getLandscapeImage(),
                  let metadata = try storageUtility.fetchMetadata(),
                  let matchingID = getMatchingIdBasedOn(legacyId: legacyWallpaperObject.name),
                  // TODO: [roux] - this will need to be in an EITH matich or disney
                  let matchingWallpaper = metadata.collections
                .first(where: { $0.type == .classic })?
                .wallpapers.first(where: { $0.id ==  matchingID })
            else { return }

            try storageUtility.store(legacyImagePortrait,
                                     withName: matchingWallpaper.portraitID,
                                     andKey: matchingWallpaper.id)
            try storageUtility.store(legacyImageLandscape,
                                     withName: matchingWallpaper.landscapeID,
                                     andKey: matchingWallpaper.id)
            try storageUtility.store(matchingWallpaper)

            userDefaults.set(true, forKey: migrationKey)

        } catch {
            browserLog.error("Migration error: \(error.localizedDescription)")
        }
    }

    // MARK: - Private helpers
    private func getMatchingIdBasedOn(legacyId: String) -> String? {
        let idMap = [
            "fxAmethyst": "amethyst",
            "fxCerulean": "cerulean",
            "fxSunrise": "sunrise",
            "beachVibes": "beach-vibes",
            "twilingHills": "twilight-hills"
            // TODO: [roux] - WHAT ABOUT DISNEY???????
        ]

        return idMap[legacyId]
    }
}
