// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

enum WallpaperType: String {
    case defaultWallpaper
    case other
}

/// A single wallpaper instance.
struct Wallpaper: Equatable {
    enum ImageTypeID {
        case thumbnail
        case portrait
        case landscape
    }

    enum CodingKeys: String, CodingKey {
        case textColour = "text-color"
        case cardColour = "card-color"
        case id
    }

    let id: String
    let textColour: UIColor?
    let cardColour: UIColor?

    var thumbnailID: String { return "\(id)_thumbnail" }
    var portraitID: String { return "\(id)\(deviceVersionID)_portrait" }
    var landscapeID: String { return "\(id)\(deviceVersionID)_landscape" }
    private var deviceVersionID: String {
        return UIDevice.current.userInterfaceIdiom == .pad ? "_iPad" : "_iPhone"
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
                return try storageUtility.fetchImageWith(name: thumbnailID, andID: id)
            case .portrait:
                return try storageUtility.fetchImageWith(name: portraitID, andID: id)
            case .landscape:
                return try storageUtility.fetchImageWith(name: landscapeID, andID: id)
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

        let textHexString = try values.decode(String.self, forKey: .textColour)
        let cardHexString = try values.decode(String.self, forKey: .cardColour)

        var colorInt: UInt64 = 0
        if Scanner(string: textHexString).scanHexInt64(&colorInt) {
            textColour = UIColor(colorString: textHexString)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Received text-colour is not a proper hex code"))
        }

        colorInt = 0
        if Scanner(string: cardHexString).scanHexInt64(&colorInt) {
            cardColour = UIColor(colorString: cardHexString)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Received text-colour is not a proper hex code"))
        }
    }
}

extension Wallpaper: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        guard let textColorHexString = textColour?.hexString,
              let cardColorHexString = cardColour?.hexString
        else {
            let nilString: String? = nil
            try container.encode(id, forKey: .id)
            try container.encode(nilString, forKey: .textColour)
            try container.encode(nilString, forKey: .cardColour)
            return
        }

        let textHex = dropOctothorpeIfAvailable(from: textColorHexString)
        let cardHex = dropOctothorpeIfAvailable(from: cardColorHexString)

        try container.encode(id, forKey: .id)
        try container.encode(textHex, forKey: .textColour)
        try container.encode(cardHex, forKey: .cardColour)
    }

    private func dropOctothorpeIfAvailable(from string: String) -> String {
        if string.hasPrefix("#") {
            return string.remove("#")
        }

        return string
    }
}
