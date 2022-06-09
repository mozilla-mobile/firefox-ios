// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCGLogger

class WallpaperStorageUtility: WallpaperFilePathProtocol, Loggable {

    // MARK: - Variables
    private var userDefaults: UserDefaults
    static let directoryName = "wallpapers"

    // MARK: - Initializer
    init(with userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Storage
    public func store(_ wallpaper: Wallpaper, and resources: WallpaperImageSet) {
        store(imageSet: resources) { result in
            switch result {
            case .success:
                self.store(wallpaperObject: wallpaper)
                NotificationCenter.default.post(name: .WallpaperDidChange, object: nil)
            case .failure(let error):
                self.browserLog.error("There was an error storing the wallpaper: \(error.localizedDescription)")
            }
        }
    }

    private func store(wallpaperObject: Wallpaper) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(wallpaperObject) {
            userDefaults.set(encoded, forKey: PrefsKeys.WallpaperManagerCurrentWallpaperObject)
        }
    }

    private func store(imageSet: WallpaperImageSet,
                       completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        if let portrait = imageSet.portrait, let landscape = imageSet.landscape {

            do {
                try store(image: portrait,
                          forKey: PrefsKeys.WallpaperManagerCurrentWallpaperImage)
                try store(image: landscape,
                          forKey: PrefsKeys.WallpaperManagerCurrentWallpaperImageLandscape)

                completionHandler(.success(()))

            } catch let error {
                completionHandler(.failure(error))
            }

        } else {
            guard let portraitPath = filePath(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperImage),
                  let landscapePath = filePath(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperImageLandscape)
            else { return }

            // If we're passing in `nil` for the image, we need to remove the currently
            // stored image so that it's not showing up.
            do {
                try FileManager.default.removeItem(at: portraitPath)
                try FileManager.default.removeItem(at: landscapePath)
                completionHandler(.success(()))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    /// Stores an image on disk as a png data representation, for the given key.
    /// The key should be the image's name unless saving a user seleceted
    /// wallpaper, in which case, the key should be the appropriate PrefsKey.
    ///
    /// The function throws if there is an error saving the image.
    ///
    /// - Parameters:
    ///   - image: The image to be saved
    ///   - key: The image's key identifier, usually it's name
    func store(image: UIImage, forKey key: String) throws {
        guard let pngRepresentation = image.pngData(),
              let saveFilePath = filePath(forKey: key)
        else { return }

        do {
            if FileManager.default.fileExists(atPath: saveFilePath.path) {
                try FileManager.default.removeItem(at: saveFilePath)
            }

            try pngRepresentation.write(to: saveFilePath, options: .atomic)

        } catch let error {
            browserLog.debug("Wallpaper - error writing file to disk: \(error)")
            throw error
        }
    }

    // MARK: - Wallpaper retrieval
    func getCurrentWallpaperObject() -> Wallpaper? {
        if let savedWallpaper = userDefaults.object(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperObject) as? Data {
            return try? JSONDecoder().decode(Wallpaper.self, from: savedWallpaper)
        }

        return nil
    }

    func getCurrentWallpaperImage() -> UIImage? {
        let key = UIDevice.current.orientation.isLandscape ? PrefsKeys.WallpaperManagerCurrentWallpaperImageLandscape : PrefsKeys.WallpaperManagerCurrentWallpaperImage
        return getImageResource(for: key)
    }

    func getImageResource(for key: String) -> UIImage? {
        guard let filePath = filePath(forKey: key),
           let fileData = FileManager.default.contents(atPath: filePath.path),
           let image = UIImage(data: fileData)
        else { return nil }

        return image
    }

    // MARK: - Deletion
    func deleteImageResource(named key: String) {
        let fileManager = FileManager.default
        guard let keyDirectoryPath = folderPath(forKey: key) else { return }
        do {
            try fileManager.removeItem(at: keyDirectoryPath)
        } catch {
            browserLog.debug("WallpaperStorageUtility - error deleting folder for \(key)")
        }
    }

    // MARK: - Migration
    func migrateResources(completion: (Bool) -> Void) {
        let fileManager = FileManager.default
        guard let documentPath = fileManager.urls(for: .documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first,
              let appSupportPath = fileManager.urls(for: .applicationSupportDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first
        else {
            browserLog.debug("Wallpaper migration error: could not fetch paths")
            return
        }

        let wallpaperDocumentDirectoryPath = documentPath.appendingPathComponent(WallpaperStorageUtility.directoryName)
        let wallpaperAppSupportDirectoryPath = appSupportPath.appendingPathComponent(WallpaperStorageUtility.directoryName)

        if shouldSkipMigration(
            source: wallpaperDocumentDirectoryPath,
            destination: wallpaperAppSupportDirectoryPath,
            with: fileManager,
            completion: { result in
            completion(result)
        }) { return }

        do {
            try fileManager.moveItem(at: wallpaperDocumentDirectoryPath,
                             to: wallpaperAppSupportDirectoryPath)
            completion(true)

        } catch {
            manualMigration(from: wallpaperDocumentDirectoryPath,
                            to: wallpaperAppSupportDirectoryPath,
                            with: fileManager) { result in
                completion(result)
            }
        }
    }

    private func shouldSkipMigration(
        source: URL,
        destination: URL,
        with fileManager: FileManager,
        completion: (Bool) -> Void
    ) -> Bool {
        var skipMigration = false

        if folderExists(at: destination) {
            completion(true)
            skipMigration = true
        }

        if !folderExists(at: source) {
            completion(true)
            skipMigration = true
        }

        if folderExists(at: source) && folderExists(at: destination) {
            try? fileManager.removeItem(at: source)
        }

        return skipMigration
    }

    private func folderExists(at directory: URL) -> Bool {

        let fileManager = FileManager.default

        // Check if the folder exists in the first place. If not, it would indicate that
        // this is probably a first time user (a user that has already migrated would
        // not get here) and so we don't need to do any sort of migration. Thus we
        // set that pref flag to `true`, as if a migration has taken place.
        var isDirectory: ObjCBool = true
        return fileManager.fileExists(atPath: directory.path,
                                      isDirectory: &isDirectory)
    }

    private func manualMigration(from source: URL,
                                 to destination: URL,
                                 with fileManager: FileManager,
                                 completion: (Bool) -> Void
    ) {
        do {
            try fileManager.copyItem(at: source,
                                     to: destination)
            try fileManager.removeItem(at: source)
            completion(true)
        } catch {
            completion(false)
        }
    }
}
