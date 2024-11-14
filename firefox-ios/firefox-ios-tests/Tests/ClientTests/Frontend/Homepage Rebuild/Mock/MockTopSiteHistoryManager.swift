// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

@testable import Client

class MockTopSiteHistoryManager: TopSiteHistoryManagerProvider {
    private let sites: [Site]?
    static var defaultSuccessData: [Site] {
        return [
            PinnedSite(
                site: Site(url: "www.mozilla.com", title: "Pinned Site Test"),
                faviconResource: nil
            ),
            PinnedSite(
                site: Site(url: "www.firefox.com", title: "Pinned Site 2 Test"),
                faviconResource: nil
            ),
            Site(url: "www.example.com", title: "History-Based Tile Test")
        ]
    }

    // Demonstrates a tile that exists under sponsored tile list
    static var duplicateTile: [Site] {
        return [
            PinnedSite(
                site: Site(url: "https://firefox.com", title: "Firefox Sponsored Tile"),
                faviconResource: nil
            )
        ]
    }

    static var noPinnedData: [Site] {
        return [
            Site(url: "https://firefox.com", title: "History-Based Tile Test"),
            Site(url: "www.example.com", title: "History-Based Tile 2 Test")
        ]
    }

    init(sites: [Site]? = []) {
        self.sites = sites
    }

    func getTopSites(completion: @escaping ([Site]?) -> Void) {
        completion(sites)
    }
}
