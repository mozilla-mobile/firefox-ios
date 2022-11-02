// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

class MockHistoryHighlightsDataAdaptor: RecentlyVisitedDataAdaptor {

    var mockHistoryItems = [RecentlyVisitedItem]()
    var delegate: RecentlyVisitedDelegate?
    var deleteCallCount = 0

    func getRecentlyVisited() -> [RecentlyVisitedItem] {
        return mockHistoryItems
    }

    func delete(_ item: RecentlyVisitedItem) {
        deleteCallCount += 1
    }
}
