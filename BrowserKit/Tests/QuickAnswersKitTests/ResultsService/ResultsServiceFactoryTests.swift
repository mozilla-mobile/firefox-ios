// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit
import Testing
import TestKit

@testable import QuickAnswersKit

struct ResultsServiceFactoryTests {
    // TODO: FXIOS-15196 - Improve testing to be more valuable
    @Test
    func test_make_storesConfig() {
        let config = QuickAnswersConfig()
        let subject = createSubject(config: config)

        _ = subject.make()

        #expect(subject.config.instructions.isEmpty)
        #expect(subject.config.options.isEmpty)
    }

    // MARK: - Helper
    private func createSubject(
        config: QuickAnswersConfig = QuickAnswersConfig()
    ) -> DefaultResultsServiceFactory {
        let subject = DefaultResultsServiceFactory(config: config)
        return subject
    }
}
