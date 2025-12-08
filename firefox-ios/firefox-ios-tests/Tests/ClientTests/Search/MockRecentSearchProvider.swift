// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
@testable import Client

/// A mock for testing that methods are called.
final class MockRecentSearchProvider: RecentSearchProvider {
    private(set) var addRecentSearchCalledCount = 0
    private(set) var clearRecentSearchCalledCount = 0
    private let searchTerms: [String] = ["search term 1", "search term 2"]

    func addRecentSearch(_ term: String, url: String?) {
        addRecentSearchCalledCount += 1
    }

    func loadRecentSearches(completion: @escaping ([String]) -> Void) {
        completion(searchTerms)
    }

    func clear(completion: @escaping @Sendable (Result<(), any Error>) -> Void) {
        clearRecentSearchCalledCount += 1
    }
}
