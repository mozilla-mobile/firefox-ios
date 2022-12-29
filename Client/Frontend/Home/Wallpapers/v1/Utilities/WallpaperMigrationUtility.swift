// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Common

struct WallpaperMigrationUtility: Loggable {
    private let metadataMigration = PrefsKeys.Wallpapers.v1MigrationCheck
    private let legacyAssetMigration = PrefsKeys.Wallpapers.legacyAssetMigrationCheck
    private let userDefaults: UserDefaultsInterface
    private let oldPromotionID = "trPromotion"

    // For ease of legibility, we're performing an inverse check here. If a migration
    // has already been performed, then we should not perform it again.
    private var shouldPerformMetadataMigration: Bool {
        return !userDefaults.bool(forKey: metadataMigration)
    }

    // For ease of legibility, we're performing an inverse check here. If a migration
    // has already been performed, then we should not perform it again.
    private var shouldPerformLegacyAssetMigration: Bool {
        return !userDefaults.bool(forKey: legacyAssetMigration)
    }

    init(with userDefaults: UserDefaultsInterface = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    /// Performs a migration of existing assets without having to download
    /// any metadata.
    ///
    /// To perform proper migration, we require metadata. However, to preserve
    /// user experience, having shifted to the JSON based metadata, we must have
    /// some form of migration that doesn't depend on metadata, which we won't
    /// have available at startup. To do this, we shift any existing wallpapers
    /// using the identifier and assets to a place that the wallpaper system
    /// will be able to find/use, and then migrate the correct identifiers
    /// once the metadata has been downloaded.
    func migrateExistingAssetWithoutMetadata() {
        guard shouldPerformLegacyAssetMigration else { return }
        let legacyStorageUtility = LegacyWallpaperStorageUtility()
        let storageUtility = WallpaperStorageUtility()

        // If no legacy wallpaper exists, then don't worry about migration
        guard let legacyWallpaperObject = legacyStorageUtility.getCurrentWallpaperObject(),
              let legacyImagePortrait = legacyStorageUtility.getPortraitImage(),
              let legacyImageLandscape = legacyStorageUtility.getLandscapeImage()
        else {
            markLegacyAssetMigrationComplete()
            markMetadataMigrationComplete()
            return
        }

        // Create a temporary dummy wallpaper
        let wallpaper = Wallpaper(id: legacyWallpaperObject.name,
                                  textColor: nil,
                                  cardColor: nil,
                                  logoTextColor: nil)

        do {
            try store(portait: legacyImagePortrait,
                      landscape: legacyImageLandscape,
                      for: wallpaper,
                      with: storageUtility)

            markLegacyAssetMigrationComplete()
        } catch {
            browserLog.error("Migration error: \(error.localizedDescription)")
        }
    }

    func attemptMetadataMigration() {
        guard shouldPerformMetadataMigration else { return }
        let storageUtility = WallpaperStorageUtility()

        do {
            let currentWallpaper = storageUtility.fetchCurrentWallpaper()
            guard currentWallpaper.type != .defaultWallpaper,
                  let landscape = currentWallpaper.landscape,
                  let portrait = currentWallpaper.portrait,
                  let matchingID = getMatchingIdBasedOn(legacyId: currentWallpaper.id),
                  let matchingWallpaper = try getMatchingWallpaperUsing(matchingID, from: storageUtility)
            else {
                markMetadataMigrationComplete()
                return
            }

            try store(portait: portrait,
                      landscape: landscape,
                      for: matchingWallpaper,
                      with: storageUtility)

            markMetadataMigrationComplete()
        } catch {
            browserLog.error("Migration error: \(error.localizedDescription)")
        }
    }

    // MARK: - Private helpers
    private func store(
        portait: UIImage,
        landscape: UIImage,
        for wallpaper: Wallpaper,
        with storageUtility: WallpaperStorageUtility
    ) throws {
        try storageUtility.store(portait,
                                 withName: wallpaper.portraitID,
                                 andKey: wallpaper.id)
        try storageUtility.store(landscape,
                                 withName: wallpaper.landscapeID,
                                 andKey: wallpaper.id)
        try storageUtility.store(wallpaper)
    }

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
            return Wallpaper(id: matchingID,
                             textColor: UIColor(colorString: "FBFBFE"),
                             cardColor: nil,
                             logoTextColor: UIColor(colorString: "FBFBFE"))
        } else {
            guard let metadata = try storageUtility.fetchMetadata(),
                  let matchingWallpaper = metadata.collections
                .first(where: { $0.type == .classic })?
                .wallpapers.first(where: { $0.id ==  matchingID })
            else { return nil }

            return matchingWallpaper
        }
    }

    private func markMetadataMigrationComplete() {
        userDefaults.set(true, forKey: metadataMigration)
    }

    private func markLegacyAssetMigrationComplete() {
        userDefaults.set(true, forKey: metadataMigration)
    }
}
