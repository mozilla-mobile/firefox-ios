// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

struct WallpaperMigrationUtility: Loggable {

    private let migrationKey = PrefsKeys.Wallpapers.v1MigrationCheck
    private let userDefaults: UserDefaultsInterface
    private let oldPromotionID = "trPromotion"

    // For ease of legibility, we're performing an inverse check here. If a migration
    // has already been performed, then we should not perform it again.
    private var shouldPerformMigration: Bool {
        return !userDefaults.bool(forKey: migrationKey)
    }

    init(with userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    func attemptMigration() {
        guard shouldPerformMigration else { return }
        let legacyStorageUtility = LegacyWallpaperStorageUtility()
        let storageUtility = WallpaperStorageUtility()

        do {
            // If no legacy wallpaper exists, then don't worry about migration
            guard let legacyWallpaperObject = legacyStorageUtility.getCurrentWallpaperObject(),
                  let legacyImagePortrait = legacyStorageUtility.getPortraitImage(),
                  let legacyImageLandscape = legacyStorageUtility.getLandscapeImage(),
                  let matchingID = getMatchingIdBasedOn(legacyId: legacyWallpaperObject.name),
                  let matchingWallpaper = try getMatchingWallpaperUsing(matchingID, from: storageUtility)
            else {
                markMigrationComplete()
                return
            }

            try storageUtility.store(legacyImagePortrait,
                                     withName: matchingWallpaper.portraitID,
                                     andKey: matchingWallpaper.id)
            try storageUtility.store(legacyImageLandscape,
                                     withName: matchingWallpaper.landscapeID,
                                     andKey: matchingWallpaper.id)
            try storageUtility.store(matchingWallpaper)

            markMigrationComplete()

        } catch {
            browserLog.error("Migration error: \(error.localizedDescription)")
        }
    }

    // MARK: - Private helpers
    private func getMatchingIdBasedOn(legacyId: String) -> String? {
        return [
            "fxAmethyst": "amethyst",
            "fxCerulean": "cerulean",
            "fxSunrise": "sunrise",
            "beachVibes": "beach-vibes",
            "twilingHills": "twilight-hills",
            "trRed": oldPromotionID,
            "trGroup": oldPromotionID
        ][legacyId]
    }

    private func getMatchingWallpaperUsing(
        _ matchingID: String,
        from storageUtility: WallpaperStorageUtility
    ) throws -> Wallpaper? {

        if matchingID == oldPromotionID {
            // The new metadata doesn't include the old promotional wallpapers.
            // Thus, we must create a new wallpaper to continue storing
            return Wallpaper(id: matchingID, textColor: nil, cardColor: nil)

        } else {
            guard let metadata = try storageUtility.fetchMetadata(),
                  let matchingWallpaper = metadata.collections
                .first(where: { $0.type == .classic })?
                .wallpapers.first(where: { $0.id ==  matchingID })
            else { return nil }

            return matchingWallpaper
        }

    }

    private func markMigrationComplete() {
        userDefaults.set(true, forKey: migrationKey)
    }
}
