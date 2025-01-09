// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

@testable import Client

class MockTopSiteHistoryManager: TopSiteHistoryManagerProvider {
    private let sites: [Site]?
    var removeDefaultTopSitesTileCalledCount = 0
    var removeTopSiteCalledCount = 0

    static var defaultSuccessData: [Site] {
        return [
            Site.createPinnedSite(fromSite: Site.createBasicSite(url: "www.mozilla.com", title: "Pinned Site Test")),
            Site.createPinnedSite(fromSite: Site.createBasicSite(url: "www.firefox.com", title: "Pinned Site 2 Test")),
            Site.createBasicSite(url: "www.example.com", title: "History-Based Tile Test")
        ]
    }

    // Demonstrates a tile that exists under sponsored tile list
    static var duplicateTile: [Site] {
        return [
            Site.createPinnedSite(
                fromSite: Site.createBasicSite(
                    url: "https://firefox.com",
                    title: "Firefox Sponsored Tile"
                )
            ),
        ]
    }

    static var noPinnedData: [Site] {
        return [
            Site.createBasicSite(url: "https://firefox.com", title: "History-Based Tile Test"),
            Site.createBasicSite(url: "www.example.com", title: "History-Based Tile 2 Test")
        ]
    }

    init(sites: [Site]? = []) {
        self.sites = sites
    }

    func getTopSites(completion: @escaping ([Site]?) -> Void) {
        completion(sites)
    }

    func removeDefaultTopSitesTile(site: Site) {
        removeDefaultTopSitesTileCalledCount += 1
    }

    func removeTopSite(site: Site) {
        removeTopSiteCalledCount += 1
    }
}
