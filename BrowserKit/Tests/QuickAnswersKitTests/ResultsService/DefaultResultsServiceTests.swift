// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit
import Testing
import TestKit

@testable import QuickAnswersKit

struct DefaultResultsServiceTests {
    let testHelper = SwiftTestingHelper()

    @Test
    func test_fetchResults_returnsResultFromSingleChunk() async throws {
        let client = MockLiteLLMClient()
        client.respondWith = ["This is a quick answer"]
        let subject = createSubject(client: client)

        let result = try await subject.fetchResults(for: "What is the weather?")

        #expect(result.body == "This is a quick answer")
        #expect(result.title == "Quick Answer")
        #expect(client.requestChatCompletionStreamedCallCount == 1)
        #expect(client.lastMessages?.count == 1)
        #expect(client.lastMessages?.first?.content == "What is the weather?")
        #expect(client.lastMessages?.first?.role == .user)
    }

    @Test
    func test_fetchResults_accumulatesMultipleChunks() async throws {
        let client = MockLiteLLMClient()
        client.respondWith = ["The ", "weather ", "is ", "sunny"]
        let subject = createSubject(client: client)

        let result = try await subject.fetchResults(for: "weather today")

        #expect(result.body == "The weather is sunny")
        #expect(client.requestChatCompletionStreamedCallCount == 1)
        #expect(client.lastMessages?.count == 1)
        #expect(client.lastMessages?.first?.content == "weather today")
        #expect(client.lastMessages?.first?.role == .user)
    }

    // MARK: - Helper
    private func createSubject(
        client: LiteLLMClientProtocol,
        config: QuickAnswersConfig = QuickAnswersConfig()
    ) -> DefaultResultsService {
        let subject = DefaultResultsService(client: client, config: config)
        testHelper.trackForMemoryLeaks(subject)
        return subject
    }
}
