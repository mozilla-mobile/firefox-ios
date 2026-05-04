// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
@testable import QuickAnswersKit

final class MockResultsServiceFactory: ResultsServiceFactory {
    var makeCallCount = 0
    var shouldReturnNil = false

    func make(prefs: Prefs, config: QuickAnswersConfig) -> ResultsService? {
        makeCallCount += 1

        if shouldReturnNil {
            return nil
        }

        return MockResultsService()
    }
}
