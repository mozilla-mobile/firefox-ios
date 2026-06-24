// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

@testable import QuickAnswersKit

struct QuickAnswersConfigTests {
    @Test
    func test_init_setsModelOptionAndSetsInstructions() {
        let config = QuickAnswersConfig(model: .exa, instructions: "Some instructions")

        #expect(config.options["model"] as? String == "exa")
        #expect(config.instructions == "Some instructions")
    }

    @Test
    func test_init_defaultModelIsExa() {
        let config = QuickAnswersConfig()

        #expect(config.options["model"] as? String == "exa")
    }

    @Test
    func test_init_overridesModelOptionFromModelParameter() {
        let config = QuickAnswersConfig(model: .liner, options: ["model": "exa", "stream": false])

        #expect(config.options["model"] as? String == "liner")
        #expect(config.options["stream"] as? Bool == false)
    }

    @Test
    func test_model_displayName() {
        #expect(QuickAnswersModel.exa.displayName == "Exa")
        #expect(QuickAnswersModel.liner.displayName == "Liner")
    }
}
