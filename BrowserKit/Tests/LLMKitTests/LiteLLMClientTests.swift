// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import TestKit
import MLPAKit

@testable import LLMKit

@MainActor
final class LiteLLMClientTests: XCTestCase {
    private static let mockAPIEndpoint = "https://test-api-url.com"
    private static let mockAPIKey =  "test-api-key"
    private static let mockMessages: [StandardMessage] = [
        StandardMessage(role: .system, content: "Init chat"),
        StandardMessage(role: .user, content: "Hello")
    ]

    private static let liteLLMMessagePayload = """
    {
      "role": "user",
      "content": "Hello !"
    }
    """.data(using: .utf8)!

    private static let liteLLMResponsePayload = """
    {
      "id": "resp-1",
      "choices": [
        {
          "index": 0,
          "message": {
            "role": "assistant",
            "content": "Hi there!"
          },
          "delta": null,
          "finishReason": "stop"
        }
      ]
    }
    """.data(using: .utf8)!

    private static let streamResponsePayload = """
    {
      "id": "stream-123",
      "created": 1690000000,
      "model": "stream-model",
      "object": "chat.completion.chunk",
      "choices": [
        {
          "index": 100,
          "delta": {
            "role": "assistant",
            "content": "Chunked text."
          }
        }
      ]
    }
    """.data(using: .utf8)!

    func testLiteLLMMessageCodable() throws {
        let msg = try JSONDecoder().decode(StandardMessage.self, from: Self.liteLLMMessagePayload)
        XCTAssertEqual(msg.role, .user)
        XCTAssertEqual(msg.content, "Hello !")
    }

    func testLiteLLMResponseCodable() throws {
        let response = try JSONDecoder().decode(LiteLLMResponse<EmptyProviderFields>.self, from: Self.liteLLMResponsePayload)
        XCTAssertEqual(response.id, "resp-1")
        let firstChoice = response.choices.first
        XCTAssertEqual(firstChoice?.message?.role, .assistant)
        XCTAssertEqual(firstChoice?.message?.content, "Hi there!")
        XCTAssertNil(response.choices.first?.delta)
    }

    func testStreamResponseCodable() throws {
        let stream = try JSONDecoder().decode(LiteLLMStreamResponse.self, from: Self.streamResponsePayload)
        XCTAssertEqual(stream.id, "stream-123")
        XCTAssertEqual(stream.created, 1690000000)
        XCTAssertEqual(stream.model, "stream-model")
        XCTAssertEqual(stream.object, "chat.completion.chunk")

        let choice = stream.choices.first!
        XCTAssertEqual(choice.index, 100)
        XCTAssertEqual(choice.delta.role, "assistant")
        XCTAssertEqual(choice.delta.content, "Chunked text.")
    }

    func testMakeRequestBuildsURLRequestNonStreaming() async throws {
        let subject = createSubject()
        let config = MockConfig(
            instructions: "instructions",
            options: [
                "model": "fake-model",
                "max_tokens": 50,
                "stream": false
            ]
        )
        let urlRequest = try await subject.makeRequest(messages: Self.mockMessages, config: config)

        XCTAssertEqual(urlRequest.httpMethod, LiteLLMClient.postMethod)
        XCTAssertEqual(urlRequest.url?.absoluteString, "\(Self.mockAPIEndpoint)/chat/completions")

        let headers = try XCTUnwrap(urlRequest.allHTTPHeaderFields, "Expected headers to be non‑nil")
        XCTAssertEqual(headers["Content-Type"], "application/json")
        XCTAssertEqual(headers["Authorization"], "Bearer \(Self.mockAPIKey)")
        XCTAssertNil(headers["Accept"])
        XCTAssertNil(headers["Connection"])

        let rawBody = try XCTUnwrap(urlRequest.httpBody, "Expected httpBody to be non‑nil")
        let json = try JSONSerialization.jsonObject(with: rawBody, options: [])
        let body = try XCTUnwrap(json as? [String: Any], "Expected JSON dictionary")

        XCTAssertEqual(body["model"] as? String, "fake-model")
        XCTAssertEqual(body["max_tokens"] as? Int, 50)
        XCTAssertEqual(body["stream"] as? Bool, false)

        let messages = try XCTUnwrap(body["messages"] as? [[String: Any]], "Expected messages array")
        XCTAssertEqual(messages.count, 2)

        let first = try XCTUnwrap(messages.first, "Expected at least one message")
        XCTAssertEqual(first["role"] as? String, "system")
    }

    func testMakeRequestBuildsURLRequestStreaming() async throws {
        let subject = createSubject()
        let config = MockConfig(
            instructions: "instructions",
            options: [
                "model": "fake-model",
                "max_tokens": 50,
                "stream": true
            ]
        )
        let urlRequest = try await subject.makeRequest(messages: Self.mockMessages, config: config)

        // Verify headers for streaming mode
        let headers = try XCTUnwrap(urlRequest.allHTTPHeaderFields, "Expected headers to be non‑nil")
        XCTAssertEqual(headers["Accept"], "text/event-stream")
        XCTAssertEqual(headers["Connection"], "keep-alive")

        let bodyData = try XCTUnwrap(urlRequest.httpBody, "Expected httpBody to be non‑nil")
        let json = try JSONSerialization.jsonObject(with: bodyData, options: [])
                    as? [String: Any]
        XCTAssertEqual(json?["stream"] as? Bool, true)
    }

    func testQuickAnswersMessageCodableWithCitations() throws {
        let payload = """
        {
          "role": "assistant",
          "content": "Quick answer here",
          "provider_specific_fields": {
            "citations": [
              {
                "id": "cite-1",
                "title": "Source Title",
                "url": "https://source.com",
                "image": "https://source.com/image.png",
                "favicon": "https://source.com/favicon.ico"
              }
            ]
          }
        }
        """.data(using: .utf8)!

        let message = try JSONDecoder().decode(QuickAnswersMessage.self, from: payload)
        XCTAssertEqual(message.role, .assistant)
        XCTAssertEqual(message.content, "Quick answer here")
        XCTAssertEqual(message.providerSpecificFields?.citations?.count, 1)

        let citation = try XCTUnwrap(message.providerSpecificFields?.citations?.first)
        XCTAssertEqual(citation.id, "cite-1")
        XCTAssertEqual(citation.title, "Source Title")
        XCTAssertEqual(citation.url, "https://source.com")
        XCTAssertEqual(citation.image, "https://source.com/image.png")
        XCTAssertEqual(citation.favicon, "https://source.com/favicon.ico")
    }

    func testMakeRequestWithQuickAnswersMessages() async throws {
        let subject = createSubject()
        let messages: [QuickAnswersMessage] = [
            QuickAnswersMessage(role: .user, content: "What is the weather?")
        ]
        let config = MockConfig(instructions: "", options: ["model": "exa"])

        let urlRequest = try await subject.makeRequest(messages: messages, config: config)

        let bodyData = try XCTUnwrap(urlRequest.httpBody)
        let json = try JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        let messagesArray = try XCTUnwrap(json?["messages"] as? [[String: Any]])

        XCTAssertEqual(messagesArray.count, 1)
        XCTAssertEqual(messagesArray[0]["role"] as? String, "user")
        XCTAssertEqual(messagesArray[0]["content"] as? String, "What is the weather?")
    }

    private func createSubject() -> LiteLLMClient {
        let subject = LiteLLMClient(
            authenticator: BearerRequestAuth(apiKey: Self.mockAPIKey),
            baseURL: URL(string: Self.mockAPIEndpoint)!
        )
        trackForMemoryLeaks(subject)
        return subject
    }
}
