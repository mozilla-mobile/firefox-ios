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
    func test_fetchResults_returnsResult() async throws {
        let client = MockLiteLLMClient()
        client.respondWith = ["This is a quick answer"]
        client.respondWithCitations = [
            Citation(
                id: "1",
                title: "Weather Source",
                url: "https://example.com"
            )
        ]
        let subject = createSubject(client: client)

        let result = try await subject.fetchResults(for: "What is the weather?")

        // Verify the request message
        let firstMessage = client.lastMessages.first as? QuickAnswersMessage
        #expect(client.lastMessages.count == 1)
        #expect(firstMessage?.content == "What is the weather?")
        #expect(firstMessage?.role == .user)

        // Verify the search result
        #expect(result.resultText == "This is a quick answer")
        #expect(result.sources.count == 1)
        let source = result.sources.first
        #expect(source?.title == "Weather Source")
        #expect(client.requestChatCompletionCallCount == 1)
    }

    @Test
    func test_fetchResults_handlesNoCitations() async throws {
        let client = MockLiteLLMClient()
        client.respondWith = ["Answer without citations"]
        client.respondWithCitations = nil
        let subject = createSubject(client: client)

        let result = try await subject.fetchResults(for: "Query")

        #expect(result.resultText == "Answer without citations")
        #expect(result.sources.isEmpty)
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
