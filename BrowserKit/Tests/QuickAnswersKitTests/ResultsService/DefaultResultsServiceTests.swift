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

    @Test
    func test_fetchResults_mapsRequestCreationFailedError() async throws {
        let client = MockLiteLLMClient()
        client.respondWithError = LiteLLMClientError.requestCreationFailed
        let subject = createSubject(client: client)

        await #expect(throws: ResultsServiceError.requestCreationFailed) {
            try await subject.fetchResults(for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsRateLimitedError() async throws {
        let client = MockLiteLLMClient()
        client.respondWithError = LiteLLMClientError.invalidResponse(statusCode: 429)
        let subject = createSubject(client: client)

        await #expect(throws: ResultsServiceError.rateLimited) {
            try await subject.fetchResults(for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsMaxUsersError() async throws {
        let client = MockLiteLLMClient()
        client.respondWithError = LiteLLMClientError.invalidResponse(statusCode: 403)
        let subject = createSubject(client: client)

        await #expect(throws: ResultsServiceError.maxUsers) {
            try await subject.fetchResults(for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsPayloadTooLargeError() async throws {
        let client = MockLiteLLMClient()
        client.respondWithError = LiteLLMClientError.invalidResponse(statusCode: 413)
        let subject = createSubject(client: client)

        await #expect(throws: ResultsServiceError.payloadTooLarge) {
            try await subject.fetchResults(for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsInvalidResponseError() async throws {
        let client = MockLiteLLMClient()
        client.respondWithError = LiteLLMClientError.invalidResponse(statusCode: 500)
        let subject = createSubject(client: client)

        await #expect(throws: ResultsServiceError.invalidResponse(statusCode: 500)) {
            try await subject.fetchResults(for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsNoContentError() async throws {
        let client = MockLiteLLMClient()
        client.respondWithError = LiteLLMClientError.noContent
        let subject = createSubject(client: client)

        await #expect(throws: ResultsServiceError.noMessage) {
            try await subject.fetchResults(for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsOtherLiteLLMClientError() async throws {
        let client = MockLiteLLMClient()
        client.respondWithError = LiteLLMClientError.decodingFailed
        let subject = createSubject(client: client)

        await #expect(throws: ResultsServiceError.self) {
            try await subject.fetchResults(for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsGenericError() async throws {
        let client = MockLiteLLMClient()
        struct TestError: Error {}
        client.respondWithError = TestError()
        let subject = createSubject(client: client)

        await #expect(throws: ResultsServiceError.self) {
            try await subject.fetchResults(for: "Query")
        }
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
