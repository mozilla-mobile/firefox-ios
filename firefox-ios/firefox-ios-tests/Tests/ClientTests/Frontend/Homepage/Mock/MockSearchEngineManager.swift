// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
@testable import Client

final class MockSearchEnginesManager: SearchEnginesManagerProvider, @unchecked Sendable {
    private let searchEngines: [OpenSearchEngine]

    weak var delegate: (any SearchEngineDelegate)?

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
        ensureMainThread {
            completion(
                SearchEnginePrefs(
                    engineIdentifiers: self.searchEngines.map {
                        $0.shortName
                    },
                    disabledEngines: [],
                    version: .v1),
                self.searchEngines
            )
        }
    }
}
