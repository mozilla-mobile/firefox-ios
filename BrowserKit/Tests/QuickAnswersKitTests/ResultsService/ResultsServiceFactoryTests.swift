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
    func test_make_withValidClient_returnsConfiguredService() throws {
        let mockLLMCreator = MockLLMClientCreator()
        mockLLMCreator.clientToReturn = MockLiteLLMClient()
        let prefs = MockProfilePrefs()
        let configFetcher = MockQuickAnswersConfigFetcher()
        let subject = createSubject(liteLLMCreator: mockLLMCreator)

        let result = try subject.make(prefs: prefs, configFetcher: configFetcher)

        #expect(result is DefaultResultsService, "Factory should return a service when the LLM client is available")
        #expect(mockLLMCreator.createAppAttestLiteLLMCallCount == 1, "Should call createAppAttestLiteLLM once")
    }

    @Test
    func test_make_withNilLLMClient_throwsError() {
        let mockLLMCreator = MockLLMClientCreator()
        mockLLMCreator.shouldReturnNil = true
        let prefs = MockProfilePrefs()
        let configFetcher = MockQuickAnswersConfigFetcher()
        let subject = createSubject(liteLLMCreator: mockLLMCreator)

        #expect(throws: ResultsServiceError.unableToCreateService) {
            try subject.make(prefs: prefs, configFetcher: configFetcher)
        }
        #expect(mockLLMCreator.createAppAttestLiteLLMCallCount == 1, "Should attempt to create LLM client")
    }

    @Test
    func test_make_withSpotlightModel_returnsOnDeviceServiceWithRemoteFallback() throws {
        let mockLLMCreator = MockLLMClientCreator()
        mockLLMCreator.clientToReturn = MockLiteLLMClient()
        let configFetcher = MockQuickAnswersConfigFetcher()
        configFetcher.model = .spotlight
        let subject = createSubject(liteLLMCreator: mockLLMCreator)

        let result = try subject.make(prefs: MockProfilePrefs(), configFetcher: configFetcher)

        #expect(result is SpotlightResultsService, "Spotlight model should be answered on device")
        #expect(
            mockLLMCreator.createAppAttestLiteLLMCallCount == 1,
            "Should build the fallback for unrelated questions"
        )
    }

    @Test
    func test_make_withSpotlightModel_withNilLLMClient_stillReturnsOnDeviceService() throws {
        let mockLLMCreator = MockLLMClientCreator()
        mockLLMCreator.shouldReturnNil = true
        let configFetcher = MockQuickAnswersConfigFetcher()
        configFetcher.model = .spotlight
        let subject = createSubject(liteLLMCreator: mockLLMCreator)

        let result = try subject.make(prefs: MockProfilePrefs(), configFetcher: configFetcher)

        #expect(result is SpotlightResultsService, "A missing fallback should not break the on-device answers")
    }

    @Test
    func test_make_withSpotlightModel_whenSessionIsUnavailable_throwsError() {
        let configFetcher = MockQuickAnswersConfigFetcher()
        configFetcher.model = .spotlight
        let subject = createSubject(makeSpotlightSession: { throw ResultsServiceError.modelUnavailable })

        #expect(throws: ResultsServiceError.modelUnavailable) {
            try subject.make(prefs: MockProfilePrefs(), configFetcher: configFetcher)
        }
    }

    // MARK: - Helper
    private func createSubject(
        liteLLMCreator: LiteLLMCreating = MockLLMClientCreator(),
        makeSpotlightSession: @escaping () throws -> SpotlightAnswerSession = { MockSpotlightAnswerSession() }
    ) -> DefaultResultsServiceFactory {
        return DefaultResultsServiceFactory(
            liteLLMCreator: liteLLMCreator,
            makeSpotlightSession: makeSpotlightSession
        )
    }
}
