// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import LLMKit
import Foundation
import MLPAKit

// MARK: - Protocol
protocol ResultsService: Sendable {
    func fetchResults(for transcription: String) async throws -> SearchResult
}

final class DefaultResultsService: ResultsService {
    // TODO: FXIOS-15196 - Remove optional when creating the appropriate client
    private let client: LiteLLMClientProtocol?
    private let config: QuickAnswersConfig

    init(client: LiteLLMClientProtocol?, config: QuickAnswersConfig) {
        self.client = client
        self.config = config
    }

    func fetchResults(for transcription: String) async throws -> SearchResult {
        let message = LiteLLMMessage(role: .user, content: transcription)

        guard let completionResult = try await client?.requestChatCompletionStreamed(
            messages: [message],
            config: config
        ) else {
            throw SpeechError.unknown
        }

        var response = LiteLLMStreamResponse(choices: [], references: [])
        do {
            for try await partialResponse in completionResult {
                response = response.accumulate(partialResponse)
            }
        } catch {
            print(error)
        }

        print("FF: \(response)")

        // Build the content by concatenating all content deltas
        let content: String = response.choices?.reduce("") { acc, choice in
            var next = acc
            if let c = choice.delta.content {
                next += c
            }
            return next
        } ?? ""

        // Map references to SearchResultSource if available; otherwise empty array
        let sources: [SearchResultSource] = response.references?.map { ref in
            SearchResultSource(title: ref.title, url: ref.url, faviconURL: ref.faviconUrl)
        } ?? []

        return SearchResult(
            content: content,
            sources: sources
        )
    }
}
