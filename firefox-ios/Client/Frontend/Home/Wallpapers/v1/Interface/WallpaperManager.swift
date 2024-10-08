// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import UIKit
import Shared

enum WallpaperManagerError: Error {
    case downloadFailed(Error)
    case other(Error)
}

protocol WallpaperManagerInterface {
    var currentWallpaper: Wallpaper { get }
    var availableCollections: [WallpaperCollection] { get }
    var canSettingsBeShown: Bool { get }

    func canOnboardingBeShown(using: Profile) -> Bool
    func setCurrentWallpaper(to wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void)
    func fetchAssetsFor(_ wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void)
    func removeUnusedAssets()
    func checkForUpdates()
}

/// The primary interface for the wallpaper feature.
class WallpaperManager: WallpaperManagerInterface, FeatureFlaggable {
    enum ThumbnailFilter {
        case none
        case thumbnailsAvailable
    }

    // MARK: - Properties
    private var networkingModule: WallpaperNetworking
    private var userDefaults: UserDefaultsInterface
    private var logger: Logger

    // MARK: - Initializers
    init(
        with networkingModule: WallpaperNetworking = WallpaperNetworkingModule(),
        userDefaults: UserDefaultsInterface = UserDefaults.standard,
        logger: Logger = DefaultLogger.shared
    ) {
        self.networkingModule = networkingModule
        self.userDefaults = userDefaults
        self.logger = logger
    }

    // MARK: Public Interface

    /// Returns the currently selected wallpaper.
    public var currentWallpaper: Wallpaper {
        let storageUtility = WallpaperStorageUtility()
        return storageUtility.fetchCurrentWallpaper()
    }

    /// Returns all available collections and their wallpaper data. Availability is
    /// determined on locale and date ranges from the collection's metadata.
    public var availableCollections: [WallpaperCollection] {
        return getAvailableCollections(filtering: .thumbnailsAvailable)
    }

    /// Determines whether the wallpaper onboarding can be shown
    /// Doesn't need overlayState to check for CFR because the state was previously check
    func canOnboardingBeShown(using profile: Profile) -> Bool {
        let cfrHintUtility = ContextualHintEligibilityUtility(with: profile, overlayState: nil)
        let toolbarCFRShown = !cfrHintUtility.canPresent(.toolbarLocation)
        let jumpBackInCFRShown = !cfrHintUtility.canPresent(.jumpBackIn)
        let cfrsHaveBeenShown = toolbarCFRShown && jumpBackInCFRShown

        guard cfrsHaveBeenShown,
              hasEnoughThumbnailsToShow,
              !userDefaults.bool(forKey: PrefsKeys.Wallpapers.OnboardingSeenKey)
        else { return false }

        return true
    }

    /// Determines whether the wallpaper settings can be shown
    var canSettingsBeShown: Bool {
        guard hasEnoughThumbnailsToShow else { return false }

        return true
    }

    /// Returns true if the metadata & thumbnails are available
    private var hasEnoughThumbnailsToShow: Bool {
        let thumbnailUtility = WallpaperThumbnailUtility(with: networkingModule)

        guard thumbnailUtility.areThumbnailsAvailable else { return false }

        return true
    }

    /// Sets and saves a selected wallpaper as currently selected wallpaper.
    ///
    /// - Parameter wallpaper: A `Wallpaper` the user has selected.
    public func setCurrentWallpaper(
        to wallpaper: Wallpaper,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        do {
            let storageUtility = WallpaperStorageUtility()
            try storageUtility.store(wallpaper)

            NotificationCenter.default.post(name: .WallpaperDidChange, object: nil)
            completion(.success(()))
        } catch {
            logger.log("Failed to set wallpaper: \(error.localizedDescription)",
                       level: .warning,
                       category: .legacyHomepage)
            completion(.failure(WallpaperManagerError.other(error)))
        }
    }

    /// Fetches the images for a specific wallpaper.
    ///
    /// - Parameter wallpaper: A `Wallpaper` for which images should be downloaded.
    /// - Parameter completion: The block that is called when the image download completes.
    ///                      If the images is loaded successfully, the block is called with
    ///                      a `.success` with the data associated. Otherwise, it is called
    ///                      with a `.failure` and passed an error.
    func fetchAssetsFor(
        _ wallpaper: Wallpaper,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let dataService = WallpaperDataService(with: networkingModule)
        let storageUtility = WallpaperStorageUtility()

        Task(priority: .userInitiated) {
            do {
                // Download both images at the same time for efficiency
                async let portraitFetchRequest = dataService.getImage(
                    named: wallpaper.portraitID,
                    withFolderName: wallpaper.id)
                async let landscapeFetchRequest = dataService.getImage(
                    named: wallpaper.landscapeID,
                    withFolderName: wallpaper.id)

                let (portrait, landscape) = await (try portraitFetchRequest,
                                                   try landscapeFetchRequest)

                try storageUtility.store(portrait, withName: wallpaper.portraitID, andKey: wallpaper.id)
                try storageUtility.store(landscape, withName: wallpaper.landscapeID, andKey: wallpaper.id)

                completion(.success(()))
            } catch {
                logger.log("Error fetching wallpaper resources: \(error.localizedDescription)",
                           level: .warning,
                           category: .legacyHomepage)
                completion(.failure(WallpaperManagerError.downloadFailed(error)))
            }
        }
    }

