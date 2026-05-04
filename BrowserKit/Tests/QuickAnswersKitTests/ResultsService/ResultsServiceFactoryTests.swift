// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit
import MLPAKit
import Shared
import Testing
import TestKit

@testable import QuickAnswersKit

struct ResultsServiceFactoryTests {
    @Test
    func test_make_withValidConfig_returnsConfiguredService() {
        let mockLLMCreator = MockLLMClientCreator()
        mockLLMCreator.clientToReturn = MockLiteLLMClient()
        let prefs = MockProfilePrefs()
        let config = QuickAnswersConfig(options: ["model": "test-model"])
        let subject = createSubject(liteLLMCreator: mockLLMCreator, config: config)

        let result = subject.make(prefs: prefs, config: config)

        #expect(result != nil, "Factory should return configured service when LLM client is available")
        #expect(mockLLMCreator.createAppAttestLiteLLMCallCount == 1, "Should call createAppAttestLiteLLM once")
    }

    @Test
    func test_make_withNoModelOption_returnsNil() {
        let mockLLMCreator = MockLLMClientCreator()
        mockLLMCreator.clientToReturn = MockLiteLLMClient()
        let prefs = MockProfilePrefs()
        let config = QuickAnswersConfig(options: [:])
        let subject = createSubject(liteLLMCreator: mockLLMCreator, config: config)

        let result = subject.make(prefs: prefs, config: config)

        #expect(result == nil, "Factory should return nil when config is missing model options")
        #expect(mockLLMCreator.createAppAttestLiteLLMCallCount == 0, "Should not call when model is missing")
    }

    @Test
    func test_make_withEmptyModel_returnsNil() {
        let mockLLMCreator = MockLLMClientCreator()
        mockLLMCreator.clientToReturn = MockLiteLLMClient()
        let prefs = MockProfilePrefs()
        let config = QuickAnswersConfig(options: ["model": ""])
        let subject = createSubject(liteLLMCreator: mockLLMCreator, config: config)

        let result = subject.make(prefs: prefs, config: config)

        #expect(result == nil, "Factory should return nil when model is empty")
        #expect(mockLLMCreator.createAppAttestLiteLLMCallCount == 0, "Should not call when model is empty")
    }

    @Test
    func test_make_withNilLLMClient_returnsNil() {
        let mockLLMCreator = MockLLMClientCreator()
        mockLLMCreator.shouldReturnNil = true
        let prefs = MockProfilePrefs()
        let config = QuickAnswersConfig(options: ["model": "test-model"])
        let subject = createSubject(liteLLMCreator: mockLLMCreator, config: config)

        let result = subject.make(prefs: prefs, config: config)

        #expect(result == nil, "Factory should return nil when LLM client creation fails")
        #expect(mockLLMCreator.createAppAttestLiteLLMCallCount == 1, "Should attempt to create LLM client")
    }

    // MARK: - Helper
    private func createSubject(
        liteLLMCreator: LiteLLMCreating = MockLLMClientCreator(),
        config: QuickAnswersConfig = QuickAnswersConfig()
    ) -> DefaultResultsServiceFactory {
        return DefaultResultsServiceFactory(config: config, liteLLMCreator: liteLLMCreator)
    }
}
