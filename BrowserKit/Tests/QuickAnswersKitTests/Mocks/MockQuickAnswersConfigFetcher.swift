// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit

final class MockQuickAnswersConfigFetcher: QuickAnswersConfigFetcher, @unchecked Sendable {
    var configToReturn: QuickAnswersConfig
    var errorToThrow: Error?
    var fetchCallCount = 0

    init(configToReturn: QuickAnswersConfig = QuickAnswersConfig()) {
        self.configToReturn = configToReturn
    }

    func fetch() async throws -> QuickAnswersConfig {
        fetchCallCount += 1
        if let errorToThrow {
            throw errorToThrow
        }
        return configToReturn
    }
}
