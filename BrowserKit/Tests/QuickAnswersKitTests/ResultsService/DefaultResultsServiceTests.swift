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

        // Verify the search result
        #expect(result.resultText == "This is a quick answer")
        #expect(result.sources.count == 1)
        let source = result.sources.first
        #expect(source?.title == "Weather Source")
        #expect(client.requestChatCompletionCallCount == 1)
    }

    @Test
    func test_fetchResults_withInstructions_sendsSystemAndUserMessages() async throws {
        let client = MockLiteLLMClient()
        client.respondWith = ["Answer"]
        let instructions = "You are a helpful assistant."
        let config = QuickAnswersConfig(model: .exa, instructions: instructions)
        let subject = createSubject(client: client, config: config)

        _ = try await subject.fetchResults(for: "What is the weather?")

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
        let client = MockLiteLLMClient()
        client.respondWith = ["Answer"]
        let config = QuickAnswersConfig(model: .liner)
        let subject = createSubject(client: client, config: config)

        _ = try await subject.fetchResults(for: "What is the weather?")

        let userMessage = client.lastMessages.first as? QuickAnswersMessage
        #expect(client.lastMessages.count == 1)
        #expect(userMessage?.role == .user)
        #expect(userMessage?.content == "What is the weather?")
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

    @Test
    func test_fetchResults_followUpEnabled_sendsMessagesFromConversation() async throws {
        let client = MockLiteLLMClient()
        let conversation = MockQuickAnswersConversation()
        let historyMessages = [
            QuickAnswersMessage(role: .user, content: "What is the weather?"),
            QuickAnswersMessage(role: .assistant, content: "Sunny"),
            QuickAnswersMessage(role: .user, content: "And tomorrow?")
        ]
        conversation.messagesToReturn = historyMessages
        let subject = createSubject(
            client: client,
            config: QuickAnswersConfig(model: .exa, instructions: "Be concise"),
            isFollowUpEnabled: true,
            conversation: conversation
        )

        _ = try await subject.fetchResults(for: "And tomorrow?")

        let sentMessages = client.lastMessages.compactMap { $0 as? QuickAnswersMessage }
        #expect(conversation.applyHistoryCallCount == 1)
        #expect(conversation.lastAppliedQuestion == "And tomorrow?")
        #expect(conversation.lastAppliedMessages?.map(\.role) == [.system])
        #expect(conversation.lastAppliedMessages?.map(\.content) == ["Be concise"])
        #expect(sentMessages.map(\.role) == historyMessages.map(\.role))
        #expect(sentMessages.map(\.content) == historyMessages.map(\.content))
    }

    @Test(arguments: [(QuickAnswersModel.liner, true), (QuickAnswersModel.exa, false)])
    func test_fetchResults_followUpEnabled_passesModelAssistantRoleSupport(
        model: QuickAnswersModel,
        supportsAssistantRole: Bool
    ) async throws {
        let conversation = MockQuickAnswersConversation()
        let subject = createSubject(
            client: MockLiteLLMClient(),
            model: model,
            isFollowUpEnabled: true,
            conversation: conversation
        )

        _ = try await subject.fetchResults(for: "Query")

        #expect(conversation.lastSupportsAssistantRole == supportsAssistantRole)
    }

    @Test
    func test_fetchResults_followUpEnabled_appendsTurnToConversation() async throws {
        let client = MockLiteLLMClient()
        client.respondWith = ["Sunny"]
        let conversation = MockQuickAnswersConversation()
        let subject = createSubject(client: client, isFollowUpEnabled: true, conversation: conversation)

        _ = try await subject.fetchResults(for: "What is the weather?")

        #expect(conversation.appendCallCount == 1)
        #expect(conversation.lastAppendedQuestion == "What is the weather?")
        #expect(conversation.lastAppendedAnswer == "Sunny")
    }

    @Test
    func test_fetchResults_followUpEnabledAndRequestFails_doesNotAppendTurn() async throws {
        let client = MockLiteLLMClient()
        client.respondWithError = LiteLLMClientError.noContent
        let conversation = MockQuickAnswersConversation()
        let subject = createSubject(client: client, isFollowUpEnabled: true, conversation: conversation)

        await #expect(throws: ResultsServiceError.noMessage) {
            try await subject.fetchResults(for: "Query")
        }
        #expect(conversation.appendCallCount == 0)
    }

    @Test
    func test_fetchResults_followUpDisabled_doesNotUseConversation() async throws {
        let client = MockLiteLLMClient()
        let conversation = MockQuickAnswersConversation()
        let subject = createSubject(client: client, isFollowUpEnabled: false, conversation: conversation)

        _ = try await subject.fetchResults(for: "Query")

        let sentMessages = client.lastMessages.compactMap { $0 as? QuickAnswersMessage }
        #expect(conversation.applyHistoryCallCount == 0)
        #expect(conversation.appendCallCount == 0)
        #expect(sentMessages.map(\.role) == [.user])
        #expect(sentMessages.map(\.content) == ["Query"])
    }

    // MARK: - Helper
    private func createSubject(
        client: LiteLLMClientProtocol,
        config: QuickAnswersConfig = QuickAnswersConfig(),
        model: QuickAnswersModel = .exa,
        isFollowUpEnabled: Bool = false,
        conversation: QuickAnswersConversation = MockQuickAnswersConversation()
    ) -> DefaultResultsService {
        let configFetcher = MockQuickAnswersConfigFetcher(configToReturn: config)
        configFetcher.model = model
        configFetcher.isFollowUpEnabled = isFollowUpEnabled
        let subject = DefaultResultsService(
            client: client,
            configFetcher: configFetcher,
            conversation: conversation
        )
        testHelper.trackForMemoryLeaks(subject)
        return subject
    }
}
