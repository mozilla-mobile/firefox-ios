// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import WebEngine

class MockFindInPageHelperDelegate: FindInPageHelperDelegate {
    var didUpdateCurrentResultCalled = 0
    var didUpdateTotalResultsCalled = 0
    var savedCurrentResult = 0
    var savedTotalResults = 0

    func findInPageHelper(didUpdateCurrentResult currentResult: Int) {
        savedCurrentResult = currentResult
        didUpdateCurrentResultCalled += 1
    }

    func findInPageHelper(didUpdateTotalResults totalResults: Int) {
        savedTotalResults = totalResults
        didUpdateTotalResultsCalled += 1
    }
}
