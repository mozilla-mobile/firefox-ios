// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

/// Responsible for tracking whether or not the wallpaper system should perform
/// a variety of checks, such as whether it should fetch data from the server.
class WallpaperMetadataUtility {
    // MARK: - Properties
    /// Will return `true` under two conditions:
    /// 1. Has never performed a check
    /// 2. Has not performed a check on the current day
    private var shouldCheckForNewMetadata: Bool {
        guard let existingDate = userDefaults.object(forKey: prefsKey) as? Date else { return true }
        let todaysDate = Calendar.current.startOfDay(for: Date())

        if existingDate == todaysDate { return false }

        return true
    }

    private let prefsKey = PrefsKeys.Wallpapers.MetadataLastCheckedDate

    private let userDefaults: UserDefaultsInterface
    private let networkingModule: WallpaperNetworking
    private var logger: Logger

    // MARK: - Initializers
    init(
        with networkingModule: WallpaperNetworking,
        and userDefaults: UserDefaultsInterface = UserDefaults.standard,
        logger: Logger = DefaultLogger.shared
    ) {
        self.networkingModule = networkingModule
        self.userDefaults = userDefaults
        self.logger = logger
    }

    // MARK: - Public interface
    public func metadataUpdateFetchedNewData() async -> Bool {
        if !shouldCheckForNewMetadata { return false }

        do {
            let freshMetadata = try await attemptToFetchMetadata()
            // If new metadata is different from the old, it should take precedence
            if oldMetadataIsDifferentThanNew(freshMetadata) {
                try attemptToStore(freshMetadata)
                markLastUpdatedDate(with: Date())
                return true
            } else {
                markLastUpdatedDate(with: Date())
                return false
            }
        } catch {
            logger.log("Failed to fetch new metadata: \(error.localizedDescription)",
                       level: .warning,
                       category: .legacyHomepage)
            return false
        }
    }

    public func getMetadata() throws -> WallpaperMetadata? {
        let storageUtility = WallpaperStorageUtility()
        guard let metadata = try storageUtility.fetchMetadata() else { return nil }

        return metadata
    }

    // MARK: - Private methods
    private func attemptToFetchMetadata() async throws -> WallpaperMetadata {
        let dataService = WallpaperDataService(with: networkingModule)
        let metadata = try await dataService.getMetadata()

        return metadata
    }

    private func attemptToStore(_ metadata: WallpaperMetadata) throws {
        let storageUtility = WallpaperStorageUtility()
        try storageUtility.store(metadata)
    }

    private func markLastUpdatedDate(with date: Date) {
        let todaysDate = Calendar.current.startOfDay(for: date)
        userDefaults.set(todaysDate, forKey: prefsKey)
    }

    private func oldMetadataIsDifferentThanNew(_ metadata: WallpaperMetadata) -> Bool {
        do {
            let storageUtility = WallpaperStorageUtility()
            guard let oldMetadata = try storageUtility.fetchMetadata() else { return true }

            if oldMetadata.collections == metadata.collections { return false }

            return true
        } catch {
            logger.log("Failed to get old metadata: \(error.localizedDescription)",
                       level: .warning,
                       category: .legacyHomepage)
            return true
        }
    }
}