    public func removeUnusedAssets() {
        let storageUtility = WallpaperStorageUtility()
        try? storageUtility.cleanupUnusedAssets()
    }

    /// Reaches out to the server and fetches the latest metadata. This is then compared
    /// to existing metadata, and, if there are changes, performs the necessary operations
    /// to ensure parity between server data and what the user sees locally.
    public func checkForUpdates() {
        let thumbnailUtility = WallpaperThumbnailUtility(with: networkingModule)
        let metadataUtility = WallpaperMetadataUtility(with: networkingModule)

        Task {
            let didFetchNewData = await metadataUtility.metadataUpdateFetchedNewData()
            if didFetchNewData {
                let migrationUtility = WallpaperMigrationUtility()
                migrationUtility.attemptMetadataMigration()
            }

            // It is possible we haven't downloaded all thumbnails, and so
            // we'll attempt to download missing ones even if the metadata hasn't
            // actually changed
            await thumbnailUtility.fetchAndVerifyThumbnails(for: getAvailableCollections(filtering: .none))
        }
    }

    // MARK: - Helper functions
    private func getAvailableCollections(filtering filter: ThumbnailFilter) -> [WallpaperCollection] {
        guard let metadata = getMetadata() else { return addDefaultWallpaper(to: []) }

        var collections = metadata.collections.filter { $0.isAvailable }
        switch filter {
        case .none:
            collections = addDefaultWallpaper(to: collections)

        case .thumbnailsAvailable:
            let collectionWithThumbnails = filterUnavailableThumbnailsFrom(collections)
            collections = addDefaultWallpaper(to: collectionWithThumbnails)
        }

        collections = collections.filter { !$0.wallpapers.isEmpty }
        return collections
    }

    private func addDefaultWallpaper(to availableCollections: [WallpaperCollection]) -> [WallpaperCollection] {
        let defaultWallpaper = [Wallpaper(id: "fxDefault",
                                          textColor: nil,
                                          cardColor: nil,
                                          logoTextColor: nil)]

        if availableCollections.isEmpty {
            return [WallpaperCollection(id: "classic-firefox",
                                        learnMoreURL: nil,
                                        availableLocales: nil,
                                        availability: nil,
                                        wallpapers: defaultWallpaper,
                                        description: nil,
                                        heading: nil)]
        } else if let classicCollection = availableCollections.first(where: { $0.type == .classic }) {
            let newWallpapers = defaultWallpaper + classicCollection.wallpapers
            let newClassic = WallpaperCollection(id: classicCollection.id,
                                                 learnMoreURL: classicCollection.learnMoreUrl?.absoluteString,
                                                 availableLocales: classicCollection.availableLocales,
                                                 availability: classicCollection.availability,
                                                 wallpapers: newWallpapers,
                                                 description: classicCollection.description,
                                                 heading: classicCollection.heading)

            return [newClassic] + availableCollections.filter { $0.type != .classic }
        } else {
            return availableCollections
        }
    }

    private func getMetadata() -> WallpaperMetadata? {
        let metadataUtility = WallpaperMetadataUtility(with: networkingModule)
        do {
            guard let metadata = try metadataUtility.getMetadata() else { return nil }

            return metadata
        } catch {
            logger.log("Error getting stored metadata: \(error.localizedDescription)",
                       level: .warning,
                       category: .legacyHomepage)
            return nil
        }
    }

    private func filterUnavailableThumbnailsFrom(_ collections: [WallpaperCollection]) -> [WallpaperCollection] {
        return collections.map { collection in
            return WallpaperCollection(
                id: collection.id,
                learnMoreURL: collection.learnMoreUrl?.absoluteString,
                availableLocales: collection.availableLocales,
                availability: collection.availability,
                wallpapers: collection.wallpapers.filter { $0.thumbnail != nil },
                description: collection.description,
                heading: collection.heading)
        }
    }
}
