// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

enum WallpaperType: String, Codable {
    case defaultBackground
    case firefox
    case themed
    case seasonal
}

struct Wallpaper: Codable {
    private let name: String
    let type: WallpaperType
    let expiryDate: String?
    let locales: [String]

    var image: UIImage? {
        return UIImage(named: name)
    }

    var imageiPad: UIImage? {
        return UIImage(named: name + "iPad")
    }

    init(named name: String,
         ofType type: WallpaperType,
         expiringOn date: String? = nil,
         limitedToLocale locale: [String] = [])
    {
        self.name = name
        self.expiryDate = date
        self.type = type
        self.locales = locale
    }
}

class WallpaperDataManager {
    var availableWallpapers: [Wallpaper] {
        return buildWallpapers()
    }

    var currentlySelectedWallpaper: Wallpaper? {
        return retrieveCurrentWallpaper()
    }

    var currentWallpaperImage: UIImage? {
        return nil
    }

    // MARK: - Wallpaper data
    private func buildWallpapers() -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        wallpapers.append(contentsOf: buildDefaultWallpapers())

        let promotionalWallpapers = buildPromotionalWallpapers()
        wallpapers.append(contentsOf: checkPromotionalWallpapersForEligibility(promotionalWallpapers))

        return wallpapers
    }

    private func buildDefaultWallpapers() -> [Wallpaper] {
        let defaultWallpaper = Wallpaper(named: "defaultBackground", ofType: .defaultBackground)
        let fxWallpaper1 = Wallpaper(named: "fxWallpaper1", ofType: .firefox)
        let fxWallpaper2 = Wallpaper(named: "fxWallpaper2", ofType: .firefox)

        return [defaultWallpaper, fxWallpaper1, fxWallpaper2]
    }

    private func buildPromotionalWallpapers() -> [Wallpaper] {
        let promotionalExpiryDate = "20220430"
        let promotionalLocale = ["en_US", "en_CA"]

        let promotionalWallpaper1 = Wallpaper(named: "promotionalWallpaper1",
                                              ofType: .themed,
                                              expiringOn: promotionalExpiryDate,
                                              limitedToLocale: promotionalLocale)

        let promotionalWallpaper2 = Wallpaper(named: "promotionalWallpaper2",
                                              ofType: .themed,
                                              expiringOn: promotionalExpiryDate,
                                              limitedToLocale: promotionalLocale)

        let promotionalWallpaper3 = Wallpaper(named: "promotionalWallpaper3",
                                              ofType: .themed,
                                              expiringOn: promotionalExpiryDate,
                                              limitedToLocale: promotionalLocale)

        return [promotionalWallpaper1, promotionalWallpaper2, promotionalWallpaper3]
    }

    /// Checks an array of `Wallpaper` to see what eligible wallpaper can be shown.
    ///
    /// - Parameter wallpapers: An array of `Wallpaper` that will have expiry
    /// - Returns: A array of promotional wallpapers that can be shown to the user
    private func checkPromotionalWallpapersForEligibility(_ wallpapers: [Wallpaper]) -> [Wallpaper] {

        var eligibleWallpapers = [Wallpaper]()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let currentDate = Date()

        for wallpaper in wallpapers {
            if wallpaper.locales.contains(Locale.current.identifier),
               let wallpaperDate = wallpaper.expiryDate,
               let expiryDate = formatter.date(from: wallpaperDate),
               currentDate < expiryDate {

                eligibleWallpapers.append(wallpaper)
            }
        }

        return eligibleWallpapers
    }

    // MARK: - Wallpaper storage
    func store(wallpaper: Wallpaper) {

    }

    func store(image: UIImage) {
        if let pngRepresentation = image.pngData(),
           let filePath = filePath(forKey: PrefsKeys.WallpaperManagerCurrentWallpaperImage) {
            do  {
                try pngRepresentation.write(to: filePath, options: .atomic)
            } catch let error {
                print("Saving file resulted in error: ", error)
            }
        }
    }

    private func filePath(forKey key: String) -> URL? {
        let fileManager = FileManager.default
        guard let documentURL = fileManager.urls(
            for: .documentDirectory,
               in: FileManager.SearchPathDomainMask.userDomainMask).first
        else { return nil }

        return documentURL.appendingPathComponent(key + ".png")
    }

    private func retrieveCurrentWallpaper() -> Wallpaper? {

        return nil
    }
}
