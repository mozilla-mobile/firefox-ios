// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
@testable import QuickAnswersKit

final class MockResultsServiceFactory: ResultsServiceFactory {
    var makeCallCount = 0
    var shouldThrow = false
    var lastConversation: QuickAnswersConversation?

    func make(
        prefs: Prefs,
        configFetcher: QuickAnswersConfigFetcher,
        conversation: QuickAnswersConversation
    ) throws -> ResultsService {
        makeCallCount += 1
        lastConversation = conversation

        if shouldThrow {
            throw ResultsServiceError.unableToCreateService
        }

        return MockResultsService()
    }
}
