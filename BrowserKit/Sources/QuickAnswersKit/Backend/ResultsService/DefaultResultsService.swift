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
    private let client: LiteLLMClientProtocol
    private let config: LLMConfig

    init(client: LiteLLMClientProtocol, config: LLMConfig) {
        self.client = client
        self.config = config
    }

    func fetchResults(for transcription: String) async throws -> SearchResult {
        // TODO: FXIOS-15198 - Handle mapping errors from request
        let fullResponse = try await request(for: transcription)
        return try formatResult(from: fullResponse.results)
    }

    private func request(for transcription: String) async throws -> SearchResponse {
        // TODO: FXIOS-15198 Handle errors appropriately
        // and may need to change type and not use String,
        // but waiting for what we get on server side
        let messages: [LiteLLMMes]
        return try await client.requestChatCompletion(messages: , config: <#T##any LLMConfig#>)(
            transcription: transcription,
            config: config,
        )
    }

    private func formatResult(from results: [SearchSource]) throws -> SearchResult {
        // TODO: FXIOS-15197 - Implement parsing logic based on response format and update Search Result
        var sources: [SearchResult.Source] = []
        let snippet = results.first?.snippet ?? ""
        for result in results {
            sources.append(SearchResult.Source(
                title: result.title ?? "",
                thumbnailURL: URL(string: result.url ?? ""),
                faviconURL: nil
            ))
        }
        return SearchResult(
            resultText: "Result shown here: \(snippet)",
            sources: sources
        )
    }
}
