// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum WallpaperJSONId: String {
    case goodData = "wallpaperGoodData"
    case noLearnMoreURL = "wallpaperNoLearnMoreURL"
    case badLastUpdatedDate = "wallpaperBadLastUpdatedDate"
    case noAvailabilityRange = "wallpaperNoAvailabilityRange"
    case noLocales = "wallpaperNoLocales"
    case availabilityStart = "wallpaperAvailabilityStart"
    case availabilityEnd = "wallpaperAvailabilityEnd"
    case badTextColor = "wallpaperBadTextColor"
    case newUpdates = "wallpaperNewUpdates"
}

protocol WallpaperJSONTestProvider: AnyObject {
    func getDataFromJSONFile(named name: WallpaperJSONId) -> Data
}

extension WallpaperJSONTestProvider {
    func getDataFromJSONFile(named name: WallpaperJSONId) -> Data {
        let bundle = Bundle(for: type(of: self))

        guard let url = bundle.url(forResource: name.rawValue, withExtension: "json") else {
            fatalError("Missing file: \(name.rawValue).json")
        }

        guard let data = try? Data(contentsOf: url) else {
            fatalError("Failure on Data(contentsOf:)")
        }

        return data
    }
}
