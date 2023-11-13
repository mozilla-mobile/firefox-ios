// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

class MockHistoryHighlightsDataAdaptor: HistoryHighlightsDataAdaptor {
    var mockHistoryItems = [HighlightItem]()
    weak var delegate: HistoryHighlightsDelegate?
    var deleteCallCount = 0

    func getHistoryHighlights() -> [HighlightItem] {
        return mockHistoryItems
    }

    func delete(_ item: HighlightItem) {
        deleteCallCount += 1
    }
}
