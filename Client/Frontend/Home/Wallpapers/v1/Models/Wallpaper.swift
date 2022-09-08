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
    }

    enum ImageTypeID {
        case thumbnail
        case portrait
        case landscape
    }

    enum CodingKeys: String, CodingKey {
        case textColor = "text-color"
        case cardColor = "card-color"
        case id
    }

    let id: String
    let textColor: UIColor?
    let cardColor: UIColor?

    var thumbnailID: String { return "\(id)\(fileId.thumbnail)" }
    var portraitID: String { return "\(id)\(deviceVersionID)\(fileId.portrait)" }
    var landscapeID: String { return "\(id)\(deviceVersionID)\(fileId.landscape)" }
    private var deviceVersionID: String {
        return UIDevice.current.userInterfaceIdiom == .pad ? fileId.iPad : fileId.iPhone
    }

    var type: WallpaperType {
        return id == "fxDefault" ? .defaultWallpaper : .other
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

    // MARK: - Helper fuctions
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

        let textHexString = try values.decode(String.self, forKey: .textColor)
        let cardHexString = try values.decode(String.self, forKey: .cardColor)

        var colorInt: UInt64 = 0
        if Scanner(string: textHexString).scanHexInt64(&colorInt) {
            textColor = UIColor(colorString: textHexString)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Received text-color is not a proper hex code"))
        }

        colorInt = 0
        if Scanner(string: cardHexString).scanHexInt64(&colorInt) {
            cardColor = UIColor(colorString: cardHexString)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Received text-color is not a proper hex code"))
        }
    }
}

extension Wallpaper: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        guard let textColorHexString = textColor?.hexString,
              let cardColorHexString = cardColor?.hexString
        else {
            let nilString: String? = nil
            try container.encode(id, forKey: .id)
            try container.encode(nilString, forKey: .textColor)
            try container.encode(nilString, forKey: .cardColor)
            return
        }

        let textHex = dropOctothorpeIfAvailable(from: textColorHexString)
        let cardHex = dropOctothorpeIfAvailable(from: cardColorHexString)

        try container.encode(id, forKey: .id)
        try container.encode(textHex, forKey: .textColor)
        try container.encode(cardHex, forKey: .cardColor)
    }

    private func dropOctothorpeIfAvailable(from string: String) -> String {
        if string.hasPrefix("#") {
            return string.remove("#")
        }

        return string
    }
}
