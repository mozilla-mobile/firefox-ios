// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client

class MockSearchEngineProvider: SearchEngineProvider {
    var getUnorderedEnginesCount = 0
    var unorderedEngines: (([OpenSearchEngine]) -> Void)?

    var mockEngines: [OpenSearchEngine] = [OpenSearchEngine(engineID: "ATester",
                                                            shortName: "ATester",
                                                            image: UIImage(),
                                                            searchTemplate: "http://firefox.com/find?q={searchTerm}",
                                                            suggestTemplate: nil,
                                                            isCustomEngine: true)]

    func getUnorderedEngines(withResult result: [OpenSearchEngine]) {
        unorderedEngines?(mockEngines)
    }

    func getOrderedEngines(customEngines: [OpenSearchEngine],
                           orderedEngineNames: [String]?,
                           completion: @escaping ([OpenSearchEngine]) -> Void) {
        completion(mockEngines)
    }

    func getUnorderedBundledEnginesFor(locale: Locale,
                                       possibleLanguageIdentifier: [String],
                                       completion: @escaping ([OpenSearchEngine]) -> Void) {
        getUnorderedEnginesCount += 1
        unorderedEngines = completion
    }
}
