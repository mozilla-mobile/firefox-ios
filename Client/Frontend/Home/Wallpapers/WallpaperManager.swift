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
        store(image: wallpaper.image) { result in
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

    private func store(image: UIImage?, completionHandler: @escaping (Result<Void, Error>) -> Void) {
        guard let filePath = filePath(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperImage) else { return }

        if let image = image,
           let pngRepresentation = image.pngData() {
            do {
                try pngRepresentation.write(to: filePath, options: .atomic)
                completionHandler(.success(()))
            } catch let error {
                completionHandler(.failure(error))
            }

        } else {
            do {
                try FileManager.default.removeItem(at: filePath)
                completionHandler(.success(()))
            } catch {
                completionHandler(.failure(error))
            }
        }
    }

    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(
            for: .documentDirectory,
               in: FileManager.SearchPathDomainMask.userDomainMask).first
        else { return nil }

        return documentURL.appendingPathComponent(key)
    }

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
        if let filePath = self.filePath(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperImage),
           let fileData = FileManager.default.contents(atPath: filePath.path),
           let image = UIImage(data: fileData) {
            return image
        }

        return nil
    }
}
