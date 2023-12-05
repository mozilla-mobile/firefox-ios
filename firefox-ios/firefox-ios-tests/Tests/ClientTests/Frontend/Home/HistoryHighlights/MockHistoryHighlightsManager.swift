// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

class MockHistoryHighlightsManager: HistoryHighlightsManagerProtocol {
    var getHighlightsDataCallCount = 0
    var getHighlightsDataCompletion: (([HighlightItem]?) -> Void)?

    func searchHighlightsData(searchQuery: String,
                              profile: Profile,
                              tabs: [Tab],
                              resultCount: Int,
                              completion: @escaping ([HighlightItem]?) -> Void) {}

    func getHighlightsData(with profile: Profile,
                           and tabs: [Tab],
                           shouldGroupHighlights: Bool,
                           resultCount: Int,
                           completion: @escaping ([HighlightItem]?) -> Void) {
        getHighlightsDataCallCount += 1
        getHighlightsDataCompletion = completion
    }

    func callGetHighlightsDataCompletion(result: [HighlightItem]) {
        getHighlightsDataCompletion?(result)
    }
}
