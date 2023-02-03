// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import Client


class MockSearchEngineProvider: SearchEngineProvider {
    var getSomeDataCallCount = 0
    var getSomeDataCompletion: ([OpenSearchEngine]) -> Void?

    func callGetSomeDataCompletion(withResult result: @escaping ([OpenSearchEngine]) -> Void) {
        getSomeDataCompletion(result)
    }

    func getOrderedEngines(completion: @escaping ([Client.OpenSearchEngine]) -> Void) {
        getSomeDataCallCount += 1
        getSomeDataCompletion = completion
    }

}
