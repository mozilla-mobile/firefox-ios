// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared

struct WallpaperManager {

    // MARK: - Variables
    private let userDefaults: UserDefaults
    private let wallpaperData: WallpaperDataManager

    var wallpapers: [Wallpaper] {
        return wallpaperData.availableWallpapers
    }

    var currentWallpaper: UIImage? {
        return retrieveCurrentWallpaperImage()
    }

    var telemetryMetadata: [String: String] {
        guard let wallpaper = retrieveCurrentWallpaperObject() else { return [:] }
        var metadata = [String: String]()

        metadata[TelemetryWrapper.EventExtraKey.wallpaperName.rawValue] = wallpaper.name

        if wallpaper.type == .defaultBackground {
            metadata[TelemetryWrapper.EventExtraKey.wallpaperType.rawValue] = "default"
        } else if case .themed(let type) = wallpaper.type {
            metadata[TelemetryWrapper.EventExtraKey.wallpaperType.rawValue] = type.rawValue
        }

        return metadata
    }

    var isUsingCustomWallpaper: Bool {
        // If no wallpaper was ever set, then we must be using the default wallpaper
        guard let currentWallpaper = retrieveCurrentWallpaperObject() else { return false }
        if currentWallpaper.type == .defaultBackground { return false }
        return true
    }

    var currentIndex: Int? {
        // If no wallpaper was ever set, then we must be at index 0
        guard let currentWallpaper = retrieveCurrentWallpaperObject() else { return 0 }

        for (index, wallpaper) in wallpaperData.availableWallpapers.enumerated() {
            if wallpaper == currentWallpaper {
                return index
            }
        }

        return nil
    }

    /// Returns the user's preference for whether or not to be able to change wallpapers
    /// by tapping on the logo on the homepage.
    ///
    /// Because the default value of this feature is actually `true`, we have to invert
    /// the actual value. Therefore, if the setting is `false`, we treat the setting as
    /// being turned on, as `false` is what UserDefaults returns when a bool does not
    /// exist for a key.
    var switchWallpaperFromLogoEnabled: Bool {
        get { return !userDefaults.bool(forKey: PrefsKeys.WallpaperManagerLogoSwitchPreference) }
        set { userDefaults.set(!newValue, forKey: PrefsKeys.WallpaperManagerLogoSwitchPreference) }
    }

    // MARK: - Initializer
    init(with userDefaults: UserDefaults = UserDefaults.standard,
         wallpaperData: WallpaperDataManager = WallpaperDataManager()) {
        self.userDefaults = userDefaults
        self.wallpaperData = wallpaperData
    }

    // MARK: - Public methods
    public func updateTo(index: Int) {
        let wallpapers = wallpaperData.availableWallpapers
        guard index <= (wallpapers.count - 1) else { return }
        updateSelectedWallpaper(to: wallpapers[index])
    }

    public func cycleWallpaper() {
        let newIndex = calculateIndex(using: currentIndex,
                                      and: wallpaperData.availableWallpapers)
        updateTo(index: newIndex)
    }

    // MARK: - Private functions
    private func calculateIndex(using currentIndex: Int?, and wallpaperArray: [Wallpaper]) -> Int {
        guard let currentIndex = currentIndex else { return 0 }

        let newIndex = currentIndex + 1
        let maxIndex = wallpaperArray.count - 1

        if newIndex > maxIndex {
            return 0
        }
        
        return newIndex
    }

    // MARK: - Wallpaper storage
    private func updateSelectedWallpaper(to wallpaper: Wallpaper) {
        store(wallpaper: wallpaper)
        store(image: wallpaper.image, landscapeImage: wallpaper.landscapeImage) { result in
            switch result {
            case .success(()):
                NotificationCenter.default.post(name: .WallpaperDidChange, object: nil)
            case .failure(let error):
                print("There was an error storing the wallpaper: ", error.localizedDescription)
            }
        }
    }

    private func store(wallpaper: Wallpaper) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(wallpaper) {
            userDefaults.set(encoded, forKey: PrefsKeys.WallpaperManagerCurrentWallpaperObject)
        }
    }

    private func store(image: UIImage?,
                       landscapeImage: UIImage?,
                       completionHandler: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let filePathPortrait = filePath(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperImage),
              let filePathLandscape = filePath(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperImageLandscape)
        else { return }

        if let image = image,
           let landscapeImage = landscapeImage,
           let portraitPngRepresentation = image.pngData(),
           let landscapePngRepresentation = landscapeImage.pngData() {
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
    private func retrieveCurrentWallpaperObject() -> Wallpaper? {
        if let savedWallpaper = userDefaults.object(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperObject) as? Data {
            let decoder = JSONDecoder()
            if let wallpaper = try? decoder.decode(Wallpaper.self, from: savedWallpaper) {
                return wallpaper
            }
        }

        return nil
    }

    private func retrieveCurrentWallpaperImage() -> UIImage? {
        let key = UIDevice.current.orientation.isLandscape ? PrefsKeys.WallpaperManagerCurrentWallpaperImageLandscape : PrefsKeys.WallpaperManagerCurrentWallpaperImage

        if let filePath = self.filePath(forKey: key),
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
