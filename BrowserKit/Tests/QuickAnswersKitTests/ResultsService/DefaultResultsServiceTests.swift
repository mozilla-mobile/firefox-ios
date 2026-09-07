// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit
import Testing
import TestKit

@testable import QuickAnswersKit

struct DefaultResultsServiceTests {
    let testHelper = SwiftTestingHelper()
    let client = MockLiteLLMClient()
    let configFetcher = MockQuickAnswersConfigFetcher()

    @Test
    func test_fetchResults_returnsResult() async throws {
        client.respondWith = ["This is a quick answer"]
        client.respondWithCitations = [
            Citation(
                id: "1",
                title: "Weather Source",
                url: "https://example.com"
            )
        ]
        let subject = createSubject()

        let results = try await collectResults(from: subject, for: "What is the weather?")

        // Verify the last emitted search result holds the complete answer and its sources
        let result = try #require(results.last)
        #expect(result.resultText == "This is a quick answer")
        #expect(result.sources.count == 1)
        #expect(result.sources.first?.title == "Weather Source")
        #expect(client.requestChatCompletionStreamedCallCount == 1)
    }

    @Test
    func test_fetchResults_emitsAccumulatedAnswerPerChunk() async throws {
        client.respondWith = ["This ", "is ", "streamed"]
        let subject = createSubject()

        let results = try await collectResults(from: subject, for: "Query")

        #expect(results.map(\.resultText) == ["This ", "This is ", "This is streamed"])
    }

    @Test
    func test_fetchResults_whenCitationsArriveLast_emitsSourcesWithFinalResult() async throws {
        client.respondWith = ["Answer"]
        client.respondWithCitations = [Citation(id: "1", title: "Source", url: "https://example.com")]
        let subject = createSubject()

        let results = try await collectResults(from: subject, for: "Query")

        #expect(results.count == 2)
        #expect(results.first?.sources.isEmpty == true)
        #expect(results.last?.resultText == "Answer")
        #expect(results.last?.sources.count == 1)
    }

    @Test
    func test_fetchResults_limitsSourcesToMaxCitationsCount() async throws {
        client.respondWith = ["Answer"]
        client.respondWithCitations = (1...5).map { Citation(id: "\($0)", title: "Source \($0)") }
        let subject = createSubject()

        let results = try await collectResults(from: subject, for: "Query")

        #expect(results.last?.sources.count == 2)
    }

    @Test
    func test_fetchResults_withInstructions_sendsSystemAndUserMessages() async throws {
        client.respondWith = ["Answer"]
        let instructions = "You are a helpful assistant."
        let config = QuickAnswersConfig(model: .exa, instructions: instructions)
        let subject = createSubject(config: config)

        _ = try await collectResults(from: subject, for: "What is the weather?")

        let systemMessage = client.lastMessages.first as? QuickAnswersMessage
        let userMessage = client.lastMessages.last as? QuickAnswersMessage

        #expect(client.lastMessages.count == 2)
        #expect(systemMessage?.role == .system)
        #expect(systemMessage?.content == instructions)
        #expect(userMessage?.role == .user)
        #expect(userMessage?.content == "What is the weather?")
    }

    @Test
    func test_fetchResults_withoutInstructions_sendsUserMessageOnly() async throws {
        client.respondWith = ["Answer"]
        let config = QuickAnswersConfig(model: .liner)
        let subject = createSubject(config: config)

        _ = try await collectResults(from: subject, for: "What is the weather?")

        let userMessage = client.lastMessages.first as? QuickAnswersMessage
        #expect(client.lastMessages.count == 1)
        #expect(userMessage?.role == .user)
        #expect(userMessage?.content == "What is the weather?")
    }

    @Test
    func test_fetchResults_handlesNoCitations() async throws {
        client.respondWith = ["Answer without citations"]
        client.respondWithCitations = nil
        let subject = createSubject()

        let results = try await collectResults(from: subject, for: "Query")

        #expect(results.last?.resultText == "Answer without citations")
        #expect(results.last?.sources.isEmpty == true)
    }

    @Test
    func test_fetchResults_whenStreamIsEmpty_throwsNoMessage() async throws {
        client.respondWith = []
        let subject = createSubject()

        await #expect(throws: ResultsServiceError.noMessage) {
            try await collectResults(from: subject, for: "Query")
        }
    }

    @Test
    func test_fetchResults_whenConfigFetchFails_mapsError() async throws {
        configFetcher.errorToThrow = LiteLLMClientError.invalidResponse(statusCode: 429)
        let subject = createSubject()

        await #expect(throws: ResultsServiceError.rateLimited) {
            try await collectResults(from: subject, for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsRequestCreationFailedError() async throws {
        client.respondWithError = LiteLLMClientError.requestCreationFailed
        let subject = createSubject()

        await #expect(throws: ResultsServiceError.requestCreationFailed) {
            try await collectResults(from: subject, for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsRateLimitedError() async throws {
        client.respondWithError = LiteLLMClientError.invalidResponse(statusCode: 429)
        let subject = createSubject()

        await #expect(throws: ResultsServiceError.rateLimited) {
            try await collectResults(from: subject, for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsMaxUsersError() async throws {
        client.respondWithError = LiteLLMClientError.invalidResponse(statusCode: 403)
        let subject = createSubject()

        await #expect(throws: ResultsServiceError.maxUsers) {
            try await collectResults(from: subject, for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsPayloadTooLargeError() async throws {
        client.respondWithError = LiteLLMClientError.invalidResponse(statusCode: 413)
        let subject = createSubject()

        await #expect(throws: ResultsServiceError.payloadTooLarge) {
            try await collectResults(from: subject, for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsInvalidResponseError() async throws {
        client.respondWithError = LiteLLMClientError.invalidResponse(statusCode: 500)
        let subject = createSubject()

        await #expect(throws: ResultsServiceError.invalidResponse(statusCode: 500)) {
            try await collectResults(from: subject, for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsNoContentError() async throws {
        client.respondWithError = LiteLLMClientError.noContent
        let subject = createSubject()

        await #expect(throws: ResultsServiceError.noMessage) {
            try await collectResults(from: subject, for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsOtherLiteLLMClientError() async throws {
        client.respondWithError = LiteLLMClientError.decodingFailed
        let subject = createSubject()

        await #expect(throws: ResultsServiceError.self) {
            try await collectResults(from: subject, for: "Query")
        }
    }

    @Test
    func test_fetchResults_mapsGenericError() async throws {
        struct TestError: Error {}
        client.respondWithError = TestError()
        let subject = createSubject()

        await #expect(throws: ResultsServiceError.self) {
            try await collectResults(from: subject, for: "Query")
        }
    }

    // MARK: - Helper
    @discardableResult
    private func collectResults(
        from subject: DefaultResultsService,
        for transcription: String
    ) async throws -> [SearchResult] {
        var results: [SearchResult] = []
        for try await result in subject.fetchResults(for: transcription) {
            results.append(result)
        }
        return results
    }

    private func createSubject(config: QuickAnswersConfig = QuickAnswersConfig()) -> DefaultResultsService {
        configFetcher.configToReturn = config
        let subject = DefaultResultsService(client: client, configFetcher: configFetcher)
        testHelper.trackForMemoryLeaks(subject)
        return subject
    }
}
