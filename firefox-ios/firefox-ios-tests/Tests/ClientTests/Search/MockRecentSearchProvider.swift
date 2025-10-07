// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

/// A mock for testing that methods are called.
final class MockRecentSearchProvider: RecentSearchProvider {
    private(set) var addRecentSearchCalledCount = 0
    private(set) var recentSearchesCalledCount = 0
    private(set) var clearRecentSearchesCalledCount = 0

    var recentSearches: [String] {
        recentSearchesCalledCount += 1
        return ["foo", "bar"]
    }

    func addRecentSearch(_ term: String) {
        addRecentSearchCalledCount += 1
    }

    func clearRecentSearches() {
        clearRecentSearchesCalledCount += 1
    }
}
