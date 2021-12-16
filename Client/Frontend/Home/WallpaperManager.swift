// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
import Shared

struct Wallpaper {
    private let name: String
    let image: UIImage?
    let contrastStyle: UIUserInterfaceStyle

    init(named name: String, withContrast contrastStyle: UIUserInterfaceStyle = .unspecified) {
        self.name = name
        self.image = UIImage(named: name)
        self.contrastStyle = contrastStyle
    }
}

struct WallpaperManager {

    let defaultWallpaper = Wallpaper(named: "defaultWallpaper")
    let wallpaper01 = Wallpaper(named: "wallpaper1")
    let wallpaper02 = Wallpaper(named: "wallpaper1")

    var wallpaperArray: [Wallpaper]

    var currentWallpaper: Wallpaper {
        guard let savedWallpaper = UserDefaults.standard.value(forKey: PrefsKeys.WallpaperManagerCustomizationKey) as? Wallpaper else {
            return defaultWallpaper
        }

        return savedWallpaper
    }

    init() {
        self.wallpaperArray = [defaultWallpaper, wallpaper01, wallpaper02]
    }

    func updateTo() {

    }

    func cycle() {

    }
}
