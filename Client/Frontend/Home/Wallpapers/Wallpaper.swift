// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

// MARK: - Wallpaper Type
enum WallpaperType {
    case defaultBackground
    case themed(type: WallpaperCollectionType)
}

extension WallpaperType: Equatable {
    static func ==(lhs: WallpaperType, rhs: WallpaperType) -> Bool {
        switch (lhs, rhs) {
        case (.defaultBackground, .defaultBackground):
            return true
        case (let .themed(lhsString), let .themed(rhsString)):
            return lhsString == rhsString
        default:
            return false
        }
    }
}

extension WallpaperType: Codable {
    enum CodingKeys: CodingKey {
        case defaultBackground, themed
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .defaultBackground:
            try container.encode(true, forKey: .defaultBackground)
        case .themed(let type):
            try container.encode(type, forKey: .themed)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let key = container.allKeys.first

        switch key {
        case .defaultBackground:
            self = .defaultBackground
        case .themed:
            let themeType = try container.decode(WallpaperCollectionType.self,
                                                 forKey: .themed)
            self = .themed(type: themeType)
        default:
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: container.codingPath,
                                      debugDescription: "Unabled to decode enum.")
            )
        }
    }
}

// MARK: - Collection types
enum WallpaperCollectionType: String, Codable {
    case firefoxDefault
    case projectHouse
    case seasonal
}

// MARK: - Wallpaper
struct Wallpaper: Codable, Equatable {
    // MARK: - Variables
    let name: String
    let type: WallpaperType
    fileprivate let expiryDate: String?
    fileprivate let locales: [String]?

    var image: UIImage? {
        var fileName = name
        if UIWindow.isLandscape { fileName += "_ls" }
        if UIDevice.current.userInterfaceIdiom == .pad { fileName += "_pad" }

        return UIImage(named: fileName)
    }

    var isElibibleForDisplay: Bool {
        if type == .defaultBackground || type == .themed(type: .firefoxDefault) { return true }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let currentDate = Date()

        if let locales = locales,
           locales.contains(Locale.current.identifier),
           let wallpaperDate = expiryDate,
           let expiredDate = formatter.date(from: wallpaperDate),
           currentDate <= expiredDate {
            return true
        }

        return false
    }

    // MARK: - Initializer
    init(named name: String,
         ofType type: WallpaperType,
         expiringOn date: String? = nil,
         limitedToLocale locale: [String]? = nil) {
        self.name = name
        self.expiryDate = date
        self.type = type
        self.locales = locale
    }
}

