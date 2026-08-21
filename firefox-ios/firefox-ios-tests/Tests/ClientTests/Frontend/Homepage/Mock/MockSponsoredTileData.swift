// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

@testable import Client

struct MockSponsoredTileData {
    enum MockError: Error {
        case testError
    }

    static let emptySuccessData: [Site] = []

    static var defaultSuccessData: [Site] {
        return [
            makeSponsoredSite(
                url: "https://firefox.com",
                title: "Firefox Sponsored Tile",
                clickURL: "https://firefox.com/click",
                impressionURL: "https://test.com",
                imageURL: "https://test.com/image1.jpg"
            ),
            makeSponsoredSite(
                url: "https://mozilla.com",
                title: "Mozilla Sponsored Tile",
                clickURL: "https://mozilla.com/click",
                impressionURL: "https://example.com",
                imageURL: "https://test.com/image2.jpg"
            ),
            makeSponsoredSite(
                url: "https://support.mozilla.org/en-US/kb/firefox-focus-ios",
                title: "Focus Sponsored Tile",
                clickURL: "https://support.mozilla.org/en-US/kb/firefox-focus-ios/click",
                impressionURL: "https://another-example.com",
                imageURL: "https://test.com/image3.jpg"
            )
        ]
    }

    static let pinnedTitle = "A pinned title %@"
    static let pinnedURL = "https://www.apinnedurl.com/pinned%@"
    static let title = "A title %@"
    static let url = "https://www.aurl%@.com"

    static var pinnedDuplicateTile: Site {
        return makeSponsoredSite(
            url: String(format: MockSponsoredTileData.pinnedURL, "0"),
            title: String(format: MockSponsoredTileData.pinnedTitle, "0"),
            clickURL: "https://www.test.com/click",
            impressionURL: "https://test.com",
            imageURL: "https://test.com/image0.jpg"
        )
    }

    static var duplicateTile: Site {
        return makeSponsoredSite(
            url: String(format: MockSponsoredTileData.url, "0"),
            title: String(format: MockSponsoredTileData.title, "0"),
            clickURL: "https://www.test.com/click",
            impressionURL: "https://test.com",
            imageURL: "https://test.com/image0.jpg"
        )
    }

    static func makeSponsoredSite(
        url: String,
        title: String,
        clickURL: String,
        impressionURL: String,
        imageURL: String
    ) -> Site {
        let siteInfo = SponsoredSiteInfo(
            impressionURL: impressionURL,
            clickURL: clickURL,
            imageURL: imageURL
        )
        return Site.createSponsoredSite(url: url, title: title, siteInfo: siteInfo)
    }
}
