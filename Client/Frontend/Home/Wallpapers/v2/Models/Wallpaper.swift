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
    enum CodingKeys: String, CodingKey {
        case textColour = "text-color"
        case id
    }

    let id: String
    let textColour: UIColor

    var type: WallpaperType {
        return id == "fxDefault" ? .defaultWallpaper : .other
    }

    var needsToFetchResources: Bool {
        guard type != .defaultWallpaper else { return false }
        return portrait == nil || landscape == nil
    }

    // TODO: This following properties will need to be replaced with fetching the
    // resource from the local folder once that functionality is in. For now, we're
    // just returning an existing image to enable development of UI related work.
    var thumbnail: UIImage? {
        guard type == .other else { return nil } // default/empty wallpaper
        return UIImage(imageLiteralResourceName: "\(id)")
    }

    var portrait: UIImage? {
        guard type == .other else { return nil } // default/empty wallpaper
        return UIImage(imageLiteralResourceName: "\(id)")
    }

    var landscape: UIImage? {
        guard type == .other else { return nil } // default/empty wallpaper
        return UIImage(imageLiteralResourceName: "\(id)_ls")
    }
}

extension Wallpaper: Decodable {
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        id = try values.decode(String.self, forKey: .id)

        let hexString = try values.decode(String.self, forKey: .textColour)

        // Validate that `hexString` is actually a valid hex vaule
        var colorInt: UInt64 = 0
        if Scanner(string: hexString).scanHexInt64(&colorInt) {
            textColour = UIColor(colorString: hexString)
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
        let hexString = textColour.hexString

        try container.encode(id, forKey: .id)
        try container.encode(hexString, forKey: .textColour)
    }
}
