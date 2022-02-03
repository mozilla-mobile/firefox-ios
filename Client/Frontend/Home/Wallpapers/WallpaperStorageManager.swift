// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import XCGLogger

private let log = Logger.browserLogger

class WallpaperStorageManager {

    // MARK: - Variables
    private var userDefaults: UserDefaults

    // MARK: - Initializer
    init(with userDefaults: UserDefaults = UserDefaults.standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Storage
    public func store(_ wallpaper: Wallpaper) {
        store(imageSet: wallpaper.image) { result in
            switch result {
            case .success(()):
                self.store(wallpaperObject: wallpaper)
                NotificationCenter.default.post(name: .WallpaperDidChange, object: nil)
            case .failure(let error):
                log.error("There was an error storing the wallpaper: \(error.localizedDescription)")
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
        guard let filePathPortrait = filePath(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperImage),
              let filePathLandscape = filePath(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperImageLandscape)
        else { return }

        if let portrait = imageSet.portrait,
           let landscape = imageSet.landscape,
           let portraitPngRepresentation = portrait.pngData(),
           let landscapePngRepresentation = landscape.pngData() {
            do {
                try portraitPngRepresentation.write(to: filePathPortrait, options: .atomic)
                try landscapePngRepresentation.write(to: filePathLandscape, options: .atomic)
                completionHandler(.success(()))
            } catch let error {
                completionHandler(.failure(error))
            }

        } else {
            // If we're passing in `nil` for the image, we need to remove the currently
            // stored image so that it's not showing up.
            do {
                try FileManager.default.removeItem(at: filePathPortrait)
                try FileManager.default.removeItem(at: filePathLandscape)
                completionHandler(.success(()))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    // MARK: - Wallpaper retrieval
    func retrieveCurrentWallpaperObject() -> Wallpaper? {
        if let savedWallpaper = userDefaults.object(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperObject) as? Data {
            let decoder = JSONDecoder()
            if let wallpaper = try? decoder.decode(Wallpaper.self, from: savedWallpaper) {
                return wallpaper
            }
        }

        return nil
    }

    func retrieveSavedImageWith(key: String) -> UIImage? {
        if let filePath = filePath(forKey: key),
           let fileData = FileManager.default.contents(atPath: filePath.path),
           let image = UIImage(data: fileData) {
            return image
        }

        return nil
    }

    // MARK: - Helper methods
    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(
            for: .documentDirectory,
               in: FileManager.SearchPathDomainMask.userDomainMask).first
        else { return nil }

        return documentURL.appendingPathComponent(key)
    }
}
