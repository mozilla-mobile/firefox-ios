// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

enum WallpaperType: String {
    case none
    case other
}

struct WallpaperFilenameIdentifiers {
    static let thumbnail = "_thumbnail"
    static let portrait = "_portrait"
    static let landscape = "_landscape"
    static let iPad = "_iPad"
    static let iPhone = "_iPhone"
}

enum WallpaperImageType: CaseIterable {
    case iPhonePortrait
    case iPhoneLandscape
    case iPadPortrait
    case iPadLandscape

    var fileSuffix: String {
        typealias fileId = WallpaperFilenameIdentifiers
        switch self {
        case .iPhonePortrait: return "\(fileId.iPhone)\(fileId.portrait)"
        case .iPhoneLandscape: return "\(fileId.iPhone)\(fileId.landscape)"
        case .iPadPortrait: return "\(fileId.iPad)\(fileId.portrait)"
        case .iPadLandscape: return "\(fileId.iPad)\(fileId.landscape)"
        }
    }
}

/// A single wallpaper instance.
struct Wallpaper: Equatable {
    static func == (lhs: Wallpaper, rhs: Wallpaper) -> Bool {
        return lhs.id == rhs.id
                && lhs.textColor == rhs.textColor
                && lhs.cardColor == rhs.cardColor
                && lhs.logoTextColor == rhs.logoTextColor
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

    private static let noAssetID = "fxDefault"

    static var baseWallpaper: Wallpaper {
        return Wallpaper(
            id: Wallpaper.noAssetID,
            textColor: nil,
            cardColor: nil,
            logoTextColor: nil
        )
    }

    var type: WallpaperType {
        return id == Wallpaper.noAssetID ? .none : .other
    }

    var hasImage: Bool {
        type != .none
    }

    // MARK: - Images

    var thumbnailID: String { return "\(id)\(WallpaperFilenameIdentifiers.thumbnail)" }
    var thumbnail: UIImage? { return loadImage(named: thumbnailID) }

    var iPhonePortrait: UIImage? { return image(for: .iPhonePortrait) }
    var iPhoneLandscape: UIImage? { return image(for: .iPhoneLandscape) }
    var iPadPortrait: UIImage? { return image(for: .iPadPortrait) }
    var iPadLandscape: UIImage? { return image(for: .iPadLandscape) }

    var needsToFetchResources: Bool {
        guard hasImage else { return false }
        return WallpaperImageType.allCases.contains { image(for: $0) == nil }
    }

    func fileName(for type: WallpaperImageType) -> String {
        return "\(id)\(type.fileSuffix)"
    }

    func image(for type: WallpaperImageType) -> UIImage? {
        return loadImage(named: fileName(for: type))
    }

    private func loadImage(named name: String) -> UIImage? {
        // If it's a default (empty) wallpaper
        guard type == .other else { return nil }
        return try? WallpaperStorageUtility().fetchImageNamed(name)
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
