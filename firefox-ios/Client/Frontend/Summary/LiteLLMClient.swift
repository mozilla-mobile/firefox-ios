// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Common
import Shared

/// A lightweight client for interacting with a chat completions endpoint.
public class LiteLLMClient: NSObject, URLSessionDataDelegate {
    /// NOTE: OpenAI like APIs including LiteLLM don't use websockets for streaming mode
    /// but instead use Server Sent Events (SSE) to send chunked responses.
    private static let sseEventDelimiter = "\n\n"
    private static let sseDataPrefix = "data: "
    private static let sseDoneSignal = "[DONE]"

    private let apiKey: String
    private let baseURL: URL
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    /// Delegate to receive streaming updates.
    public weak var streamDelegate: LiteLLMStreamDelegate?

    /// Initializes the client.
    /// - Parameters:
    ///   - apiKey: Your API key for authentication.
    ///   - baseURL: Base URL of the server.
    public init(apiKey: String, baseURL: URL) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    /// Sends a chat completion request.
    /// - Parameters:
    ///   - messages: Array of `LiteLLMMessage`.
    ///   - model: Model identifier.
    ///   - maxTokens: Maximum tokens to generate.
    ///   - stream: Whether to stream the response (`true`) or not (`false`).
    ///   - completion: Completion handler for non-streaming requests. Ignored if `stream` is `true`.
    public func requestChatCompletion(
        messages: [LiteLLMMessage],
        model: String = "fake-openai-endpoint-5",
        maxTokens: Int = 1000,
        stream: Bool = false,
        completion: ((Result<String, Error>) -> Void)? = nil
    ) {
        do {
            let request = try makeRequest(messages: messages, model: model, maxTokens: maxTokens, stream: stream)
            if stream {
                session.dataTask(with: request).resume()
            } else {
                URLSession.shared.dataTask(with: request) { data, _, error in
                    self.handleResponse(data: data, error: error, completion: completion)
                }.resume()
            }
        } catch {
            if stream {
                streamDelegate?.liteLLMClient(self, didFinishWith: LLMClientError.requestCreationFailed)
            } else {
                completion?(.failure(LLMClientError.requestCreationFailed))
            }
        }
    }

    func makeRequest(
        messages: [LiteLLMMessage],
        model: String,
        maxTokens: Int,
        stream: Bool
    ) throws -> URLRequest {
        let endpoint = baseURL.appendingPathComponent("chat/completions")
        var request = URLRequest(url: endpoint)
        request.httpMethod = HTTPMethod.post.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        var payload: [String: Any] = [
            "model": model,
            "messages": messages.map { ["role": $0.role.rawValue, "content": $0.content] },
            "max_tokens": maxTokens
        ]

        if stream {
            request.addValue("text/event-stream", forHTTPHeaderField: "Accept")
            request.addValue("keep-alive", forHTTPHeaderField: "Connection")
            payload["stream"] = true
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        return request
    }

    private func handleResponse(
        data: Data?,
        error: Error?,
        completion: ((Result<String, Error>) -> Void)?
    ) {
        // Network-level errors
        if let err = error {
            completion?(.failure(LLMClientError.networkError(underlying: err)))
            return
        }
        // Missing or invalid data
        guard let data = data else {
            completion?(.failure(LLMClientError.invalidResponse))
            return
        }
        // Parse JSON and extract content
        do {
            let response = try JSONDecoder().decode(LiteLLMResponse.self, from: data)
            guard let content = response.choices.first?.message?.content else {
                completion?(.failure(LLMClientError.noContent))
                return
            }
            completion?(.success(content))
        } catch {
            completion?(.failure(LLMClientError.decodingFailed))
        }
    }

    // MARK: - URLSessionDataDelegate

    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }

        for raw in text.components(separatedBy: Self.sseEventDelimiter) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmed.hasPrefix(Self.sseDataPrefix) else { continue }
            let payload = String(trimmed.dropFirst(Self.sseDataPrefix.count))

            if payload == Self.sseDoneSignal {
                streamDelegate?.liteLLMClient(self, didFinishWith: nil)
                return
            }

            decodeAndForward(payload)
        }
    }

    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        streamDelegate?.liteLLMClient(self, didFinishWith: error)
    }

    private func decodeAndForward(_ jsonString: String) {
        guard
            let data = jsonString.data(using: .utf8),
            let chunk = try? JSONDecoder().decode(LiteLLMStreamResponse.self, from: data)
        else { return }

        if let content = chunk.choices.first?.delta.content {
            streamDelegate?.liteLLMClient(self, didReceive: content)
        }
    }
}
