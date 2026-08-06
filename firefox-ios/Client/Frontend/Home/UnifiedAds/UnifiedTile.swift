// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import MozillaAppServices

/// Unified tiles are a type of tiles belonging in the Top sites section on the Firefox home page.
/// See UnifiedAdsProvider for how they are requested from the ads client.
struct UnifiedTile {
    let url: String
    let callbacks: UnifiedTileCallback
    let imageUrl: String
    let name: String

    static func from(mozAdsTile: MozAdsTile) -> UnifiedTile {
        return UnifiedTile(
            url: mozAdsTile.url,
            callbacks: UnifiedTileCallback(
                click: mozAdsTile.callbacks.click,
                impression: mozAdsTile.callbacks.impression
            ),
            imageUrl: mozAdsTile.imageUrl,
            name: mozAdsTile.name
        )
    }
}

// Callbacks for telemetry events
struct UnifiedTileCallback {
    let click: String
    let impression: String
}
