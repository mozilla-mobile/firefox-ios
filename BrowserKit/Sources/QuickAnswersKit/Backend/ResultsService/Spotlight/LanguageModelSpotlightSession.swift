// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import CoreSpotlight
import Foundation
import FoundationModels

/// A `SpotlightAnswerSession` backed by `LanguageModelSession` and by the system `SpotlightSearchTool`, which is what
/// gives the on-device model access to the Spotlight index, and with it to the open tabs and the bookmarks the app
/// indexes as browser entities.
@available(iOS 27.0, *)
final class LanguageModelSpotlightSession: SpotlightAnswerSession {
    /// The attributes the tool reads back for every match. `keywords` carries the entity type, which is what lets the
    /// model tell an open tab from a bookmark, and `contentURL` is what makes a match usable as an answer source.
    private static let fetchAttributes: [SearchableItemAttribute] = [
        .title,
        .displayName,
        .contentURL,
        .contentDescription,
        .keywords,
        .lastUsedDate
    ]

    private static let classificationInstructions = """
    You decide whether a question is asking about the pages the user has in their browser, meaning their own open tabs,
    their bookmarks, their reading history or the sites they visited. Answer true only for those questions. Answer
    false for questions about the world, about facts, definitions, news, calculations or anything that could be
    answered without looking at what the user has open or saved.
    """.replacingOccurrences(of: "\n", with: " ")

    private let model: SystemLanguageModel

    init(model: SystemLanguageModel = .default) {
        self.model = model
    }

    func answer(question: String, instructions: String) async throws -> SpotlightAnswer {
        guard model.isAvailable else { throw ResultsServiceError.modelUnavailable }

        let tool = SpotlightSearchTool(configuration: Self.makeConfiguration())
        let collector = SourceCollector()
        let collecting = Task {
            for await reply in tool.searchResults {
                await collector.add(Self.sources(from: reply.content))
            }
        }
        defer { collecting.cancel() }
        // Gives the collecting task a chance to subscribe before the model starts calling the tool.
        await Task.yield()

        do {
            let session = LanguageModelSession(
                model: model,
                tools: [tool],
                instructions: instructions.isEmpty ? nil : instructions
            )
            let response = try await session.respond(to: Prompt(question))
            return SpotlightAnswer(text: response.content, sources: await collector.sources)
        } catch {
            throw Self.mapError(error)
        }
    }

    /// Runs a short, tool-less generation so that the classification costs a single on-device turn and never touches
    /// the Spotlight index.
    func isAboutBrowserItems(question: String) async -> Bool {
        guard model.isAvailable else { return true }

        do {
            let session = LanguageModelSession(model: model, instructions: Self.classificationInstructions)
            let response = try await session.respond(
                to: Prompt(question),
                generating: BrowserItemsClassification.self,
                options: GenerationOptions(temperature: 0)
            )
            return response.content.isAboutBrowserItems
        } catch {
            return true
        }
    }

    private static func makeConfiguration() -> SpotlightSearchTool.Configuration {
        let source = CoreSpotlightSource(fetchAttributes: fetchAttributes)
        let guide = SpotlightSearchTool.Guide(
            level: .focused(.items(.init(
                title: [.title, .displayName],
                text: [.contentDescription, .keywords],
                modified: [.lastUsedDate]
            ))),
            format: .structured
        )

        return SpotlightSearchTool.Configuration(sources: [.coreSpotlight(source)], guide: guide)
    }

    private static func sources(from content: SpotlightSearchTool.SearchReply.Content) -> [SpotlightAnswerSource] {
        switch content {
        case .items(let items):
            return items.compactMap(source(from:))
        case .scoredItems(let scoredItems):
            return scoredItems.compactMap { source(from: $0.item) }
        case .groupedItems(let groupedItems):
            return groupedItems.values.flatMap { $0 }.compactMap(source(from:))
        case .count, .table, .statistic, .text:
            return []
        @unknown default:
            return []
        }
    }

    private static func source(from item: SearchableItem) -> SpotlightAnswerSource? {
        let attributes = item.item.attributeSet
        guard let url = attributes.contentURL else { return nil }

        let title = attributes.title ?? attributes.displayName ?? url.absoluteString
        return SpotlightAnswerSource(title: title, url: url)
    }

    private static func mapError(_ error: any Error) -> ResultsServiceError {
        if let error = error as? ResultsServiceError { return error }
        if let toolCallError = error as? LanguageModelSession.ToolCallError {
            return mapError(toolCallError.underlyingError)
        }
        guard let generationError = error as? LanguageModelSession.GenerationError else {
            return .unknown(error.localizedDescription)
        }

        switch generationError {
        case .exceededContextWindowSize:
            return .payloadTooLarge
        case .rateLimited, .concurrentRequests:
            return .rateLimited
        case .assetsUnavailable:
            return .modelUnavailable
        default:
            return .noMessage
        }
    }
}

/// The structured yes/no the model returns when asked to classify a question.
@available(iOS 26.0, *)
@Generable
private struct BrowserItemsClassification {
    @Guide(description: "True when the question is about the user's own open tabs, bookmarks or visited pages.")
    let isAboutBrowserItems: Bool
}

/// Accumulates the pages the tool matched while the model is answering, keeping the first match per page.
private actor SourceCollector {
    private(set) var sources: [SpotlightAnswerSource] = []
    private var seenURLs: Set<URL> = []

    func add(_ newSources: [SpotlightAnswerSource]) {
        for source in newSources where seenURLs.insert(source.url).inserted {
            sources.append(source)
        }
    }
}
