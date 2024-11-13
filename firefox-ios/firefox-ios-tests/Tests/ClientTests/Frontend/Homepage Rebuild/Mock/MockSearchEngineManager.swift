// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockSearchEnginesManager: SearchEnginesManagerProvider {
    private let searchEngine: OpenSearchEngine?
    var defaultEngine: OpenSearchEngine? {
        return searchEngine
    }
    init(searchEngine: OpenSearchEngine? = nil) {
        self.searchEngine = searchEngine
    }
}
