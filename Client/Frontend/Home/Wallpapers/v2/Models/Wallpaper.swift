// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// A single wallpaper instance.
struct Wallpaper: Codable, Equatable {
    enum CodingKeys: String, CodingKey {
        case textColour = "text-color"
        case id
    }

    let id: String
    let textColour: String
}
