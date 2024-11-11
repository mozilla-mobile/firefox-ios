// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

@testable import Client

class MockTopSiteHistoryManager: TopSiteHistoryManagerProvider {
    private let historyBasedSites: [Site]?

    init(historyBasedSites: [Site]? = [
        Site(url: "www.example.com", title: "History-Based Tile Test")
    ]) {
        self.historyBasedSites = historyBasedSites
    }

    func getTopSites(completion: @escaping ([Site]?) -> Void) {
        completion(historyBasedSites)
    }
}
