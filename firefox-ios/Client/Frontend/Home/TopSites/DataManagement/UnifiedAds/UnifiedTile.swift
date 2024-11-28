// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// Unified tiles are a type of tiles belonging in the Top sites section on the Firefox home page.
/// See UnifiedAdsProvider and the resource endpoint there for context.
struct UnifiedTile: Decodable {
    let format: String
    let url: String
    let callbacks: UnifiedTileCallback
    let imageUrl: String
    let name: String
    let blockKey: String
}

// Root node containing tiles
struct UnifiedTiles: Decodable {
    let newtab_mobile_tile_1: [UnifiedTile]
    let newtab_mobile_tile_2: [UnifiedTile]
}

// Callbacks for telemetry events
struct UnifiedTileCallback: Decodable {
    let click: String
    let impression: String
}
