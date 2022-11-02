// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import Client

class MockRecentlyVisitedManager: RecentlyVisitedManagerProtocol {

    var getDataCallCount = 0
    var
    tlyVisitedItem]?) -> Void)?

    func searchData(searchQuery: String,
                              profile: Profile,
                              tabs: [Tab],
                              resultCount: Int,
                              completion: @escaping ([RecentlyVisitedItem]?) -> Void) {}

    func getData(with profile: Profile,
                           and tabs: [Tab],
                           shouldGroup: Bool,
                           resultCount: Int,
                           completion: @escaping ([RecentlyVisitedItem]?) -> Void) {
        getDataCallCount += 1
        getDataCompletion = completion
    }

    func callGetHighlightsDataCompletion(result: [RecentlyVisitedItem]) {
        getDataCompletion?(result)
    }
}
