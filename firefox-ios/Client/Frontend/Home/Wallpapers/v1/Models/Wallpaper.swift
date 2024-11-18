// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum WallpaperType: String {
    case defaultWallpaper
    case other
}

struct WallpaperFilenameIdentifiers {
    static let thumbnail = "_thumbnail"
    static let portrait = "_portrait"
    static let landscape = "_landscape"
    static let iPad = "_iPad"
    static let iPhone = "_iPhone"
}

/// A single wallpaper instance.
struct Wallpaper: Equatable {
    typealias fileId = WallpaperFilenameIdentifiers

    static func == (lhs: Wallpaper, rhs: Wallpaper) -> Bool {
        return lhs.id == rhs.id
                && lhs.textColor == rhs.textColor
                && lhs.cardColor == rhs.cardColor
                && lhs.logoTextColor == rhs.logoTextColor
    }

    enum ImageTypeID {
        case thumbnail
        case portrait
        case landscape
    }

    enum CodingKeys: String, CodingKey {
        case textColor = "text-color"
        case cardColor = "card-color"
        case logoTextColor = "logo-text-color"
        case id
    }

    let id: String
    let textColor: UIColor?
    let cardColor: UIColor?
    let logoTextColor: UIColor?

    var thumbnailID: String { return "\(id)\(fileId.thumbnail)" }
    var portraitID: String { return "\(id)\(deviceVersionID)\(fileId.portrait)" }
    var landscapeID: String { return "\(id)\(deviceVersionID)\(fileId.landscape)" }

    static var defaultWallpaper: Wallpaper {
        return Wallpaper(
            id: Wallpaper.defaultWallpaperName,
            textColor: nil,
            cardColor: nil,
            logoTextColor: nil
        )
    }

    var type: WallpaperType {
        return id == Wallpaper.defaultWallpaperName ? .defaultWallpaper : .other
    }

    var needsToFetchResources: Bool {
        guard type != .defaultWallpaper else { return false }
        return portrait == nil || landscape == nil
    }

    var thumbnail: UIImage? {
        return fetchResourceFor(imageType: .thumbnail)
    }

    var portrait: UIImage? {
        return fetchResourceFor(imageType: .portrait)
    }

    var landscape: UIImage? {
        return fetchResourceFor(imageType: .landscape)
    }

    private static var defaultWallpaperName = "fxDefault"
    private var deviceVersionID: String {
        return UIDevice.current.userInterfaceIdiom == .pad ? fileId.iPad : fileId.iPhone
    }

    // MARK: - Helper functions
    private func fetchResourceFor(imageType: ImageTypeID) -> UIImage? {
        // If it's a default (empty) wallpaper
        guard type == .other else { return nil }

        do {
            let storageUtility = WallpaperStorageUtility()

            switch imageType {
            case .thumbnail:
                return try storageUtility.fetchImageNamed(thumbnailID)
            case .portrait:
                return try storageUtility.fetchImageNamed(portraitID)
            case .landscape:
                return try storageUtility.fetchImageNamed(landscapeID)
            }
        } catch {
            return nil
        }
    }
}

extension Wallpaper: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(String.self, forKey: .id)

        // Returning `nil` if the strings aren't valid as we already handle nil cases
        let textHexString = try? values.decode(String.self, forKey: .textColor)
        let cardHexString = try? values.decode(String.self, forKey: .cardColor)
        let logoHexString = try? values.decode(String.self, forKey: .logoTextColor)

        let getColorFrom: (String?) -> UIColor? = { hexString in
            guard let hexString = hexString else { return nil }
            var colorInt: UInt64 = 0
            if Scanner(string: hexString).scanHexInt64(&colorInt) {
                return UIColor(colorString: hexString)
            } else {
                return nil
            }
        }

        textColor = getColorFrom(textHexString)
        cardColor = getColorFrom(cardHexString)
        logoTextColor = getColorFrom(logoHexString)
    }
}

extension Wallpaper: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        guard let textColorHexString = textColor?.hexString,
              let cardColorHexString = cardColor?.hexString,
              let logoColorHexString = logoTextColor?.hexString
        else {
            let nilString: String? = nil
            try container.encode(id, forKey: .id)
            try container.encode(nilString, forKey: .textColor)
            try container.encode(nilString, forKey: .cardColor)
            try container.encode(nilString, forKey: .logoTextColor)
            return
        }

        let textHex = dropOctothorpeIfAvailable(from: textColorHexString)
        let cardHex = dropOctothorpeIfAvailable(from: cardColorHexString)
        let logoHex = dropOctothorpeIfAvailable(from: logoColorHexString)

        try container.encode(id, forKey: .id)
        try container.encode(textHex, forKey: .textColor)
        try container.encode(cardHex, forKey: .cardColor)
        try container.encode(logoHex, forKey: .logoTextColor)
    }

    private func dropOctothorpeIfAvailable(from string: String) -> String {
        if string.hasPrefix("#") {
            return string.removingOccurrences(of: "#")
        }

        return string
    }
}
