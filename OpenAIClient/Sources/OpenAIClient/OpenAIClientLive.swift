//
//  OpenAIClientLive.swift
//

import Foundation
import Dependencies
import OpenAIStreamingCompletions

fileprivate var apiKey: String {
    // You can use raw string for testing purposes, but it's better to provide API_KEY from env vars.
    ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""
}
fileprivate let openAI = OpenAIAPI(apiKey: apiKey)

extension OpenAIClient: DependencyKey {
    public static let liveValue = OpenAIClient(
        summaryForUrl: { url in
            let prompt = "tldr \(url.absoluteString)"
            return try? openAI.completeStreaming(.init(prompt: prompt, max_tokens: 512))
        }
    )
}
