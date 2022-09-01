// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

protocol WallpaperManagerInterface {
    var currentWallpaper: Wallpaper? { get }
    var availableCollections: [WallpaperCollection] { get }
    var canOnboardingBeShown: Bool { get }

    func setCurrentWallpaper(to wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void)
    func fetch(_ wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void)
    func removeDownloadedAssets()
    func checkForUpdates()
}

/// The primary interface for the wallpaper feature.
class WallpaperManager: WallpaperManagerInterface, FeatureFlaggable, Loggable {

    // MARK: - Properties
    private var networkingModule: WallpaperNetworking

    // MARK: - Initializers
    init(with networkingModule: WallpaperNetworking = WallpaperNetworkingModule()) {
        self.networkingModule = networkingModule
    }

    // MARK: Public Interface

    /// Returns the currently selected wallpaper.
    public var currentWallpaper: Wallpaper? {
        do {
            let storageUtility = WallpaperStorageUtility()
            return try storageUtility.fetchCurrentWallpaper()
        } catch {
            browserLog.error("WallpaperManager error: \(error.localizedDescription)")
            return nil
        }
    }

    /// Returns all available collections and their wallpaper data. Availability is
    /// determined on locale and date ranges from the collection's metadata.
    public var availableCollections: [WallpaperCollection] {
        return getAvailableCollections()
    }

    /// Determines whether the wallpaper onboarding can be shown
    var canOnboardingBeShown: Bool {
        let thumbnailVerifier = WallpaperThumbnailVerifier()

        guard let wallpaperVersion: WallpaperVersion = featureFlags.getCustomState(for: .wallpaperVersion),
              wallpaperVersion == .v2,
              featureFlags.isFeatureEnabled(.wallpaperOnboardingSheet, checking: .buildOnly),
              thumbnailVerifier.thumbnailsAvailable
        else { return false }

        return true
    }

    /// Sets and saves a selected wallpaper as currently selected wallpaper.
    ///
    /// - Parameter wallpaper: A `Wallpaper` the user has selected.
    public func setCurrentWallpaper(
        to wallpaper: Wallpaper,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        completion(.success(()))
    }

    /// Fetches the images for a specific wallpaper.
    ///
    /// - Parameter wallpaper: A `Wallpaper` for which images should be downloaded.
    /// - Parameter completion: The block that is called when the image download completes.
    ///                      If the images is loaded successfully, the block is called with
    ///                      a `.success` with the data associated. Otherwise, it is called
    ///                      with a `.failure` and passed an error.
    func fetch(_ wallpaper: Wallpaper, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 0.1) {
            completion(.success(()))
        }
    }

    public func removeDownloadedAssets() {

    }

    /// Reaches out to the server and fetches the latest metadata. This is then compared
    /// to existing metadata, and, if there are changes, performs the necessary operations
    /// to ensure parity between server data and what the user sees locally.
    public func checkForUpdates() {
        let thumbnailVerifier = WallpaperThumbnailVerifier()
        let metadataUtility = WallpaperMetadataUtility(with: networkingModule)

        Task {
            let didFetchNewData = await metadataUtility.metadataUpdateFetchedNewData()
            if didFetchNewData {
                do {
                    try await fetchMissingThumbnails()
                    thumbnailVerifier.verifyThumbnailsFor(availableCollections)
                } catch {
                    browserLog.error("Wallpaper update check error: \(error.localizedDescription)")
                }
            } else {
                thumbnailVerifier.verifyThumbnailsFor(availableCollections)
            }
        }
    }

    // MARK: - Helper functions
    private func getAvailableCollections() -> [WallpaperCollection] {
        let metadata = getMetadata()
        let collections = metadata.collections.filter {
            let isDateAvailable = $0.availability?.isAvailable ?? true
            var isLocaleAvailable: Bool = false

            if let availableLocales = $0.availableLocales {
                isLocaleAvailable = availableLocales.isEmpty || availableLocales.contains(Locale.current.identifier)
            } else {
                isLocaleAvailable = true
            }

            return isDateAvailable && isLocaleAvailable
        }

        return collections
    }

    private func addDefaultWallpaper(to availableCollections: [WallpaperCollection]) -> [WallpaperCollection] {
        guard let classicCollection = availableCollections.first(where: { $0.type == .classic }) else { return availableCollections }

        let defaultWallpaper = [Wallpaper(id: "fxDefault",
                                          textColour: nil,
                                          cardColour: nil)]
        let newWallpapers = defaultWallpaper + classicCollection.wallpapers
        let newClassic = WallpaperCollection(id: classicCollection.id,
                                             learnMoreURL: classicCollection.learnMoreUrl?.absoluteString,
                                             availableLocales: classicCollection.availableLocales,
                                             availability: classicCollection.availability,
                                             wallpapers: newWallpapers,
                                             description: classicCollection.description,
                                             heading: classicCollection.heading)

        return [newClassic] + availableCollections.filter { $0.type != .classic }
    }

    private func getMetadata() -> WallpaperMetadata {
        let metadataUtility = WallpaperMetadataUtility(with: networkingModule)
        do {
            guard let metadata = try metadataUtility.getMetadata() else {
                fatalError()
            }

            return metadata
        } catch {
            print(error.localizedDescription)
            fatalError()
        }
    }

    private func fetchMissingThumbnails() async throws {
        let thumbnailVerifier = WallpaperThumbnailVerifier()
        let dataService = WallpaperDataService(with: networkingModule)
        let storageUtility = WallpaperStorageUtility()

        let missingThumbnails = thumbnailVerifier.getListOfMissingTumbnails(from: availableCollections)
        if !missingThumbnails.isEmpty {
            for (key, fileName) in missingThumbnails {
                let thumbnail = try await dataService.getImageWith(key: key, imageName: fileName)
                try storageUtility.store(thumbnail, withName: fileName, andKey: key)
            }
        }
    }
}
