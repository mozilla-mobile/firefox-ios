// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

/// Unified tiles are a type of tiles belonging in the Top sites section on the Firefox home page.
/// See UnifiedAdsProvider and the resource endpoint there for context.
struct UnifiedTile: Decodable {
    let format: String
    let url: String
    let callbacks: UnifiedTileCallback
    let imageUrl: String
    let name: String
    let blockKey: String

    static func from(name: String, mozAdsPlacement: MozAdsPlacement) -> UnifiedTile {
        let content = mozAdsPlacement.content
        return UnifiedTile(
            format: content.format,
            url: content.url,
            callbacks: UnifiedTileCallback(
                click: content.callbacks.click ?? "",
                impression: content.callbacks.impression ?? ""
            ),
            imageUrl: content.imageUrl,
            name: name,
            blockKey: content.blockKey
        )
    }
}

// Callbacks for telemetry events
struct UnifiedTileCallback: Decodable {
    let click: String
    let impression: String
}
