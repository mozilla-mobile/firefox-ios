// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

struct WallpaperMigrationUtility {
    private let metadataMigration = PrefsKeys.Wallpapers.v1MigrationCheck
    private let userDefaults: UserDefaultsInterface
    private let oldPromotionID = "trPromotion"
    private var logger: Logger

    // For ease of legibility, we're performing an inverse check here. If a migration
    // has already been performed, then we should not perform it again.
    private var shouldPerformMetadataMigration: Bool {
        return !userDefaults.bool(forKey: metadataMigration)
    }

    init(with userDefaults: UserDefaultsInterface = UserDefaults.standard,
         logger: Logger = DefaultLogger.shared) {
        self.userDefaults = userDefaults
        self.logger = logger
    }

    func attemptMetadataMigration() {
        guard shouldPerformMetadataMigration else { return }
        let storageUtility = WallpaperStorageUtility()

        do {
            let currentWallpaper = storageUtility.fetchCurrentWallpaper()
            guard currentWallpaper.type != .none,
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
            logger.log("Metadata migration error: \(error.localizedDescription)",
                       level: .warning,
                       category: .legacyHomepage)
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
}
