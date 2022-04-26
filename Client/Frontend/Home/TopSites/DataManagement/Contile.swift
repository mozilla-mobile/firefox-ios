// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

/// Contiles are a type of tiles belonging in the Shortcuts section on the Firefox home page.
/// See ContileProvider and the resource endpoint there for context.
struct Contile: Codable, Equatable {
    let id: Int
    let name: String
    let url: String
    let clickUrl: String
    let imageUrl: String
    let imageSize: Int
    let impressionUrl: String
    let position: Int?
}

// Root node containing contiles
struct Contiles: Codable {
    let tiles: [Contile]
}

