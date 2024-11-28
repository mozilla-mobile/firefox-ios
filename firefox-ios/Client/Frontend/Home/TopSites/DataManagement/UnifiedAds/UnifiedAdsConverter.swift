// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

/// To keep the integration of unified ads simple with minimal changes, we are converting Unified tiles
/// into the old API Contile object. This will avoid logic changes inside the TopSitesDataAdaptor, which will be deprecated
/// soon anyway due to the refactor of the homepage.
struct UnifiedAdsConverter {
    func convert(unifiedTiles: [UnifiedTile]) -> [Contile] {
        return unifiedTiles.enumerated().map { (index, tile) in
            Contile(
                id: 0, // Was relevant for old telemetry, but not with unified ads
                name: tile.name,
                url: tile.url,
                clickUrl: tile.callbacks.click,
                imageUrl: tile.imageUrl,
                imageSize: 0, // Zero since not used anyway
                impressionUrl: tile.callbacks.impression,
                position: index + 1 // Keeping the same tile position as provided in the array
            )
        }
    }
}
