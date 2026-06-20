// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Testing

@testable import QuickAnswersKit

struct QuickAnswersConfigTests {
    @Test
    func test_init_withExaModel_syncsModelOptionAndInjectsInstructions() {
        let config = QuickAnswersConfig(model: .exa)

        #expect(config.options["model"] as? String == "exa")
        #expect(config.instructions == QuickAnswersInstructions.exaInstructions)
        #expect(config.instructions.isEmpty == false)
    }

    @Test
    func test_init_withLinerModel_syncsModelOptionAndOmitsInstructions() {
        let config = QuickAnswersConfig(model: .liner)

        #expect(config.options["model"] as? String == "liner")
        #expect(config.instructions.isEmpty)
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

    @Test
    func test_model_injectsSystemPrompt() {
        #expect(QuickAnswersModel.exa.injectsSystemPrompt == true)
        #expect(QuickAnswersModel.liner.injectsSystemPrompt == false)
    }
}
