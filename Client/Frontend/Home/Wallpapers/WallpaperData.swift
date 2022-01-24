// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import UIKit

enum WallpaperType: String, Codable {
    case defaultBackground
    case firefox
    case themed
    case seasonal
}

struct Wallpaper: Codable, Equatable {
    let name: String
    let type: WallpaperType
    fileprivate let expiryDate: String?
    fileprivate let locales: [String]?

    var image: UIImage? {
        let isiPad = UIDevice.current.userInterfaceIdiom == .pad
        let fileName = isiPad ? name + "_iPad" : name

        return UIImage(named: fileName)
    }

    init(named name: String,
         ofType type: WallpaperType,
         expiringOn date: String? = nil,
         limitedToLocale locale: [String]? = nil)
    {
        self.name = name
        self.expiryDate = date
        self.type = type
        self.locales = locale
    }
}

fileprivate struct TimedProjects {
    struct TimedProject {
        let expiryDate: String
        let projectLocales: [String]
    }

    static let projectHouse = TimedProject(expiryDate: "20220430",
                                           projectLocales: ["en_US", "es_US"])
}

struct WallpaperDataManager {
    
    var availableWallpapers: [Wallpaper] {
        return buildWallpapers()
    }

    // MARK: - Wallpaper data
    private func buildWallpapers() -> [Wallpaper] {
        var wallpapers: [Wallpaper] = []
        wallpapers.append(contentsOf: defaultWallpapers())
        wallpapers.append(contentsOf: themedWallpapers())

        return wallpapers
    }

    private func defaultWallpapers() -> [Wallpaper] {
        let defaultWallpaper = Wallpaper(named: "defaultBackground", ofType: .defaultBackground)
        let fxWallpaper1 = Wallpaper(named: "fxWallpaper1", ofType: .firefox)
        let fxWallpaper2 = Wallpaper(named: "fxWallpaper2", ofType: .firefox)

        return [defaultWallpaper, fxWallpaper1, fxWallpaper2]
    }

    private func themedWallpapers() -> [Wallpaper] {
        let themedWallpapers = buildThemedWallpapers()
        return checkSpecialWallpapersForEligibility(themedWallpapers)
    }

    private func buildThemedWallpapers() -> [Wallpaper] {

        let themedWallpaper1 = Wallpaper(named: "themedWallpaper1",
                                         ofType: .themed,
                                         expiringOn: TimedProjects.projectHouse.expiryDate,
                                         limitedToLocale: TimedProjects.projectHouse.projectLocales)

        let themedWallpaper2 = Wallpaper(named: "themedWallpaper2",
                                         ofType: .themed,
                                         expiringOn: TimedProjects.projectHouse.expiryDate,
                                         limitedToLocale: TimedProjects.projectHouse.projectLocales)

        let themedWallpaper3 = Wallpaper(named: "themedWallpaper3",
                                         ofType: .themed,
                                         expiringOn: TimedProjects.projectHouse.expiryDate,
                                         limitedToLocale: TimedProjects.projectHouse.projectLocales)

        return [themedWallpaper1, themedWallpaper2, themedWallpaper3]
    }

    /// Checks an array of `Wallpaper` to see what eligible wallpaper can be shown.
    ///
    /// - Parameter wallpapers: An array of `Wallpaper` that will have expiry
    /// - Returns: A array of wallpapers that can be shown to the user
    private func checkSpecialWallpapersForEligibility(_ wallpapers: [Wallpaper]) -> [Wallpaper] {

        var eligibleWallpapers = [Wallpaper]()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let currentDate = Date()

        for wallpaper in wallpapers {
            if let locales = wallpaper.locales,
               locales.contains(Locale.current.identifier),
               let wallpaperDate = wallpaper.expiryDate,
               let expiryDate = formatter.date(from: wallpaperDate),
               currentDate < expiryDate {

                eligibleWallpapers.append(wallpaper)
            }
        }

        return eligibleWallpapers
    }
}
