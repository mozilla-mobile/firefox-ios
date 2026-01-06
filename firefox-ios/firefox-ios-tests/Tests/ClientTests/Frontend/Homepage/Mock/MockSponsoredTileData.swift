// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

@testable import Client

struct MockSponsoredTileData {
    enum MockError: Error {
        case testError
    }

    static let emptySuccessData: [UnifiedTile] = []

    static var defaultSuccessData: [UnifiedTile] {
        return [
            UnifiedTile(
                format: "",
                url: "https://firefox.com",
                callbacks: UnifiedTileCallback(
                    click: "https://firefox.com/click",
                    impression: "https://test.com"
                ),
                imageUrl: "https://test.com/image1.jpg",
                name: "Firefox Sponsored Tile",
                blockKey: "Block_key_1"
            ),
            UnifiedTile(
                format: "",
                url: "https://mozilla.com",
                callbacks: UnifiedTileCallback(
                    click: "https://mozilla.com/click",
                    impression: "https://example.com"
                ),
                imageUrl: "https://test.com/image2.jpg",
                name: "Mozilla Sponsored Tile",
                blockKey: "Block_key_2"
            ),
            UnifiedTile(
                format: "",
                url: "https://support.mozilla.org/en-US/kb/firefox-focus-ios",
                callbacks: UnifiedTileCallback(
                    click: "https://support.mozilla.org/en-US/kb/firefox-focus-ios/click",
                    impression: "https://another-example.com"
                ),
                imageUrl: "https://test.com/image3.jpg",
                name: "Focus Sponsored Tile",
                blockKey: "Block_key_3"
            )
        ]
    }

    static let pinnedTitle = "A pinned title %@"
    static let pinnedURL = "https://www.apinnedurl.com/pinned%@"
    static let title = "A title %@"
    static let url = "https://www.aurl%@.com"

    static var pinnedDuplicateTile: UnifiedTile {
        return UnifiedTile(
            format: "",
            url: String(format: MockSponsoredTileData.pinnedURL, "0"),
            callbacks: UnifiedTileCallback(
                click: "https://www.test.com/click",
                impression: "https://test.com"
            ),
            imageUrl: "https://test.com/image0.jpg",
            name: String(format: MockSponsoredTileData.pinnedTitle, "0"),
            blockKey: "Block_key_3"
        )
    }

    static var duplicateTile: UnifiedTile {
        return UnifiedTile(
            format: "",
            url: String(format: MockSponsoredTileData.url, "0"),
            callbacks: UnifiedTileCallback(
                click: "https://www.test.com/click",
                impression: "https://test.com"
            ),
            imageUrl: "https://test.com/image0.jpg",
            name: String(format: MockSponsoredTileData.title, "0"),
            blockKey: "Block_key_3"
        )
    }
}
