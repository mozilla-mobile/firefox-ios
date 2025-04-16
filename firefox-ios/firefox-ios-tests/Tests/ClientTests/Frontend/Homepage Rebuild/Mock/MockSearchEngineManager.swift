// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

@testable import Client

class MockSearchEnginesManager: SearchEnginesManagerProvider {
    private let searchEngines: [OpenSearchEngine]

    var defaultEngine: OpenSearchEngine? {
        return searchEngines.first
    }

    var orderedEngines: [OpenSearchEngine] {
        return searchEngines
    }

    init(searchEngines: [OpenSearchEngine] = []) {
        self.searchEngines = searchEngines
    }

    func getOrderedEngines(completion: @escaping SearchEngineCompletion) {
        completion(
            SearchEnginePrefs(
                engineIdentifiers: searchEngines.map {
                    $0.shortName
                },
                disabledEngines: [],
                version: .v1),
            searchEngines
        )
    }
}
